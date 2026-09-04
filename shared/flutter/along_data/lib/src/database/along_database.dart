import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:along_data/src/database/tables.dart';

part 'along_database.g.dart';

@DriftDatabase(tables: [
  KvStore,
  GraphCache,
  PlanCache,
  TripCache,
  StepsCache,
  PendingActions,
])
class AlongDatabase extends _$AlongDatabase {
  AlongDatabase(super.executor);

  AlongDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  static Future<AlongDatabase> open({String fileName = 'along.db'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));
    return AlongDatabase(NativeDatabase(file));
  }
}
