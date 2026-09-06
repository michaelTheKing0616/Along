import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';

final tripsHistoryProvider = FutureProvider<List<TripHistoryEntry>>((ref) async {
  return ref.read(tripsRepositoryProvider).completedTrips();
});

final tripDetailProvider =
    FutureProvider.family<TripHistoryEntry?, String>((ref, tripId) async {
  return ref.read(tripsRepositoryProvider).tripHistoryDetail(tripId);
});
