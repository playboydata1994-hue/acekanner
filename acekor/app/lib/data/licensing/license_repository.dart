import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../domain/licensing/entitlement.dart';
import '../../domain/licensing/plan_status.dart';
import '../db/app_database.dart';
import '../settings/settings_repository.dart';

/// The phone's plan state: the last verified entitlement (configured builds)
/// or the phone-only trial (test builds).
class LicenseRepository {
  LicenseRepository(
    this._db,
    this._settings, {
    required this.configured,
    required EntitlementVerifier verifier,
    this.clock = const Clock(),
  }) : _verifier = verifier; // ignore: prefer_initializing_formals

  final AppDatabase _db;
  final SettingsRepository _settings;
  final bool configured;
  final EntitlementVerifier _verifier;
  final Clock clock;
  final Map<String, Entitlement> _verified = {};

  /// The cached entitlement, re-verified (an edited row is ignored).
  Future<Entitlement?> current() async {
    if (!configured) return null;
    final row = await (_db.select(_db.licenseCache)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return null;
    final cached = _verified[row.token];
    if (cached != null) return cached;
    try {
      final e = await _verifier.verify(row.token);
      _verified[row.token] = e;
      return e;
    } on EntitlementException {
      return null;
    }
  }

  /// Saves a newly received, already verified entitlement.
  Future<void> store(Entitlement e) async {
    _verified[e.token] = e;
    await _db
        .into(_db.licenseCache)
        .insertOnConflictUpdate(
          LicenseCacheCompanion.insert(id: const Value(1), token: e.token, storedAt: clock.now()),
        );
  }

  Future<void> clear() => _db.delete(_db.licenseCache).go();

  /// Test builds: starts the phone-only trial (once).
  Future<void> startLocalTrial() async {
    if (configured) return;
    if (await _settings.getString(SettingKeys.localTrialStarted) != null) return;
    await _settings.setString(SettingKeys.localTrialStarted, '${clock.now().toUtc().millisecondsSinceEpoch}');
  }

  Future<PlanStatus> status({bool signedIn = false, String? email}) async {
    final local = await _settings.getString(SettingKeys.localTrialStarted);
    return PlanStatus(
      configured: configured,
      now: clock.now().toUtc(),
      entitlement: await current(),
      localTrialStarted: local == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.tryParse(local) ?? 0, isUtc: true),
      signedIn: signedIn,
      email: email,
    );
  }

  /// Re-emits when the entitlement or the trial changes, and every minute
  /// (so a plan or trial that ends while the app is open locks in time).
  Stream<PlanStatus> watch({bool signedIn = false, String? email}) {
    late final StreamController<PlanStatus> controller;
    StreamSubscription<Object?>? a;
    StreamSubscription<Object?>? b;
    Timer? timer;
    Future<void> emit() async {
      try {
        final s = await status(signedIn: signedIn, email: email);
        if (!controller.isClosed) controller.add(s);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<PlanStatus>(
      onListen: () {
        a = _db.select(_db.licenseCache).watch().listen((_) => emit());
        b = _settings.watchString(SettingKeys.localTrialStarted).listen((_) => emit());
        timer = Timer.periodic(const Duration(minutes: 1), (_) => emit());
      },
      onCancel: () async {
        timer?.cancel();
        await a?.cancel();
        await b?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }
}
