import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/routes/domain/route_draft.dart';
import 'package:mobile_driver/features/routes/presentation/draw_route_controller.dart';
import 'package:mobile_driver/features/routes/presentation/fast_route_setup_controller.dart';
import 'package:mobile_driver/features/routes/presentation/routes_list_controller.dart';
import 'package:mobile_driver/features/routes/presentation/widgets/route_widgets.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-10 Routes list — profile cards, empty state, suggested route (doc 06 D-10).
class RoutesListScreen extends ConsumerWidget {
  const RoutesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(routesListControllerProvider);
    final modesAsync = ref.watch(_modeLabelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routesListTitle),
        backgroundColor: AlongColors.surface0,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('routes_add_button'),
        onPressed: () => _startAddRoute(context, ref, state.suggestion),
        label: Text(l10n.routesAddRoute),
        icon: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(routesListControllerProvider.notifier).refresh(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AlongSpace.s16),
                children: [
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AlongSpace.s16),
                      child: Text(
                        l10n.errorGeneric,
                        style: AlongText.body.copyWith(
                          color: AlongColors.semanticDangerFill,
                        ),
                      ),
                    ),
                  if (state.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AlongSpace.s24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.alt_route_rounded,
                            size: 48,
                            color: AlongColors.ink500,
                          ),
                          const SizedBox(height: AlongSpace.s16),
                          Text(
                            l10n.routesEmptyTitle,
                            style: AlongText.heading2,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AlongSpace.s8),
                          Text(
                            l10n.routesEmptyBody,
                            style: AlongText.body.copyWith(color: AlongColors.ink500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (state.suggestion != null)
                      modesAsync.when(
                        data: (labels) => SuggestedRouteCard(
                          suggestion: state.suggestion!,
                          modeLabel: labels[state.suggestion!.modeCode] ??
                              state.suggestion!.modeCode,
                          onTap: () => context.push(
                            AppRoutes.routeFastSetup,
                            extra: state.suggestion,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => SuggestedRouteCard(
                          suggestion: state.suggestion!,
                          modeLabel: state.suggestion!.modeCode,
                          onTap: () => context.push(
                            AppRoutes.routeFastSetup,
                            extra: state.suggestion,
                          ),
                        ),
                      ),
                  ] else ...[
                    for (final profile in state.profiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AlongSpace.s12),
                        child: modesAsync.when(
                          data: (labels) => RouteProfileCard(
                            profile: profile,
                            modeLabel:
                                labels[profile.modeCode] ?? profile.modeCode,
                            onToggleActive: (active) => ref
                                .read(routesListControllerProvider.notifier)
                                .toggleActive(profile, active),
                            onTap: () => context.push(
                              AppRoutes.routeDraw,
                              extra: DrawRouteArgs(
                                existingProfileId: profile.id,
                                initialStops: draftsFromProfile(profile),
                                modeCode: profile.modeCode,
                                initialLoadSurcharge: profile.loadSurchargeAmount ==
                                        null
                                    ? null
                                    : Decimal.parse(
                                        profile.loadSurchargeAmount!.toString(),
                                      ),
                              ),
                            ),
                          ),
                          loading: () => const SizedBox(height: 72),
                          error: (_, __) => RouteProfileCard(
                            profile: profile,
                            modeLabel: profile.modeCode,
                            onToggleActive: (active) => ref
                                .read(routesListControllerProvider.notifier)
                                .toggleActive(profile, active),
                            onTap: () {},
                          ),
                        ),
                      ),
                    if (state.suggestion != null)
                      modesAsync.when(
                        data: (labels) => SuggestedRouteCard(
                          suggestion: state.suggestion!,
                          modeLabel: labels[state.suggestion!.modeCode] ??
                              state.suggestion!.modeCode,
                          onTap: () => context.push(
                            AppRoutes.routeFastSetup,
                            extra: state.suggestion,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => SuggestedRouteCard(
                          suggestion: state.suggestion!,
                          modeLabel: state.suggestion!.modeCode,
                          onTap: () => context.push(
                            AppRoutes.routeFastSetup,
                            extra: state.suggestion,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _startAddRoute(
    BuildContext context,
    WidgetRef ref,
    SuggestedKnownRoute? suggestion,
  ) async {
    if (suggestion != null) {
      await context.push(AppRoutes.routeFastSetup, extra: suggestion);
    } else {
      await context.push(
        AppRoutes.routeDraw,
        extra: const DrawRouteArgs(),
      );
    }
    await ref.read(routesListControllerProvider.notifier).refresh();
  }
}

final _modeLabelsProvider = FutureProvider<Map<String, String>>((ref) async {
  final modes = await ref.read(catalogRepositoryProvider).modeConfigs();
  const locale = 'en-NG';
  return {for (final mode in modes) mode.code: mode.displayLabel(locale)};
});
