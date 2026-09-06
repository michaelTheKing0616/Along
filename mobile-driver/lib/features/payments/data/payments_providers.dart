import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';

/// Whether digital payments are enabled platform-wide (P4-E-02 gate).
final digitalPaymentsEnabledProvider = FutureProvider<bool>((ref) async {
  final config = ref.read(configRepositoryProvider);
  final value = await config.configJson('payments.digital_enabled');
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
});

final driverQrRepositoryProvider = Provider<DriverQrRepository>((ref) {
  return DriverQrRepository(ref.watch(alongSupabaseProvider));
});

final driverQrProfileProvider =
    FutureProvider.autoDispose<DriverQrProfile>((ref) async {
  final userId = ref.watch(alongSupabaseProvider).currentUser?.id;
  if (userId == null) {
    throw StateError('Not signed in');
  }
  return ref.read(driverQrRepositoryProvider).fetchProfile(userId);
});

final driverStickerRequestsProvider =
    FutureProvider.autoDispose<List<QrStickerRequest>>((ref) async {
  final userId = ref.watch(alongSupabaseProvider).currentUser?.id;
  if (userId == null) return const [];
  return ref.read(driverQrRepositoryProvider).fetchStickerRequests(userId);
});

final driverDigitalPaymentsProvider =
    FutureProvider.autoDispose<List<DriverDigitalPayment>>((ref) async {
  final userId = ref.watch(alongSupabaseProvider).currentUser?.id;
  if (userId == null) return const [];
  return ref.read(driverQrRepositoryProvider).fetchDigitalPayments(userId);
});
