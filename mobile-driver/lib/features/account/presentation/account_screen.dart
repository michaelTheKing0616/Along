import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/account/presentation/account_controller.dart';
import 'package:mobile_driver/features/account/presentation/emergency_contacts_section.dart';
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

    return Scaffold(
      key: const Key('account_screen'),
      appBar: AppBar(
        title: Text(l10n.navAccount),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.errorGeneric)),
        data: (state) {
          if (state.errorMessage != null) {
            return Center(child: Text(l10n.errorGeneric));
          }

          final activeVehicle = state.vehicles
              .where((v) => v.active)
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(AlongSpace.s16),
            children: [
              Text(l10n.accountProfileHeading, style: AlongText.overline),
              const SizedBox(height: AlongSpace.s8),
              ListTile(
                key: const Key('account_profile_tile'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  state.displayName ?? l10n.accountProfileUnknown,
                  style: AlongText.title,
                ),
                subtitle: Text(state.phoneE164 ?? '—', style: AlongText.body),
                trailing: Text(
                  _verifiedLabel(l10n, state.verifiedStatus),
                  style: AlongText.caption,
                ),
                onTap: () => context.push(AppRoutes.profile),
              ),
              const SizedBox(height: AlongSpace.s24),
              Text(l10n.accountVehicleHeading, style: AlongText.overline),
              const SizedBox(height: AlongSpace.s8),
              if (activeVehicle != null)
                ListTile(
                  key: const Key('account_vehicle_tile'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_car_outlined),
                  title: Text(activeVehicle.plate, style: AlongText.bodyStrong),
                  subtitle: state.hasMultipleVehicles
                      ? Text(
                          l10n.accountVehicleActiveHint,
                          style: AlongText.caption,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.vehicle),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.accountVehicleEmpty, style: AlongText.body),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.vehicle),
                ),
              if (state.hasMultipleVehicles) ...[
                const SizedBox(height: AlongSpace.s8),
                Text(l10n.accountVehicleSwitchHint, style: AlongText.caption),
              ],
              const SizedBox(height: AlongSpace.s24),
              Text(l10n.accountDocumentsHeading, style: AlongText.overline),
              const SizedBox(height: AlongSpace.s8),
              ListTile(
                key: const Key('account_documents_tile'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.documentsTitle, style: AlongText.bodyStrong),
                subtitle: Text(
                  _documentSummaryLabel(l10n, state.documentSummary),
                  style: AlongText.caption,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.documents),
              ),
              const SizedBox(height: AlongSpace.s24),
              Text(l10n.accountPayoutHeading, style: AlongText.overline),
              const SizedBox(height: AlongSpace.s8),
              ListTile(
                key: const Key('account_payout_tile'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_outlined),
                title: Text(
                  l10n.accountPayoutBank,
                  style: AlongText.bodyStrong,
                ),
                subtitle: Text(
                  state.hasPayoutSubaccount
                      ? l10n.accountPayoutConfigured(
                          state.payoutBankLast4 ?? '****',
                        )
                      : l10n.accountPayoutNotConfigured,
                  style: AlongText.caption,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.myQr),
              ),
              ListTile(
                key: const Key('account_my_qr_link'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code_2_outlined),
                title: Text(l10n.myQrTitle, style: AlongText.bodyStrong),
                subtitle: Text(
                  l10n.myQrAccountSubtitle,
                  style: AlongText.caption,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.myQr),
              ),
              const SizedBox(height: AlongSpace.s24),
              Text(l10n.accountPreferencesHeading, style: AlongText.overline),
              const SizedBox(height: AlongSpace.s8),
              if (state.cities.isNotEmpty) ...[
                Text(l10n.accountCityLabel, style: AlongText.bodyStrong),
                const SizedBox(height: AlongSpace.s8),
                DropdownButtonFormField<String>(
                  key: const Key('account_city_dropdown'),
                  isExpanded: true,
                  value: state.cityId,
                  decoration: InputDecoration(hintText: l10n.accountCityHint),
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
                const SizedBox(height: AlongSpace.s16),
              ],
              ListTile(
                key: const Key('account_language_tile'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.accountLanguage, style: AlongText.bodyStrong),
                subtitle: Text(
                  l10n.accountLanguageValue,
                  style: AlongText.caption,
                ),
              ),
              const SizedBox(height: AlongSpace.s24),
              Text(l10n.accountSafetyHeading, style: AlongText.overline),
              const SizedBox(height: AlongSpace.s8),
              ListTile(
                key: const Key('account_safety_tile'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.accountSafetyHowSos,
                  style: AlongText.bodyStrong,
                ),
                subtitle: Text(
                  l10n.accountSafetyHowSosBody,
                  style: AlongText.caption,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.accountHelp, style: AlongText.bodyStrong),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.accountLegal, style: AlongText.bodyStrong),
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
