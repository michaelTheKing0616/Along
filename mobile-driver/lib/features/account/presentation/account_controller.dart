import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/payments/data/payments_providers.dart';

class AccountVehicleRow {
  const AccountVehicleRow({
    required this.vehicleId,
    required this.plate,
    required this.active,
  });

  final String vehicleId;
  final String plate;
  final bool active;
}

class AccountState {
  const AccountState({
    this.displayName,
    this.phoneE164,
    this.verifiedStatus,
    this.standing,
    this.vehicles = const [],
    this.documentSummary,
    this.hasPayoutSubaccount = false,
    this.payoutBankLast4,
    this.isLoading = true,
    this.errorMessage,
  });

  final String? displayName;
  final String? phoneE164;
  final String? verifiedStatus;
  final String? standing;
  final List<AccountVehicleRow> vehicles;
  final String? documentSummary;
  final bool hasPayoutSubaccount;
  final String? payoutBankLast4;
  final bool isLoading;
  final String? errorMessage;

  bool get hasMultipleVehicles => vehicles.length > 1;

  AccountState copyWith({
    String? displayName,
    String? phoneE164,
    String? verifiedStatus,
    String? standing,
    List<AccountVehicleRow>? vehicles,
    String? documentSummary,
    bool? hasPayoutSubaccount,
    String? payoutBankLast4,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountState(
      displayName: displayName ?? this.displayName,
      phoneE164: phoneE164 ?? this.phoneE164,
      verifiedStatus: verifiedStatus ?? this.verifiedStatus,
      standing: standing ?? this.standing,
      vehicles: vehicles ?? this.vehicles,
      documentSummary: documentSummary ?? this.documentSummary,
      hasPayoutSubaccount: hasPayoutSubaccount ?? this.hasPayoutSubaccount,
      payoutBankLast4: payoutBankLast4 ?? this.payoutBankLast4,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, AccountState>(AccountController.new);

class AccountController extends AsyncNotifier<AccountState> {
  @override
  Future<AccountState> build() async {
    return _load();
  }

  Future<AccountState> _load() async {
    try {
      final userId = ref.read(alongSupabaseProvider).currentUser?.id;
      if (userId == null) {
        return const AccountState(isLoading: false);
      }

      final gateway = ref.read(alongSupabaseProvider);
      final profileRows = await gateway.selectRows(
        'profiles',
        filters: {'id': userId},
      );
      final driverProfile =
          await ref.read(driverRepositoryProvider).fetchDriverProfile(userId);
      final qrProfile = await ref.read(driverQrRepositoryProvider).fetchProfile(userId);

      final vehicleLinks = await gateway.selectRows(
        'driver_vehicles',
        filters: {'driver_id': userId},
      );
      final vehicles = <AccountVehicleRow>[];
      for (final link in vehicleLinks) {
        final vehicleId = link['vehicle_id'] as String?;
        if (vehicleId == null) continue;
        final vehicleRows = await gateway.selectRows(
          'vehicles',
          filters: {'id': vehicleId},
        );
        if (vehicleRows.isEmpty) continue;
        vehicles.add(
          AccountVehicleRow(
            vehicleId: vehicleId,
            plate: vehicleRows.first['plate_number'] as String? ?? '',
            active: link['active'] as bool? ?? false,
          ),
        );
      }
      vehicles.sort((a, b) {
        if (a.active == b.active) return a.plate.compareTo(b.plate);
        return a.active ? -1 : 1;
      });

      final driverRows = await gateway.selectRows(
        'drivers',
        filters: {'id': userId},
      );
      final payoutLast4 = driverRows.isNotEmpty
          ? driverRows.first['payout_bank_last4'] as String?
          : null;

      final country =
          await ref.read(catalogRepositoryProvider).countryConfig('NG');
      final verifications =
          await ref.read(verificationRepositoryProvider).myVerifications();
      final statusByType = {
        for (final row in verifications) row.documentType: row.status,
      };
      final documentSummary = _documentSummary(
        country.verificationSchema.map((doc) => doc.type).toList(),
        statusByType,
      );

      final profile = profileRows.isNotEmpty ? profileRows.first : null;

      return AccountState(
        displayName: profile?['display_name'] as String?,
        phoneE164: profile?['phone_e164'] as String?,
        verifiedStatus: driverProfile?.verifiedStatus,
        standing: driverProfile?.standing,
        vehicles: vehicles,
        documentSummary: documentSummary,
        hasPayoutSubaccount: qrProfile.hasSubaccount,
        payoutBankLast4: payoutLast4,
        isLoading: false,
      );
    } catch (_) {
      return const AccountState(
        isLoading: false,
        errorMessage: 'load_failed',
      );
    }
  }

  String? _documentSummary(
    List<String> documentTypes,
    Map<String, String> statusByType,
  ) {
    if (documentTypes.isEmpty) return null;
    var approved = 0;
    var pending = 0;
    var rejected = 0;
    for (final type in documentTypes) {
      switch (statusByType[type]) {
        case 'approved':
          approved++;
        case 'pending':
          pending++;
        case 'rejected':
          rejected++;
        default:
          break;
      }
    }
    if (approved == documentTypes.length) return 'all_approved';
    if (rejected > 0) return 'needs_attention';
    if (pending > 0) return 'pending_review';
    return 'incomplete';
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }
}
