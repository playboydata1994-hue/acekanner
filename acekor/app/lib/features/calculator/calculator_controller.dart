import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../data/errors.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/roster_repository.dart';
import '../../data/settings/settings_repository.dart';
import '../../domain/licensing/plan_status.dart';
import '../../domain/scoring/score_entry.dart';

/// What the academic calculator shows.
class CalcState {
  const CalcState({
    this.loaded = false,
    this.subjectId,
    this.sectionId,
    this.activity,
    this.student,
    this.entry = const ScoreEntry.empty(50),
    this.savedPoints,
    this.showingSaved = false,
    this.quickMax = 50,
  });

  final bool loaded;
  final String? subjectId;

  /// Section filter for search order and continuous entry (null = all).
  final String? sectionId;
  final ActivityView? activity;
  final StudentView? student;
  final ScoreEntry entry;

  /// The score already saved for this student in this activity.
  final int? savedPoints;

  /// The display shows [savedPoints]; the next key press starts a new score.
  final bool showingSaved;

  /// Denominator when no activity is chosen (quick computing only).
  final int quickMax;

  int get maxPoints => activity?.maxPoints ?? quickMax;

  CalcState copyWith({
    bool? loaded,
    String? Function()? subjectId,
    String? Function()? sectionId,
    ActivityView? Function()? activity,
    StudentView? Function()? student,
    ScoreEntry? entry,
    int? Function()? savedPoints,
    bool? showingSaved,
    int? quickMax,
  }) => CalcState(
    loaded: loaded ?? this.loaded,
    subjectId: subjectId == null ? this.subjectId : subjectId(),
    sectionId: sectionId == null ? this.sectionId : sectionId(),
    activity: activity == null ? this.activity : activity(),
    student: student == null ? this.student : student(),
    entry: entry ?? this.entry,
    savedPoints: savedPoints == null ? this.savedPoints : savedPoints(),
    showingSaved: showingSaved ?? this.showingSaved,
    quickMax: quickMax ?? this.quickMax,
  );
}

/// Result of pressing the green SAVE key.
sealed class SaveAttempt {
  const SaveAttempt();
}

class NeedSubject extends SaveAttempt {
  const NeedSubject();
}

class NeedActivity extends SaveAttempt {
  const NeedActivity();
}

class NeedStudent extends SaveAttempt {
  const NeedStudent();
}

class NeedScore extends SaveAttempt {
  const NeedScore();
}

class PlanLocked extends SaveAttempt {
  const PlanLocked(this.block);
  final PlanBlock block;
}

class ConfirmReplace extends SaveAttempt {
  const ConfirmReplace(this.previous, this.points);
  final int previous;
  final int points;
}

class Saved extends SaveAttempt {
  const Saved({
    required this.scoreId,
    required this.previous,
    required this.studentId,
    required this.studentName,
    required this.activityId,
    required this.activityLabel,
    required this.points,
    required this.maxPoints,
    required this.nextStudentName,
    required this.classDone,
  });
  final String scoreId;
  final int? previous;
  final String studentId;
  final String studentName;
  final String activityId;
  final String activityLabel;
  final int points;
  final int maxPoints;

  /// Continuous entry moved on to this student.
  final String? nextStudentName;

  /// Continuous entry: every student in the class list has a score.
  final bool classDone;
}

class SaveFailed extends SaveAttempt {
  const SaveFailed(this.message);
  final String message;
}

final calculatorProvider = NotifierProvider<CalculatorController, CalcState>(CalculatorController.new);

class CalculatorController extends Notifier<CalcState> {
  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  @override
  CalcState build() {
    Future.microtask(_restore);
    return const CalcState();
  }

  /// Restores the last class and activity.
  Future<void> _restore() async {
    final s = ref.read(appSettingsProvider);
    final settings = await _settings.all();
    String? read(String k) => (settings[k] ?? '').isEmpty ? null : settings[k];
    final quickMax = int.tryParse(settings[SettingKeys.quickMax] ?? '') ?? s.quickMax;
    var subjectId = read(SettingKeys.currentSubject);
    if (subjectId != null) {
      final subject = await ref.read(subjectsRepositoryProvider).subject(subjectId);
      if (subject == null || subject.deletedAt != null) subjectId = null;
    }
    ActivityView? activity;
    final activityId = read(SettingKeys.currentActivity);
    if (subjectId != null && activityId != null) {
      activity = await ref.read(activitiesRepositoryProvider).activity(activityId);
      if (activity == null || activity.row.deletedAt != null || activity.row.subjectId != subjectId) activity = null;
    }
    state = CalcState(
      loaded: true,
      subjectId: subjectId,
      sectionId: subjectId == null ? null : read(SettingKeys.currentSection),
      activity: activity,
      quickMax: quickMax,
      entry: ScoreEntry.empty(activity?.maxPoints ?? quickMax),
    );
  }

  Future<void> selectClass(String? subjectId, {String? sectionId}) async {
    final sameSubject = subjectId == state.subjectId;
    state = state.copyWith(
      subjectId: () => subjectId,
      sectionId: () => sectionId,
      activity: sameSubject ? null : () => null,
      student: sameSubject ? null : () => null,
      savedPoints: sameSubject ? null : () => null,
      showingSaved: sameSubject ? null : false,
      entry: sameSubject ? null : ScoreEntry.empty(state.quickMax),
    );
    await _settings.setMany({
      SettingKeys.currentSubject: subjectId ?? '',
      SettingKeys.currentSection: sectionId ?? '',
      if (!sameSubject) SettingKeys.currentActivity: '',
    });
  }

