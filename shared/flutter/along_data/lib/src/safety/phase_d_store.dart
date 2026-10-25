import 'dart:convert';

import 'package:along_data/src/database/along_database.dart';
import 'package:along_data/src/safety/phase_d_rules.dart';

/// Offline copy of the rider's guardian rules and the driver's rest rules.
class PhaseDStore {
  PhaseDStore(this._db);

  static const guardianKey = 'phase_d:guardian';
  static const restKey = 'phase_d:rest';
  static const driveStartedKey = 'phase_d:drive_started';

  final AlongDatabase _db;

  Future<GuardianPrefs> readGuardian() async {
    final raw = await _read(guardianKey);
    if (raw == null) return GuardianPrefs.disabled;
    return GuardianPrefs.fromJson(raw);
  }

  Future<void> writeGuardian(GuardianPrefs prefs) {
    return _write(guardianKey, prefs.toJson());
  }

  Future<RestPrefs> readRest() async {
    final raw = await _read(restKey);
    if (raw == null) return const RestPrefs();
    return RestPrefs.fromJson(raw);
  }

  Future<void> writeRest(RestPrefs prefs) {
    return _write(restKey, prefs.toJson());
  }

  Future<DateTime?> readDriveStarted() async {
    final raw = await _readString(driveStartedKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeDriveStarted(DateTime? started) {
    return _writeString(
      driveStartedKey,
      started?.toUtc().toIso8601String() ?? '',
    );
  }

  Future<Map<String, dynamic>?> _read(String key) async {
    final raw = await _readString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  Future<String?> _readString(String key) async {
    final row = await (_db.select(
      _db.kvStore,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String key, Map<String, dynamic> value) {
    return _writeString(key, jsonEncode(value));
  }

  Future<void> _writeString(String key, String value) {
    return _db
        .into(_db.kvStore)
        .insertOnConflictUpdate(
          KvStoreCompanion.insert(key: key, value: value),
        );
  }
}
