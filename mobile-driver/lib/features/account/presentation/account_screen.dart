import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/account/presentation/account_controller.dart';
import 'package:mobile_driver/features/account/presentation/emergency_contacts_section.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-24 Account — profile, vehicle, documents, payout, My QR, safety, sign out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  String _documentSummaryLabel(AppLocalizations l10n, String? code) =>
      switch (code) {
        'all_approved' => l10n.accountDocumentsAllApproved,
        'pending_review' => l10n.accountDocumentsPending,
        'needs_attention' => l10n.accountDocumentsNeedsAttention,
        'incomplete' => l10n.accountDocumentsIncomplete,
        _ => l10n.accountDocumentsUnknown,
      };

  String _verifiedLabel(AppLocalizations l10n, String? status) =>
      status == 'verified' ? l10n.accountVerified : l10n.accountUnverified;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(AppRoutes.phone);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncState = ref.watch(accountControllerProvider);

    final p = AlongPalette.of(context);
    return KeyedSubtree(
      key: const Key('account_screen'),
      child: asyncState.when(
        loading: () => DrivePage(
          title: l10n.navAccount,
          children: const [
            SizedBox(height: AlongSpace.s16),
            AlongSkeleton(variant: SkeletonVariant.line),
          ],
        ),
        error: (_, __) => DrivePage(
          title: l10n.navAccount,
          children: [Text(l10n.errorGeneric)],
        ),
        data: (state) {
          if (state.errorMessage != null) {
            return DrivePage(
              title: l10n.navAccount,
              children: [Text(l10n.errorGeneric)],
            );
          }
          final activeVehicle = state.vehicles
              .where((v) => v.active)
              .firstOrNull;
          final verified = state.verifiedStatus == 'verified';
          return DrivePage(
            title: l10n.navAccount,
            children: [
              const SizedBox(height: AlongSpace.s16),
              DriveRows(
                children: [
                  DriveRow(
                    key: const Key('account_profile_tile'),
                    icon: AlongIcons.user,
                    title: state.displayName ?? l10n.accountProfileUnknown,
                    detail:
                        '${state.phoneE164 ?? '—'} · ${_verifiedLabel(l10n, state.verifiedStatus)}',
                    trailingStyle: verified
                        ? AlongType.caption(p).copyWith(color: p.success)
                        : null,
                    chevron: true,
                    onTap: () => context.push(AppRoutes.profile),
                  ),
                ],
              ),
              DriveSection(l10n.accountVehicleHeading),
              DriveRows(
                children: [
                  DriveRow(
                    key: activeVehicle != null
                        ? const Key('account_vehicle_tile')
                        : null,
                    icon: AlongIcons.danfo,
                    title: activeVehicle?.plate ?? l10n.accountVehicleEmpty,
                    detail: state.hasMultipleVehicles
                        ? l10n.accountVehicleActiveHint
                        : null,
                    chevron: true,
                    onTap: () => context.push(AppRoutes.vehicle),
                  ),
                  DriveRow(
                    key: const Key('account_documents_tile'),
                    icon: AlongIcons.receipt,
                    title: l10n.documentsTitle,
                    detail: _documentSummaryLabel(l10n, state.documentSummary),
                    chevron: true,
                    onTap: () => context.push(AppRoutes.documents),
                  ),
                ],
              ),
              DriveSection(l10n.accountPayoutHeading),
              DriveRows(
                children: [
                  DriveRow(
                    key: const Key('account_payout_tile'),
                    icon: AlongIcons.bank,
                    title: l10n.accountPayoutBank,
                    detail: state.hasPayoutSubaccount
                        ? l10n.accountPayoutConfigured(
                            state.payoutBankLast4 ?? '****',
                          )
                        : l10n.accountPayoutNotConfigured,
                    chevron: true,
                    onTap: () => context.push(AppRoutes.myQr),
                  ),
                  DriveRow(
                    key: const Key('account_my_qr_link'),
                    icon: AlongIcons.qrCode,
                    title: l10n.myQrTitle,
                    detail: l10n.myQrAccountSubtitle,
                    chevron: true,
                    onTap: () => context.push(AppRoutes.myQr),
                  ),
                ],
              ),
              DriveSection(l10n.accountPreferencesHeading),
              if (state.cities.isNotEmpty) ...[
                DriveCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AlongSpace.s16,
                    vertical: AlongSpace.s4,
                  ),
                  child: DropdownButtonFormField<String>(
                    key: const Key('account_city_dropdown'),
                    isExpanded: true,
                    initialValue: state.cityId,
                    style: AlongType.label(p),
                    decoration: InputDecoration(
                      labelText: l10n.accountCityLabel,
                      hintText: l10n.accountCityHint,
                      border: InputBorder.none,
                    ),
                    items: state.cities
                        .map(
                          (city) => DropdownMenuItem(
                            value: city.id,
                            child: Text(city.name),
                          ),
                        )
                        .toList(),
                    onChanged: (cityId) async {
                      if (cityId == null) return;
                      await ref
                          .read(accountControllerProvider.notifier)
                          .switchCity(cityId);
                    },
                  ),
                ),
                const SizedBox(height: AlongSpace.s8),
              ],
              DriveRows(
                children: [
                  DriveRow(
                    key: const Key('account_language_tile'),
                    icon: AlongIcons.chat,
                    title: l10n.accountLanguage,
                    trailing: l10n.accountLanguageValue,
                  ),
                ],
              ),
              DriveSection(l10n.accountSafetyHeading),
              DriveRows(
                children: [
                  DriveRow(
                    key: const Key('account_safety_tile'),
                    icon: AlongIcons.sos,
                    title: l10n.accountSafetyHowSos,
                    detail: l10n.accountSafetyHowSosBody,
                  ),
                  DriveRow(
                    icon: AlongIcons.info,
                    title: l10n.accountHelp,
                    chevron: true,
                  ),
                  DriveRow(
                    icon: AlongIcons.shield,
                    title: l10n.accountLegal,
                    chevron: true,
                  ),
                ],
              ),
              const SizedBox(height: AlongSpace.s24),
              const EmergencyContactsSection(),
              const SizedBox(height: AlongSpace.s16),
              AlongButton(
                key: const Key('account_sign_out'),
                label: l10n.accountSignOut,
                variant: AlongButtonVariant.secondary,
                onPressed: () => _signOut(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }
}
