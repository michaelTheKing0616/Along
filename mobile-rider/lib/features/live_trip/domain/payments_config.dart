import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';

/// Whether digital rider payments are enabled (R-27 gate — TS-UI-04).
final digitalPaymentsEnabledProvider = FutureProvider<bool>((ref) async {
  final config = ref.read(configRepositoryProvider);
  final value = await config.configJson('payments.digital_enabled');
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
});

/// Rating tag vocabulary from app_config.
final ratingTagsProvider = FutureProvider<List<String>>((ref) async {
  final config = ref.read(configRepositoryProvider);
  final value = await config.configJson('rating.tags');
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const [
    'safe_driving',
    'fair_fare',
    'clean_vehicle',
    'polite',
    'on_time',
  ];
});
