import 'dart:convert';

import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Resolves `app_config` values (doc 02 §2.3) — corridor > city > country > global.
class ConfigRepository {
  ConfigRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<num> configNum(
    String key, {
    String? cityId,
    String? countryCode,
  }) async {
    try {
      final value = await _resolveConfigValue(
        key,
        cityId: cityId,
        countryCode: countryCode,
      );
      final numeric = _parseNumeric(value);
      if (numeric == null) {
        throw StateError('Non-numeric app_config value for key: $key');
      }
      return numeric;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<Object?> configJson(
    String key, {
    String? cityId,
    String? countryCode,
  }) async {
    try {
      return await _resolveConfigValue(
        key,
        cityId: cityId,
        countryCode: countryCode,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<Object?> _resolveConfigValue(
    String key, {
    String? cityId,
    String? countryCode,
  }) async {
    final rows = await _gateway.selectRows(
      'app_config',
      filters: {'key': key},
    );
    if (rows.isEmpty) {
      throw StateError('Missing app_config key: $key');
    }

    Object? corridor;
    Object? city;
    Object? country;
    Object? global;

    for (final row in rows) {
      final scopeType = row['scope_type'] as String?;
      final value = _parseConfigValue(row['value']);
      if (value == null) continue;

      switch (scopeType) {
        case 'corridor':
          corridor ??= value;
        case 'city':
          if (cityId != null && row['scope_id'] == cityId) {
            city = value;
          }
        case 'country':
          if (countryCode != null && row['scope_id'] == countryCode) {
            country = value;
          }
        case 'global':
          global ??= value;
      }
    }

    return corridor ?? city ?? country ?? global ??
        (throw StateError('No resolved value for app_config key: $key'));
  }

  Object? _parseConfigValue(Object? value) {
    if (value == null) return null;
    if (value is Map || value is List) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return jsonDecode(trimmed);
      }
      return value;
    }
    return value;
  }

  num? _parseNumeric(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return num.tryParse(value.toString());
  }
}
