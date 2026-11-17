import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/licensing/entitlement.dart';
import '../../domain/licensing/license_status.dart';
import '../db/app_database.dart';
import '../live_query.dart';
import '../repositories/grading_repository.dart';
import '../settings/settings_repository.dart';
import 'scan_ledger.dart';

/// Charges a saved paper against the plan. Called inside the transaction that
/// saves the paper, so a refused charge saves nothing.
abstract interface class ScanCharger {
  /// Throws [ScanLimitException] when the plan does not allow a new scan.
  /// Re-scanning an already charged paper is always free.
  Future<void> charge({required String examId, required String? studentId, required String sheetId});
}

/// The phone's licensing state: the current verified entitlement, the scan
/// ledger and a trusted-time high-water mark.
class LicenseRepository implements ScanCharger {
  LicenseRepository(
    this._db,
    this._ledger,
    this._settings, {
    required this.configured,
    required EntitlementVerifier verifier,
    this.clock = const Clock(),
  }) : _verifier = verifier; // ignore: prefer_initializing_formals

  static const String trustedTimeKey = 'license.trusted_time_ms';

  /// Device time may lag the trusted time this much (time-zone or NTP jitter).
  static const Duration clockTolerance = Duration(minutes: 10);

  final AppDatabase _db;
  final ScanLedgerStore _ledger;
  final SettingsRepository _settings;
  final bool configured;
  final EntitlementVerifier _verifier;
  final Clock clock;
  final Map<String, Entitlement> _verified = {};

  ScanLedgerStore get ledger => _ledger;

  /// The current entitlement, re-verified (a row edited on the phone is ignored).
  Future<Entitlement?> current() async {
    if (!configured) return null;
    final row = await (_db.select(_db.subscriptionEntitlements)..where((t) => t.isCurrent.equals(true)))
        .getSingleOrNull();
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

  /// Saves a newly received (already verified) entitlement and marks the
  /// ledger rows it accounts for as synced.
  Future<void> store(Entitlement e, {List<String> syncedLedgerIds = const []}) {
    return _db.transaction(() async {
      await (_db.update(_db.subscriptionEntitlements)..where((t) => t.isCurrent.equals(true)))
          .write(const SubscriptionEntitlementsCompanion(isCurrent: Value(false)));
      await _db.into(_db.subscriptionEntitlements).insert(
            SubscriptionEntitlementsCompanion.insert(
              id: newId(),
              accountId: e.accountId,
              token: e.token,
              tier: e.premiumPlan ? 'premium' : 'free',
              freeLimit: e.freeLimit,
              freeUsed: e.freeUsed,
              lease: e.lease,
              premiumUntil: Value(e.premiumUntil),
              verifiedAt: e.verifiedAt,
              offlineUntil: e.offlineUntil,
              issuedAt: e.issuedAt,
              tokenId: e.tokenId,
              receivedAt: clock.now(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      _verified[e.token] = e;
      await _ledger.markSynced(syncedLedgerIds, e.tokenId);
      // Server time is trusted: it resets the high-water mark (fixes a clock
      // that was wrong and has been corrected).
      await _settings.setString(trustedTimeKey, '${e.issuedAt.millisecondsSinceEpoch}');
    });
  }

  /// Forgets the entitlement (sign-out). Papers, results and the ledger stay.
  Future<void> clear() => (_db.update(_db.subscriptionEntitlements)..where((t) => t.isCurrent.equals(true)))
      .write(const SubscriptionEntitlementsCompanion(isCurrent: Value(false)));

  /// Device time, and whether it is earlier than a time already trusted.
  Future<(DateTime, bool)> _trustedNow() async {
    final now = clock.now().toUtc();
    final stored = int.tryParse(await _settings.getString(trustedTimeKey) ?? '');
    if (stored != null && now.isBefore(DateTime.fromMillisecondsSinceEpoch(stored, isUtc: true).subtract(clockTolerance))) {
      return (now, true);
    }
    if (stored == null || now.millisecondsSinceEpoch > stored + 60000) {
      await _settings.setString(trustedTimeKey, '${now.millisecondsSinceEpoch}');
    }
    return (now, false);
  }

  Future<LicenseStatus> status({String? email}) async {
    final (now, tampered) = await _trustedNow();
    return LicenseStatus(
      configured: configured,
      entitlement: await current(),
      unsyncedFree: configured ? await _ledger.countFree(unsyncedOnly: true) : 0,
      localFreeUsed: await _ledger.countFree(),
      now: now,
      clockTampered: tampered,
      email: email,
    );
  }

  Stream<LicenseStatus> watch({String? email}) =>
      liveQuery(_db, [_db.subscriptionEntitlements, _db.scanLedger], () => status(email: email));

  @override
  Future<void> charge({required String examId, required String? studentId, required String sheetId}) async {
    final key = studentId != null
        ? GradingRepository.submissionKey(examId, studentId)
        : ScanLedgerStore.unidentifiedKey(examId, sheetId);
    if (await _ledger.isCharged(key)) return;
    final s = await status();
    final tier = s.chargeTier;
    if (tier == null) throw ScanLimitException(s.block!);
    await _ledger.append(
      submissionKey: key,
      tier: tier,
      answerSheetId: sheetId,
      accountId: s.entitlement?.accountId,
      tokenId: s.entitlement?.tokenId,
    );
  }
}
