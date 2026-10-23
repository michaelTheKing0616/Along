import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/account/presentation/emergency_contacts_section.dart';
import 'package:mobile_rider/features/marketplace/presentation/fare_shield_screen.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/rider_prefs/rider_prefs_store.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-26 Account & settings — profile, prefs, cash payment default, sign out.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  RiderProfile? _profile;
  List<CityOption> _cities = const [];
  bool _womenOnlyRegulatory = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profileRepo = ref.read(riderProfileRepositoryProvider);
    final profile = await profileRepo.fetchCurrentProfile();
    final cities = await ref.read(catalogRepositoryProvider).activeCities();
    final regulatory = profile?.homeCityId != null
        ? await profileRepo.womenOnlyMatchingEnabled(profile!.homeCityId)
        : false;
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _cities = cities;
      _womenOnlyRegulatory = regulatory;
      _loading = false;
    });
  }

  Future<void> _updateHomeCity(String? cityId) async {
    if (cityId == null || cityId == _profile?.homeCityId) return;
    setState(() => _saving = true);
    try {
      await ref.read(homeControllerProvider.notifier).switchCity(cityId);
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateWayfinding(WayfindingMode mode) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(riderProfileRepositoryProvider)
          .updatePrefs(wayfindingMode: mode);
      await ref.read(riderPrefsStoreProvider).setWayfindingMode(mode);
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateSort(SortCriterion sort) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(riderProfileRepositoryProvider)
          .updatePrefs(savedSort: sort);
      await ref.read(riderPrefsStoreProvider).setSavedSort(sort);
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateWomenOnly(bool value) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(riderProfileRepositoryProvider)
          .updatePrefs(womenOnlyPref: value);
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go(AppRoutes.phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = _profile;

    return ListView(
      padding: const EdgeInsets.all(AlongSpace.s16),
      children: [
        Text(l10n.accountProfileHeading, style: AlongText.overline),
        const SizedBox(height: AlongSpace.s8),
        ListTile(
          key: const Key('account_profile_name'),
          contentPadding: EdgeInsets.zero,
          title: Text(profile?.displayName ?? '—', style: AlongText.title),
          subtitle: Text(profile?.phoneE164 ?? '—', style: AlongText.body),
        ),
        const SizedBox(height: AlongSpace.s24),
        Text(l10n.accountPreferencesHeading, style: AlongText.overline),
        const SizedBox(height: AlongSpace.s8),
        if (_cities.isNotEmpty) ...[
          Text(l10n.accountCityLabel, style: AlongText.bodyStrong),
          const SizedBox(height: AlongSpace.s8),
          DropdownButtonFormField<String>(
            key: const Key('account_city_dropdown'),
            isExpanded: true,
            value: profile?.homeCityId,
            decoration: InputDecoration(hintText: l10n.accountCityHint),
            items: _cities
                .map(
                  (city) =>
                      DropdownMenuItem(value: city.id, child: Text(city.name)),
                )
                .toList(),
            onChanged: _saving ? null : _updateHomeCity,
          ),
          const SizedBox(height: AlongSpace.s16),
        ],
        Text(l10n.accountWayfindingLabel, style: AlongText.bodyStrong),
        const SizedBox(height: AlongSpace.s8),
        SegmentedButton<WayfindingMode>(
          key: const Key('account_wayfinding'),
          segments: [
            ButtonSegment(
              value: WayfindingMode.text,
              label: Text(l10n.wayfindingModeText),
            ),
            ButtonSegment(
              value: WayfindingMode.map,
              label: Text(l10n.wayfindingModeMap),
            ),
            ButtonSegment(
              value: WayfindingMode.audio,
              label: Text(l10n.wayfindingModeAudio),
            ),
          ],
          selected: {profile?.wayfindingMode ?? WayfindingMode.text},
          onSelectionChanged: _saving
              ? null
              : (selection) => _updateWayfinding(selection.first),
        ),
        const SizedBox(height: AlongSpace.s16),
        Text(l10n.accountSortLabel, style: AlongText.bodyStrong),
        const SizedBox(height: AlongSpace.s8),
        SortChips(
          key: const Key('account_saved_sort'),
          selected: _sortOption(profile?.savedSort),
          onSelected: _saving
              ? (_) {}
              : (option) => _updateSort(_sortCriterion(option)),
        ),
        if (_womenOnlyRegulatory) ...[
          const SizedBox(height: AlongSpace.s16),
          SwitchListTile(
            key: const Key('account_women_only'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.accountWomenOnlyLabel,
              style: AlongText.bodyStrong,
            ),
            subtitle: Text(l10n.accountWomenOnlyHint, style: AlongText.caption),
            value: profile?.womenOnlyPref ?? false,
            onChanged: _saving ? null : _updateWomenOnly,
          ),
        ],
        const SizedBox(height: AlongSpace.s24),
        Text(l10n.accountPaymentHeading, style: AlongText.overline),
        const SizedBox(height: AlongSpace.s8),
        ListTile(
          key: const Key('account_payment_cash'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.payments_outlined),
          title: Text(
            l10n.accountPaymentCashDefault,
            style: AlongText.bodyStrong,
          ),
          subtitle: Text(l10n.accountPaymentCashHint, style: AlongText.caption),
        ),
        const SizedBox(height: AlongSpace.s24),
        Text(l10n.accountSafetyHeading, style: AlongText.overline),
        const SizedBox(height: AlongSpace.s8),
        ListTile(
          key: const Key('account_stage_radar'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.stageRadarTitle, style: AlongText.bodyStrong),
          onTap: () => context.push(AppRoutes.stageRadar),
        ),
        ListTile(
          key: const Key('account_fare_shield'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.fareShieldTitle, style: AlongText.bodyStrong),
          onTap: () => context.push(
            AppRoutes.fareShield,
            extra: const FareShieldArgs(offeredLabel: ''),
          ),
        ),
        ListTile(
          key: const Key('account_guardian'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.guardianTitle, style: AlongText.bodyStrong),
          subtitle: Text(l10n.guardianEnabled, style: AlongText.caption),
          onTap: () => context.push(AppRoutes.guardian),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.accountSafetyHowSos, style: AlongText.bodyStrong),
          subtitle: Text(
            l10n.accountSafetyHowSosBody,
            style: AlongText.caption,
          ),
        ),
        const SizedBox(height: AlongSpace.s24),
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
          onPressed: _signOut,
        ),
      ],
    );
  }

  SortOption _sortOption(SortCriterion? sort) => switch (sort) {
    SortCriterion.cheapest => SortOption.cheapest,
    SortCriterion.fastest => SortOption.fastest,
    SortCriterion.leastStrenuous => SortOption.leastStrenuous,
    _ => SortOption.recommended,
  };

  SortCriterion _sortCriterion(SortOption option) => switch (option) {
    SortOption.cheapest => SortCriterion.cheapest,
    SortOption.fastest => SortCriterion.fastest,
    SortOption.leastStrenuous => SortCriterion.leastStrenuous,
    SortOption.recommended => SortCriterion.recommended,
  };
}
