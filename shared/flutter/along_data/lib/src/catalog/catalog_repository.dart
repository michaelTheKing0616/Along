import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Active city row for D-04 city picker.
class CityOption {
  const CityOption({
    required this.id,
    required this.name,
    required this.slug,
    required this.countryCode,
  });

  final String id;
  final String name;
  final String slug;
  final String countryCode;

  factory CityOption.fromJson(Map<String, dynamic> json) {
    return CityOption(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      countryCode: json['country_code'] as String,
    );
  }
}

/// Mode row from `mode_config` for D-05 chips.
class ModeConfigRow {
  const ModeConfigRow({
    required this.code,
    required this.label,
    required this.iconKey,
    required this.colorToken,
    required this.loadCapacity,
    required this.defaultSeatCapacity,
    required this.sortOrder,
  });

  final String code;
  final String label;
  final String iconKey;
  final String colorToken;
  final String loadCapacity;
  final int defaultSeatCapacity;
  final int sortOrder;

  factory ModeConfigRow.fromJson(Map<String, dynamic> json) {
    return ModeConfigRow(
      code: json['code'] as String,
      label: json['label'] as String,
      iconKey: json['icon_key'] as String,
      colorToken: json['color_token'] as String,
      loadCapacity: json['load_capacity'] as String? ?? 'none',
      defaultSeatCapacity: (json['default_seat_capacity'] as num).toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Document type from `countries.verification_schema`.
class VerificationDocType {
  const VerificationDocType({
    required this.type,
    required this.label,
    required this.pattern,
  });

  final String type;
  final String label;
  final String pattern;

  factory VerificationDocType.fromJson(Map<String, dynamic> json) {
    return VerificationDocType(
      type: json['type'] as String,
      label: json['label'] as String,
      pattern: json['pattern'] as String? ?? r'^.+$',
    );
  }
}

/// Country metadata for plate validation and verification checklist.
class CountryConfig {
  const CountryConfig({
    required this.code,
    required this.verificationSchema,
    required this.platePattern,
  });

  final String code;
  final List<VerificationDocType> verificationSchema;
  final String platePattern;
}

/// Read-only catalog data for onboarding (cities, modes, country schema).
class CatalogRepository {
  CatalogRepository(this._gateway);

  final AlongSupabase _gateway;

  static const _activeCityStatuses = ['alpha', 'beta', 'live'];

  Future<List<CityOption>> activeCities() async {
    try {
      final rows = await _gateway.selectRows(
        'cities',
        inColumn: 'status',
        inValues: _activeCityStatuses,
      );
      final cities = rows.map(CityOption.fromJson).toList(growable: false);
      cities.sort((a, b) => a.name.compareTo(b.name));
      return cities;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<ModeConfigRow>> modeConfigs() async {
    try {
      final rows = await _gateway.selectRows('mode_config');
      final modes = rows.map(ModeConfigRow.fromJson).toList(growable: false);
      modes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return modes;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<CountryConfig> countryConfig(String countryCode) async {
    try {
      final rows = await _gateway.selectRows(
        'countries',
        filters: {'code': countryCode},
      );
      if (rows.isEmpty) {
        throw StateError('Country not found: $countryCode');
      }
      final row = rows.first;
      final schemaJson = row['verification_schema'] as List<dynamic>? ?? const [];
      final regulatory = row['regulatory_flags'] as Map<String, dynamic>? ?? {};
      final platePattern = regulatory['plate_pattern'] as String? ??
          r'^[A-Za-z]{3}[-\s]?\d{3}[A-Za-z]{2}$';

      return CountryConfig(
        code: row['code'] as String,
        verificationSchema: schemaJson
            .cast<Map<String, dynamic>>()
            .map(VerificationDocType.fromJson)
            .toList(growable: false),
        platePattern: platePattern,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
