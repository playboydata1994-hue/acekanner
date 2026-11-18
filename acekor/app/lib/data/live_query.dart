import 'dart:async';

import 'package:drift/drift.dart';

/// A stream that runs [load] now and again whenever any of [tables] change.
/// Bursts of changes are coalesced into one reload, and cancelling never
/// waits on a pending database read.
Stream<T> liveQuery<T>(DatabaseConnectionUser db, List<TableInfo<Table, Object?>> tables, Future<T> Function() load) {
  late final StreamController<T> controller;
  StreamSubscription<Set<TableUpdate>>? updates;
  var loading = false;
  var again = false;

  Future<void> reload() async {
    if (loading) {
      again = true;
      return;
    }
    loading = true;
    try {
      do {
        again = false;
        final value = await load();
        if (controller.isClosed) return;
        controller.add(value);
      } while (again);
    } catch (error, stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    } finally {
      loading = false;
    }
  }

  controller = StreamController<T>(
    onListen: () {
      updates = db.tableUpdates(TableUpdateQuery.onAllTables(tables)).listen((_) => reload());
      reload();
    },
    onCancel: () async {
      await updates?.cancel();
      await controller.close();
    },
  );
  return controller.stream;
}
