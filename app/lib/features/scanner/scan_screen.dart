import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/util/ids.dart';
import '../../data/repositories/scan_repository.dart';
import '../../domain/omr_reading.dart';
import '../../domain/sheet_layout.dart';
import 'capture_guide.dart';
import '../../domain/scan_problem.dart';
import 'review_screen.dart';
import 'scan_problem_panel.dart';

/// Settings key: auto-capture when the sheet is steady.
const String autoCaptureSetting = 'scanner.auto_capture';

/// Live camera scanner. Papers are scanned one after another (batch); each is
/// checked on the review screen before it is saved. Photos never leave the
/// phone; the original photo is deleted right after it is read.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  CameraController? _camera;
  ScanContext? _ctx;
  String? _sessionId;
  CaptureGuide? _guide;
  GuideState? _state;
  String? _fatal;
  String? _notice;

  /// Why the last photo was not read. Scanning stays paused (no auto-capture)
  /// until the instructor acknowledges it.
  ScanProblem? _problem;
  bool _processing = false;
  bool _detecting = false;
  bool _autoCapture = true;
  bool _torch = false;
  int _saved = 0;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    final session = _sessionId;
    if (session != null) ref.read(scanRepositoryProvider).endSession(session);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _camera = null;
      camera?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && camera == null && _ctx != null && !_processing) {
      _openCamera();
    }
  }

  Future<void> _start() async {
    try {
      final repo = ref.read(scanRepositoryProvider);
      final ctx = await repo.context(widget.examId);
      final auto = await ref.read(settingsRepositoryProvider).getBool(autoCaptureSetting, defaultValue: true);
      final session = await repo.startSession(widget.examId, 'batch');
      if (!mounted) return;
      setState(() {
        _ctx = ctx;
        _sessionId = session;
        _autoCapture = auto;
        _guide = CaptureGuide(itemCount: ctx.exam.itemCount);
      });
      await _openCamera();
    } catch (e) {
      if (mounted) setState(() => _fatal = 'The scanner could not start. Please try again.');
    }
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _fatal = 'No camera was found on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // 1080p: verified by the engine test suite (omr_engine, "1080p" scenario)
      // and light enough to stream preview frames for live guidance.
      final camera = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await camera.initialize();
      await camera.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
      try {
        await camera.setFocusMode(FocusMode.auto);
      } catch (_) {}
      if (!mounted) {
        await camera.dispose();
        return;
      }
      setState(() => _camera = camera);
      await _resumeStream();
    } on CameraException catch (e) {
      final denied = e.code.toLowerCase().contains('denied') || e.code.toLowerCase().contains('restricted');
      setState(() => _fatal = denied
          ? 'ACEkanner needs the camera to scan answer sheets. Allow it in Android Settings › Apps › ACEkanner › Permissions, then reopen the scanner.'
          : 'The camera could not be opened (${e.description ?? e.code}).');
    }
  }

  Future<void> _resumeStream() async {
    final camera = _camera;
    if (camera == null || camera.value.isStreamingImages) return;
    _guide?.rearm();
    await camera.startImageStream(_onFrame);
  }

  void _onFrame(CameraImage image) {
    if (_processing || _detecting || _problem != null) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame) < const Duration(milliseconds: 250)) return;
    _lastFrame = now;
    _detecting = true;
    final plane = image.planes.first;
    ref
        .read(omrEngineChannelProvider)
        .detectMarkers(bytes: plane.bytes, width: image.width, height: image.height, rowStride: plane.bytesPerRow)
        .then((feedback) {
      if (feedback == null || !mounted || _processing) return;
      final state = _guide!.update(feedback);
      setState(() {
        _state = state;
        if (state.status == GuideStatus.ready) _notice = null;
      });
      if (state.autoCapture && _autoCapture) _capture();
    }).catchError((_) {}).whenComplete(() => _detecting = false);
  }

  Future<void> _capture() async {
    final camera = _camera;
    final ctx = _ctx;
    if (camera == null || ctx == null || _processing || _problem != null || camera.value.isTakingPicture) return;
    setState(() {
      _processing = true;
      _notice = null;
    });
    final repo = ref.read(scanRepositoryProvider);
    File? photo;
    File? rectified;
    var keepRectified = false;
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
      photo = File((await camera.takePicture()).path);
      final tmp = await getTemporaryDirectory();
      rectified = File(p.join(tmp.path, 'scan-${newId()}.jpg'));
      final reading = await ref.read(omrEngineChannelProvider).analyzeSheet(
            imagePath: photo.path,
            layout: ctx.layout,
            rectifiedPath: rectified.path,
            preset: ctx.exam.omrPreset,
            customThresholds: ctx.exam.omrThresholds,
          );
      switch (reading) {
        case OmrFailure():
          await repo.recordCapture(_sessionId!, rejected: true);
          _report(ScanProblem.fromFailure(reading));
        case OmrSheetReading():
          final mismatch = repo.sheetMismatch(ctx, reading);
          if (mismatch != null) {
            await repo.recordCapture(_sessionId!, rejected: true);
            _report(ScanProblem.mismatch(mismatch));
            break;
          }
          await repo.recordCapture(_sessionId!, rejected: false);
          if (!mounted) return;
          keepRectified = true;
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => ScaffoldMessenger(
                child: ReviewScreen(
                  context: ctx,
                  reading: reading,
                  rectifiedImage: rectified!,
                  sessionId: _sessionId,
                ),
              ),
            ),
          );
          keepRectified = false;
          if (saved == true && mounted) {
            setState(() => _saved++);
            _show('Paper saved. Scan the next one.', good: true);
          }
      }
    } on CameraException catch (e) {
      _report(ScanProblem.camera(e.description ?? e.code));
    } catch (_) {
      _report(ScanProblem.unexpected);
    } finally {
      await _deleteQuietly(photo);
      if (!keepRectified) await _deleteQuietly(rectified);
      if (mounted) {
        setState(() => _processing = false);
        if (_problem == null) await _resumeStream();
      }
    }
  }

  void _report(ScanProblem problem) {
    if (mounted) {
      setState(() {
        _problem = problem;
        _notice = null;
      });
    }
  }

  /// The instructor read the problem: scanning continues.
  Future<void> _acknowledge() async {
    setState(() => _problem = null);
    await _resumeStream();
  }

  bool _noticeGood = false;

  void _show(String message, {bool good = false}) {
    if (mounted) {
      setState(() {
        _notice = message;
        _noticeGood = good;
      });
    }
  }

  static Future<void> _deleteQuietly(File? f) async {
    try {
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> _toggleAuto() async {
    setState(() => _autoCapture = !_autoCapture);
    await ref.read(settingsRepositoryProvider).setBool(autoCaptureSetting, _autoCapture);
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null) return;
    setState(() => _torch = !_torch);
    try {
      await camera.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    final colors = context.statusColors;
    final state = _state;
    final ready = state?.status == GuideStatus.ready;
    final guideColor = ready ? colors.correct : Colors.white;
    final problem = _problem;
    final message = _processing
        ? 'Reading the sheet…'
        : problem != null
            ? 'Scanning paused: read the note below'
            : (_notice ?? state?.message ?? 'Point the camera at the answer sheet');
    final messageColor = problem != null
        ? colors.uncertain
        : _processing || _notice == null
            ? (ready ? colors.correct : Colors.black87)
            : (_noticeGood ? colors.correct : colors.uncertain);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_ctx?.exam.title ?? 'Scan papers', overflow: TextOverflow.ellipsis),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: Space.l),
              child: Text('$_saved saved', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: _fatal != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Text(_fatal!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
            )
          : Stack(
              children: [
                if (camera != null && camera.value.isInitialized)
                  Center(child: CameraPreview(camera))
                else
                  const Center(child: CircularProgressIndicator()),
                // Sheet-shaped guide.
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.86,
                    child: AspectRatio(
                      aspectRatio: SheetLayout.frameWidth / SheetLayout.frameHeight,
                      child: CustomPaint(painter: _GuidePainter(guideColor)),
                    ),
                  ),
                ),
                Positioned(
                  left: Space.l,
                  right: Space.l,
                  top: Space.l,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(Radii.l),
                    ),
                    child: Row(
                      children: [
                        if (_processing)
                          const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Icon(
                            problem != null
                                ? Icons.pause_circle_outline
                                : ready
                                    ? Icons.check_circle
                                    : Icons.crop_free,
                            color: messageColor,
                            size: 20,
                          ),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(color: messageColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (problem != null)
                  Positioned(
                    left: Space.l,
                    right: Space.l,
                    bottom: Space.l,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
                      child: ScanProblemPanel(problem: problem, onAcknowledge: _acknowledge),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: _fatal != null
          ? null
          : SafeArea(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: Space.l, horizontal: Space.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ToggleButton(
                      icon: _autoCapture ? Icons.motion_photos_auto : Icons.motion_photos_off,
                      label: _autoCapture ? 'Auto on' : 'Auto off',
                      onTap: _toggleAuto,
                    ),
                    Semantics(
                      button: true,
                      label: 'Take photo',
                      child: GestureDetector(
                        onTap: _processing || problem != null ? null : _capture,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _processing || problem != null ? Colors.white38 : (ready ? colors.correct : Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _ToggleButton(
                      icon: _torch ? Icons.flashlight_on : Icons.flashlight_off,
                      label: _torch ? 'Light on' : 'Light off',
                      onTap: _toggleTorch,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      );
}

/// Corner brackets showing where the sheet should be.
class _GuidePainter extends CustomPainter {
  _GuidePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final l = size.shortestSide * 0.12;
    final w = size.width;
    final h = size.height;
    for (final (x, y, dx, dy) in [(0.0, 0.0, 1.0, 1.0), (w, 0.0, -1.0, 1.0), (w, h, -1.0, -1.0), (0.0, h, 1.0, -1.0)]) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * l, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * l), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => old.color != color;
}