  Future<void> selectActivity(ActivityView activity) async {
    state = state.copyWith(activity: () => activity, entry: state.entry.withMaximum(activity.maxPoints));
    await _settings.setString(SettingKeys.currentActivity, activity.id);
    await _loadSaved();
  }

  /// Re-reads the current activity (after it was edited).
  Future<void> refreshActivity() async {
    final a = state.activity;
    if (a == null) return;
    final fresh = await ref.read(activitiesRepositoryProvider).activity(a.id);
    if (fresh == null || fresh.row.deletedAt != null) {
      state = state.copyWith(activity: () => null, entry: ScoreEntry.empty(state.quickMax), savedPoints: () => null);
      return;
    }
    state = state.copyWith(activity: () => fresh, entry: state.entry.withMaximum(fresh.maxPoints));
  }

  Future<void> selectStudent(StudentView student) async {
    state = state.copyWith(student: () => student, entry: state.entry.cleared(), showingSaved: false);
    await _settings.pushRecent(SettingKeys.recentStudents, student.id);
    await _loadSaved();
  }

  void clearStudent() {
    state = state.copyWith(
      student: () => null,
      savedPoints: () => null,
      showingSaved: false,
      entry: state.entry.cleared(),
    );
  }

  Future<void> setQuickMax(int max) async {
    if (max < 1 || max > 1000) return;
    state = state.copyWith(quickMax: max, entry: state.activity == null ? state.entry.withMaximum(max) : null);
    await _settings.setInt(SettingKeys.quickMax, max);
  }

  /// Shows the student's saved score for the current activity, if any.
  Future<void> _loadSaved() async {
    final a = state.activity;
    final s = state.student;
    if (a == null || s == null) {
      state = state.copyWith(savedPoints: () => null, showingSaved: false);
      return;
    }
    final row = await ref.read(scoresRepositoryProvider).score(a.id, s.id);
    if (state.activity?.id != a.id || state.student?.id != s.id) return;
    if (row == null) {
      state = state.copyWith(savedPoints: () => null, showingSaved: false);
    } else {
      state = state.copyWith(
        savedPoints: () => row.points,
        showingSaved: true,
        entry: ScoreEntry.ofValue(row.points, a.maxPoints),
      );
    }
  }

  /// A digit key. Returns the rejection, if any.
  EntryRejection? press(int digit) {
    final base = state.showingSaved ? state.entry.cleared() : state.entry;
    final r = base.press(digit);
    if (r.rejected != null) {
      if (state.showingSaved) return r.rejected;
      return r.rejected;
    }
    state = state.copyWith(entry: r.entry, showingSaved: false);
    return null;
  }

  EntryRejection? backspace() {
    if (state.showingSaved) {
      state = state.copyWith(entry: state.entry.cleared(), showingSaved: false);
      return null;
    }
    final r = state.entry.backspace();
    state = state.copyWith(entry: r.entry);
    return r.rejected;
  }

  /// The green SAVE key. [replaceConfirmed]: the instructor agreed to replace
  /// an existing score.
  Future<SaveAttempt> save({bool replaceConfirmed = false}) async {
    final s = state;
    if (s.subjectId == null) return const NeedSubject();
    final activity = s.activity;
    if (activity == null) return const NeedActivity();
    final student = s.student;
    if (student == null) return const NeedStudent();
    final points = s.entry.value;
    if (points == null) return const NeedScore();
    final plan = ref.read(planStatusProvider);
    final block = plan.block(activity.kind);
    if (block != null) return PlanLocked(block);

    final scores = ref.read(scoresRepositoryProvider);
    final settings = ref.read(appSettingsProvider);
    try {
      final existing = await scores.score(activity.id, student.id);
      if (existing != null && existing.points == points && s.showingSaved) {
        return const SaveFailed('This score is already saved.');
      }
      if (existing != null && existing.points != points && settings.confirmReplace && !replaceConfirmed) {
        return ConfirmReplace(existing.points, points);
      }
      // A student found outside the class list joins it.
      await ref.read(subjectsRepositoryProvider).enrolStudents(s.subjectId!, [student.id]);
      final out = await scores.save(activity.id, student.id, points);

      String? nextName;
      var classDone = false;
      if (settings.continuousEntry) {
        final next = await scores.nextWithoutScore(
          activity.id,
          s.subjectId!,
          sectionId: s.sectionId,
          afterStudentId: student.id,
        );
        if (next != null) {
          nextName = next.natural;
          state = state.copyWith(
            student: () => next,
            savedPoints: () => null,
            showingSaved: false,
            entry: state.entry.cleared(),
          );
        } else {
          classDone = true;
          clearStudent();
        }
      } else {
        state = state.copyWith(savedPoints: () => points, showingSaved: true);
      }
      return Saved(
        scoreId: out.scoreId,
        previous: out.previous,
        studentId: student.id,
        studentName: student.natural,
        activityId: activity.id,
        activityLabel: activity.label,
        points: points,
        maxPoints: activity.maxPoints,
        nextStudentName: nextName,
        classDone: classDone,
      );
    } on DataError catch (e) {
      return SaveFailed(e.message);
    } catch (e) {
      return SaveFailed('The score could not be saved ($e).');
    }
  }

  /// Undoes a save (restores the previous score, or removes the new one).
  Future<void> undo(Saved saved) async {
    final scores = ref.read(scoresRepositoryProvider);
    if (saved.previous == null) {
      await scores.deleteScore(saved.scoreId);
    } else {
      await scores.updateScore(saved.scoreId, saved.previous!);
    }
    final student = await ref.read(rosterRepositoryProvider).student(saved.studentId);
    if (student != null && state.activity?.id == saved.activityId) {
      state = state.copyWith(student: () => student, entry: state.entry.cleared(), showingSaved: false);
      await _loadSaved();
    }
  }
}
