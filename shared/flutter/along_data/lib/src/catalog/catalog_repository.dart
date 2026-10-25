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

/// Resolves a localized mode label from `mode_config.label_i18n` with fallback to
/// [fallbackLabel] (the `label` column) and locale `en`.
String resolveModeLabel({
  required Map<String, String> labelI18n,
  required String fallbackLabel,
  required String locale,
}) {
  if (labelI18n.isEmpty) return fallbackLabel;
  final normalized = locale.replaceAll('_', '-');
  if (labelI18n.containsKey(normalized)) {
    return labelI18n[normalized]!;
  }
  final language = normalized.split('-').first;
  for (final entry in labelI18n.entries) {
    if (entry.key.split('-').first == language) {
      return entry.value;
    }
  }
  return labelI18n['en'] ?? labelI18n['en-NG'] ?? fallbackLabel;
}

/// Mode row from `mode_config` for D-05 chips.
class ModeConfigRow {
  const ModeConfigRow({
    required this.code,
    required this.label,
    required this.labelI18n,
    required this.iconKey,
    required this.colorToken,
    required this.loadCapacity,
    required this.defaultSeatCapacity,
    required this.sortOrder,
    this.layoutPreset,
    this.reviewSeatMax,
  });

  final String code;
  final String label;
  final Map<String, String> labelI18n;
  final String iconKey;
  final String colorToken;
  final String loadCapacity;
  final int defaultSeatCapacity;
  final int sortOrder;
  final Map<String, dynamic>? layoutPreset;
  final int? reviewSeatMax;

  int get reviewSeatLimit => reviewSeatMax ?? defaultSeatCapacity;

  String displayLabel(String locale) => resolveModeLabel(
    labelI18n: labelI18n,
    fallbackLabel: label,
    locale: locale,
  );

  factory ModeConfigRow.fromJson(Map<String, dynamic> json) {
    final rawI18n = json['label_i18n'] as Map<String, dynamic>? ?? const {};
    return ModeConfigRow(
      code: json['code'] as String,
      label: json['label'] as String,
      labelI18n: rawI18n.map(
        (key, value) => MapEntry(key, value as String),
      ),
      iconKey: json['icon_key'] as String,
      colorToken: json['color_token'] as String,
      loadCapacity: json['load_capacity'] as String? ?? 'none',
      defaultSeatCapacity: (json['default_seat_capacity'] as num).toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      layoutPreset: json['layout_preset'] is Map
          ? (json['layout_preset'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            )
          : null,
      reviewSeatMax: (json['review_seat_max'] as num?)?.toInt(),
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

/// Country metadata for plate validation, dial config, and verification checklist.
class CountryConfig {
  const CountryConfig({
    required this.code,
    required this.phonePrefix,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyMinorUnits,
    required this.verificationSchema,
    required this.platePattern,
  });

  final String code;
  final String phonePrefix;
  final String currencyCode;
  final String currencySymbol;
  final int currencyMinorUnits;
  final List<VerificationDocType> verificationSchema;
  final String platePattern;
}

/// Currency display metadata resolved from `countries`.
class CityCurrencyMeta {
  const CityCurrencyMeta({
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyMinorUnits,
  });

  final String currencyCode;
  final String currencySymbol;
  final int currencyMinorUnits;
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

  /// Alias retained for P9-A-01 call sites.
  Future<List<CityOption>> listActiveCities() => activeCities();

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
      final schemaJson =
          row['verification_schema'] as List<dynamic>? ?? const [];
      final regulatory = row['regulatory_flags'] as Map<String, dynamic>? ?? {};
      final platePattern =
          regulatory['plate_pattern'] as String? ??
          r'^[A-Za-z]{3}[-\s]?\d{3}[A-Za-z]{2}$';

      return CountryConfig(
        code: row['code'] as String,
        phonePrefix: row['phone_prefix'] as String,
        currencyCode: row['currency_code'] as String,
        currencySymbol: row['currency_symbol'] as String,
        currencyMinorUnits: (row['currency_minor_units'] as num?)?.toInt() ?? 2,
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

  /// First active country for pre-auth onboarding (phone prefix, currency).
  Future<CountryConfig> defaultActiveCountry() async {
    try {
      final rows = await _gateway.selectRows(
        'countries',
        filters: {'active': true},
      );
      if (rows.isEmpty) {
        throw StateError('No active country configured');
      }
      rows.sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
      return await countryConfig(rows.first['code'] as String);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<CityCurrencyMeta> currencyMetaForCity(String cityId) async {
    try {
      final cityRows = await _gateway.selectRows(
        'cities',
        filters: {'id': cityId},
      );
      if (cityRows.isEmpty) {
        throw StateError('City not found: $cityId');
      }
      final countryCode = cityRows.first['country_code'] as String;
      final countryRows = await _gateway.selectRows(
        'countries',
        filters: {'code': countryCode},
      );
      if (countryRows.isEmpty) {
        throw StateError('Country not found: $countryCode');
      }
      final row = countryRows.first;
      return CityCurrencyMeta(
        currencyCode: row['currency_code'] as String,
        currencySymbol: row['currency_symbol'] as String,
        currencyMinorUnits: (row['currency_minor_units'] as num?)?.toInt() ?? 2,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String> currencyCodeForCity(String cityId) async {
    final meta = await currencyMetaForCity(cityId);
    return meta.currencyCode;
  }

  /// `deployments.branding_config` for the tenant owning [countryCode].
  Future<Map<String, dynamic>> brandingConfigForCountry(
    String countryCode,
  ) async {
    try {
      final countryRows = await _gateway.selectRows(
        'countries',
        filters: {'code': countryCode},
      );
      if (countryRows.isEmpty) return const {};
      final deploymentId = countryRows.first['deployment_id'] as String?;
      if (deploymentId == null) return const {};
      final deploymentRows = await _gateway.selectRows(
        'deployments',
        filters: {'id': deploymentId},
      );
      if (deploymentRows.isEmpty) return const {};
      final raw = deploymentRows.first['branding_config'];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.cast<String, dynamic>();
      return const {};
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Branding for the first active country (pre-auth shell).
  Future<Map<String, dynamic>> brandingConfigForDefaultCountry() async {
    final country = await defaultActiveCountry();
    return brandingConfigForCountry(country.code);
  }
}
