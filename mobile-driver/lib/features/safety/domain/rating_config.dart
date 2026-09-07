import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';

/// Rating tag vocabulary from app_config (doc 02 §11 `rating.tags`).
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
