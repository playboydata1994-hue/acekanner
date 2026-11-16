import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../db/app_database.dart';

/// Writes the append-only, hash-chained `audit_logs` table.
///
/// entry_hash = SHA-256 of the previous entry's hash and this entry's fields,
/// so removing or editing any entry breaks every hash after it. Details hold
/// IDs and counts only, never student names.
class AuditLogger {
  AuditLogger(this._db, {this.clock = const Clock()});

  static final String genesisHash = '0' * 64;

  final AppDatabase _db;
  final Clock clock;

  /// Appends an entry. Runs inside the caller's transaction when there is one,
  /// so the entry commits (or rolls back) together with the change.
  Future<void> record({
    required String event,
    required String entityType,
    String? entityId,
    String? examinationId,
    Map<String, Object?>? details,
    String actor = 'instructor',
  }) {
    return _db.transaction(() async {
      final last = await (_db.select(_db.auditLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.seq)])
            ..limit(1))
          .getSingleOrNull();
      final prev = last?.entryHash ?? genesisHash;
      final id = newId();
      final seconds = clock.now().millisecondsSinceEpoch ~/ 1000;
      final detailsJson = details == null ? null : jsonEncode(details);
      final hash = entryHash(
        prevHash: prev,
        id: id,
        occurredAtSeconds: seconds,
        actor: actor,
        event: event,
        entityType: entityType,
        entityId: entityId,
        examinationId: examinationId,
        details: detailsJson,
      );
      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: id,
              occurredAt: DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
              actor: actor,
              event: event,
              entityType: entityType,
              entityId: Value(entityId),
              examinationId: Value(examinationId),
              details: Value(detailsJson),
              prevHash: prev,
              entryHash: hash,
            ),
          );
    });
  }

  static String entryHash({
    required String prevHash,
    required String id,
    required int occurredAtSeconds,
    required String actor,
    required String event,
    required String entityType,
    String? entityId,
    String? examinationId,
    String? details,
  }) {
    final payload = [
      prevHash,
      id,
      '$occurredAtSeconds',
      actor,
      event,
      entityType,
      entityId ?? '',
      examinationId ?? '',
      details ?? '',
    ].join('\u001f');
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Returns the `seq` of the first entry whose hash does not verify, or null
  /// when the whole chain is intact.
  Future<int?> findBrokenEntry() async {
    final rows = await (_db.select(_db.auditLogs)
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
    var prev = genesisHash;
    for (final r in rows) {
      final expected = entryHash(
        prevHash: prev,
        id: r.id,
        occurredAtSeconds: r.occurredAt.millisecondsSinceEpoch ~/ 1000,
        actor: r.actor,
        event: r.event,
        entityType: r.entityType,
        entityId: r.entityId,
        examinationId: r.examinationId,
        details: r.details,
      );
      if (r.prevHash != prev || r.entryHash != expected) return r.seq;
      prev = r.entryHash;
    }
    return null;
  }
}
