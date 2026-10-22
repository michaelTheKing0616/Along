import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/profile/presentation/profile_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-04 Driver profile & city (doc 06 D-04).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncState = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.errorGeneric)),
        data: (state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AlongSpace.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.profileSubtitle, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AlongSpace.s24),
                  Text(l10n.nameLabel, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AlongSpace.s8),
                  TextField(
                    key: const Key('profile_name_field'),
                    decoration: InputDecoration(hintText: l10n.nameHint),
                    onChanged: ref
                        .read(profileControllerProvider.notifier)
                        .setDisplayName,
                  ),
                  const SizedBox(height: AlongSpace.s16),
                  Text(l10n.cityLabel, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AlongSpace.s8),
                  DropdownButtonFormField<String>(
                    key: const Key('profile_city_dropdown'),
                    value: state.selectedCityId,
                    items: state.cities
                        .map(
                          (city) => DropdownMenuItem(
                            value: city.id,
                            child: Text(city.name),
                          ),
                        )
                        .toList(),
                    onChanged: ref
                        .read(profileControllerProvider.notifier)
                        .setCity,
                  ),
                  const SizedBox(height: AlongSpace.s16),
                  Text(l10n.genderLabel, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AlongSpace.s8),
                  Wrap(
                    spacing: AlongSpace.s8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.genderFemale),
                        selected: state.gender == 'female',
                        onSelected: (_) => ref
                            .read(profileControllerProvider.notifier)
                            .setGender('female'),
                      ),
                      ChoiceChip(
                        label: Text(l10n.genderMale),
                        selected: state.gender == 'male',
                        onSelected: (_) => ref
                            .read(profileControllerProvider.notifier)
                            .setGender('male'),
                      ),
                      ChoiceChip(
                        label: Text(l10n.genderOther),
                        selected: state.gender == 'other',
                        onSelected: (_) => ref
                            .read(profileControllerProvider.notifier)
                            .setGender('other'),
                      ),
                    ],
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AlongSpace.s16),
                    Text(
                      l10n.errorValidation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AlongColors.semanticDangerFill,
                      ),
                    ),
                  ],
                  const Spacer(),
                  AlongButton(
                    key: const Key('profile_continue_button'),
                    label: l10n.continueButton,
                    onPressed: state.isSubmitting
                        ? null
                        : () async {
                            final ok = await ref
                                .read(profileControllerProvider.notifier)
                                .submit();
                            if (ok && context.mounted) {
                              context.go(AppRoutes.vehicle);
                            }
                          },
                    visualState: state.isSubmitting
                        ? AlongButtonVisualState.loading
                        : AlongButtonVisualState.normal,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
