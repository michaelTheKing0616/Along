import 'package:mobile_rider/features/pricing/domain/pricing_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending hail-from-cell intent between R-05 tap and destination pick.
final hailIntentProvider = StateProvider<HailIntent?>((ref) => null);
