import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../db/app_database.dart';
import '../secure/secret_store.dart';

/// Append-only record of charged scans (one row per submission key).
///
/// Rows are hash-chained and HMAC-signed with a per-install key from the
/// Android Keystore; SQLite triggers block edits and deletes. Only a one-way
/// hash of each submission key ever leaves the phone.
class ScanLedgerStore {
  ScanLedgerStore(this._db, this._secrets, {this.clock = const Clock(), Random? random})
      : _random = random ?? Random.secure();

  static const String macKeyName = 'acekanner.ledger_mac.v1';
  static final String genesis = '0' * 64;

  final AppDatabase _db;
  final SecretStore _secrets;
  final Clock clock;
  final Random _random;
  List<int>? _macKey;

  /// Hash uploaded to the server for a submission key.
  static String chargeHash(String submissionKey) =>
      sha256.convert(utf8.encode('acekanner-charge|v1|$submissionKey')).toString();

  /// Submission key for a paper whose student is not known (charged per paper).
  static String unidentifiedKey(String examId, String sheetId) =>
      sha256.convert(utf8.encode('acekanner-submission|v1|$examId|sheet:$sheetId')).toString();

  /// Submission key for one quick check of a paper whose student is not
  /// known (each such check is counted).
  static String quickCheckKey(String examId, String checkId) =>
      sha256.convert(utf8.encode('acekanner-submission|v1|$examId|quick:$checkId')).toString();

  Future<List<int>> _key() async {
    if (_macKey != null) return _macKey!;
    final stored = await _secrets.read(macKeyName);
    if (stored != null && RegExp(r'^[0-9a-f]{64}$').hasMatch(stored)) {
      return _macKey = _hex(stored);
    }
    final fresh = List<int>.generate(32, (_) => _random.nextInt(256));
    await _secrets.write(macKeyName, _toHex(fresh));
    return _macKey = fresh;
  }

  Future<bool> isCharged(String submissionKey) async =>
      await (_db.select(_db.scanLedger)..where((t) => t.submissionKey.equals(submissionKey))).getSingleOrNull() != null;

  static String entryHash({
    required String prevHash,
    required String id,
    required String? accountId,
    required String submissionKey,
    required String tier,
    required String? tokenId,
    required DateTime consumedAt,
  }) =>
      sha256
          .convert(utf8.encode([
            prevHash,
            id,
            accountId ?? '',
            submissionKey,
            tier,
            tokenId ?? '',
            consumedAt.toUtc().toIso8601String(),
          ].join('|')))
          .toString();

  /// Appends a charge. Call inside the transaction that saves the paper.
  Future<ScanLedgerRow> append({
    required String submissionKey,
    required String tier,
    String? answerSheetId,
    String? accountId,
    String? tokenId,
  }) async {
    final key = await _key();
    final last = await (_db.select(_db.scanLedger)
          ..orderBy([(t) => OrderingTerm.desc(t.seq)])
          ..limit(1))
        .getSingleOrNull();
    final prev = last?.entryHash ?? genesis;
    final id = newId();
    // Stored with second precision so the hash input round-trips exactly.
    final now = DateTime.fromMillisecondsSinceEpoch(clock.now().millisecondsSinceEpoch ~/ 1000 * 1000, isUtc: true);
    final hash = entryHash(
      prevHash: prev,
      id: id,
      accountId: accountId,
      submissionKey: submissionKey,
      tier: tier,
      tokenId: tokenId,
      consumedAt: now,
    );
    await _db.into(_db.scanLedger).insert(
          ScanLedgerCompanion.insert(
            id: id,
            accountId: Value(accountId),
            submissionKey: submissionKey,
            answerSheetId: Value(answerSheetId),
            tier: tier,
            entitlementTokenId: Value(tokenId),
            consumedAt: now,
            prevHash: prev,
            entryHash: hash,
            mac: Hmac(sha256, key).convert(utf8.encode(hash)).toString(),
          ),
        );
    return (_db.select(_db.scanLedger)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<List<ScanLedgerRow>> unsynced({int limit = 500}) => (_db.select(_db.scanLedger)
        ..where((t) => t.syncedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.seq)])
        ..limit(limit))
      .get();

  Future<void> markSynced(List<String> ids, String receipt) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.scanLedger)..where((t) => t.id.isIn(ids) & t.syncedAt.isNull())).write(
          ScanLedgerCompanion(syncedAt: Value(clock.now()), serverReceipt: Value(receipt)),
        );
  }

  Future<int> countFree({bool unsyncedOnly = false}) async {
    final count = _db.scanLedger.id.count();
    final q = _db.selectOnly(_db.scanLedger)
      ..addColumns([count])
      ..where(_db.scanLedger.tier.equals('free') &
          (unsyncedOnly ? _db.scanLedger.syncedAt.isNull() : const Constant(true)));
    return (await q.getSingle()).read(count) ?? 0;
  }

  /// Re-computes the hash chain and MACs. False means the ledger was altered.
  Future<bool> verifyChain() async {
    final key = await _key();
    final rows = await (_db.select(_db.scanLedger)..orderBy([(t) => OrderingTerm.asc(t.seq)])).get();
    var prev = genesis;
    for (final r in rows) {
      final hash = entryHash(
        prevHash: prev,
        id: r.id,
        accountId: r.accountId,
        submissionKey: r.submissionKey,
        tier: r.tier,
        tokenId: r.entitlementTokenId,
        consumedAt: r.consumedAt,
      );
      if (r.prevHash != prev || r.entryHash != hash) return false;
      if (Hmac(sha256, key).convert(utf8.encode(hash)).toString() != r.mac) return false;
      prev = r.entryHash;
    }
    return true;
  }

  static List<int> _hex(String s) => [for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)];
  static String _toHex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}
