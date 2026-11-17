import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/bootstrap.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/logo.dart';
import '../../data/security/pin_store.dart';

final pinStoreProvider = Provider<PinStore>((ref) => PinStore(ref.watch(secretStoreProvider)));

/// Fingerprint / face check; replaceable in tests.
abstract interface class Biometrics {
  Future<bool> available();
  Future<bool> authenticate(String reason);
}

class DeviceBiometrics implements Biometrics {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } catch (_) {
      return false;
    }
  }
}

final biometricsProvider = Provider<Biometrics>((ref) => DeviceBiometrics());

/// Whether the app is locked right now.
final appLockProvider = NotifierProvider<AppLockController, bool>(AppLockController.new);

class AppLockController extends Notifier<bool> {
  bool _decidedAtStart = false;
  DateTime? _pausedAt;

  /// Locks again after this long in the background.
  static const Duration relockAfter = Duration(minutes: 1);

  @override
  bool build() => false;

  /// Called once the settings are known (cold start).
  void startup(bool enabled) {
    if (_decidedAtStart) return;
    _decidedAtStart = true;
    if (enabled) state = true;
  }

  void paused() => _pausedAt = DateTime.now();

  void resumed(bool enabled) {
    final p = _pausedAt;
    _pausedAt = null;
    if (enabled && p != null && DateTime.now().difference(p) >= relockAfter) state = true;
  }

  void lock() => state = true;
  void unlock() => state = false;
}

/// Covers the app with the lock screen while locked (PIN on, Settings › App lock).
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _enabled {
    if (ref.read(bootstrapControllerProvider).value is! BootstrapReady) return false;
    return ref.read(appSettingsProvider).lockEnabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = ref.read(appLockProvider.notifier);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) ctrl.paused();
    if (state == AppLifecycleState.resumed) ctrl.resumed(_enabled);
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(bootstrapControllerProvider).value is BootstrapReady;
    if (ready) {
      final settings = ref.watch(settingsProvider);
      if (settings.hasValue) {
        final enabled = settings.value!.lockEnabled;
        WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(appLockProvider.notifier).startup(enabled));
      }
    }
    final locked = ready && ref.watch(appLockProvider);
    return Stack(
      children: [
        widget.child,
        if (locked) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _message;
  bool _checking = false;
  bool _bioAvailable = false;
  int? _length;

  @override
  void initState() {
    super.initState();
    ref.read(pinStoreProvider).pinLength().then((n) {
      if (mounted) setState(() => _length = n);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!ref.read(appSettingsProvider).lockBiometric) return;
      final ok = await ref.read(biometricsProvider).available();
      if (!mounted) return;
      setState(() => _bioAvailable = ok);
      if (ok) await _biometric();
    });
  }

  Future<void> _biometric() async {
    final ok = await ref.read(biometricsProvider).authenticate('Unlock ACEkor Grading Sheet');
    if (ok && mounted) ref.read(appLockProvider.notifier).unlock();
  }

  Future<void> _digit(int d) async {
    if (_checking || _pin.length >= 6) return;
    setState(() {
      _pin += '$d';
      _message = null;
    });
    if (_pin.length == (_length ?? 6)) await _try();
  }

  Future<void> _try() async {
    if (_pin.length < 4) return;
    final store = ref.read(pinStoreProvider);
    final wait = await store.waitSeconds();
    if (wait > 0) {
      setState(() {
        _pin = '';
        _message = 'Too many wrong PINs. Try again in $wait seconds.';
      });
      return;
    }
    setState(() => _checking = true);
    final ok = await store.verify(_pin);
    if (!mounted) return;
    setState(() => _checking = false);
    if (ok) {
      ref.read(appLockProvider.notifier).unlock();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _pin = '';
      _message = 'Wrong PIN. Try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback onTap, {String? label}) => Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.key,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 80, height: 80, child: Center(child: child)),
        ),
      ),
    );
    Text digit(int d) => Text('$d', style: const TextStyle(fontSize: 32, color: AppColors.white));
    return Material(
      color: AppColors.black,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const AcekorMark(size: 64),
            const SizedBox(height: 16),
            const Text(
              'Enter your PIN',
              style: TextStyle(fontSize: 22, color: AppColors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < (_length ?? 6); i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length ? AppColors.teal : Colors.transparent,
                      border: Border.all(color: AppColors.muted, width: 2),
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 48,
              child: Center(
                child: Text(_message ?? '', style: const TextStyle(color: AppColors.red, fontSize: 16)),
              ),
            ),
            const Spacer(),
            for (final row in const [
              [7, 8, 9],
              [4, 5, 6],
              [1, 2, 3],
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [for (final d in row) key(digit(d), () => _digit(d), label: '$d')],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  key(
                    const Icon(Icons.backspace_outlined, color: AppColors.red),
                    () => setState(() => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1)),
                    label: 'Backspace',
                  ),
                  key(digit(0), () => _digit(0), label: '0'),
                  _bioAvailable
                      ? key(
                          const Icon(Icons.fingerprint, color: AppColors.teal, size: 36),
                          _biometric,
                          label: 'Fingerprint',
                        )
                      : key(const Icon(Icons.check_rounded, color: AppColors.save, size: 36), _try, label: 'OK'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
