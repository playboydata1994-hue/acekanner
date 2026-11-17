import 'dart:convert';

/// How the engine read one group of bubbles.
enum MarkState {
  answered,
  blank,
  multiple,
  uncertain;

  static MarkState parse(String code) => MarkState.values.firstWhere(
        (s) => s.name == code,
        orElse: () => MarkState.uncertain,
      );
}

class GroupReading {
  const GroupReading({
    required this.state,
    required this.mask,
    required this.scores,
    required this.confidence,
    this.erasure = false,
  });

  factory GroupReading.fromJson(Map<String, dynamic> j) => GroupReading(
        state: MarkState.parse(j['state'] as String),
        mask: j['mask'] as int,
        scores: [for (final s in j['scores'] as List) (s as num).toDouble()],
        confidence: (j['confidence'] as num).toDouble(),
        erasure: j['erasure'] as bool? ?? false,
      );

  final MarkState state;

  /// Bit i = choice i read as filled (or suggested, when uncertain).
  final int mask;
  final List<double> scores;
  final double confidence;

  /// A clear answer accepted despite a fainter, probably erased, mark.
  final bool erasure;
}

class OmrQualityInfo {
  const OmrQualityInfo({
    required this.edgeWidthMm,
    required this.contrast,
    required this.glare,
    required this.reprojectionMm,
    required this.score,
  });

  factory OmrQualityInfo.fromJson(Map<String, dynamic> j) => OmrQualityInfo(
        edgeWidthMm: (j['edgeWidthMm'] as num).toDouble(),
        contrast: (j['contrast'] as num).toDouble(),
        glare: (j['glare'] as num).toDouble(),
        reprojectionMm: (j['reprojectionMm'] as num).toDouble(),
        score: (j['score'] as num).toDouble(),
      );

  final double edgeWidthMm;
  final double contrast;
  final double glare;
  final double reprojectionMm;

  /// 0–1 summary.
  final double score;
}

/// Result of analysing one photo.
sealed class OmrReading {
  const OmrReading();

  static OmrReading parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    if (j['ok'] != true) {
      return OmrFailure(
        code: j['error'] as String? ?? 'unknown',
        message: j['message'] as String? ?? 'The photo could not be read. Please try again.',
        markersFound: j['markersFound'] as int? ?? 0,
        detectedItemCount: j['detectedItemCount'] as int?,
      );
    }
    final set = j['set'];
    return OmrSheetReading(
      raw: json,
      engineVersion: j['engineVersion'] as String? ?? '',
      template: j['template'] as String,
      questions: [for (final q in j['questions'] as List) GroupReading.fromJson(q as Map<String, dynamic>)],
      idColumns: [for (final c in j['idColumns'] as List) GroupReading.fromJson(c as Map<String, dynamic>)],
      studentNumber: j['studentNumber'] as String,
      studentNumberClear: j['studentNumberClear'] as bool,
      set: set == null ? null : GroupReading.fromJson(set as Map<String, dynamic>),
      qr: j['qr'] as String?,
      quality: OmrQualityInfo.fromJson(j['quality'] as Map<String, dynamic>),
      elapsedMs: j['elapsedMs'] as int? ?? 0,
    );
  }
}

class OmrFailure extends OmrReading {
  const OmrFailure({
    required this.code,
    required this.message,
    this.markersFound = 0,
    this.detectedItemCount,
  });

  final String code;
  final String message;
  final int markersFound;
  final int? detectedItemCount;

  /// The instructor-facing explanation, with detail where it helps.
  String get explanation => switch (code) {
        'wrong_template' when detectedItemCount != null =>
          'This is a $detectedItemCount-item answer sheet, but this examination uses a different one.',
        'old_sheet_design' =>
          'This answer sheet was printed from an older version of ACEkanner (round bubbles). '
              'Print new sheets for this examination from Answer sheets.',
        _ => message,
      };
}

class OmrSheetReading extends OmrReading {
  const OmrSheetReading({
    required this.raw,
    required this.engineVersion,
    required this.template,
    required this.questions,
    required this.idColumns,
    required this.studentNumber,
    required this.studentNumberClear,
    required this.set,
    required this.qr,
    required this.quality,
    required this.elapsedMs,
  });

  /// The engine's JSON, kept with the paper for audit and re-analysis.
  final String raw;
  final String engineVersion;
  final String template;
  final List<GroupReading> questions;
  final List<GroupReading> idColumns;

  /// Shaded digits; '?' marks an unclear column.
  final String studentNumber;
  final bool studentNumberClear;
  final GroupReading? set;
  final String? qr;
  final OmrQualityInfo quality;
  final int elapsedMs;

  int get flaggedCount => questions.where((q) => q.state == MarkState.uncertain).length;

  /// Flagged answers among questions 1..[used] (later ones are not graded).
  int flaggedWithin(int used) =>
      questions.take(used).where((q) => q.state == MarkState.uncertain).length;

  /// Answers with two or more circles shaded among questions 1..[used].
  int multipleWithin(int used) =>
      questions.take(used).where((q) => q.state == MarkState.multiple).length;

  /// Final answers as read: questions after [used] (not graded) never wait
  /// for a decision; their unclear marks count as no answer.
  Map<int, int?> initialAnswers(int used) => {
        for (var i = 0; i < questions.length; i++)
          i + 1: questions[i].state != MarkState.uncertain
              ? questions[i].mask
              : (i < used ? null : 0),
      };
}
