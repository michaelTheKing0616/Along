import 'package:along_core/along_core.dart' hide formatMoney;
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/routes/presentation/draw_route_controller.dart';
import 'package:mobile_driver/features/routes/presentation/fast_route_setup_controller.dart';
import 'package:mobile_driver/features/routes/presentation/price_keypad_sheet.dart';
import 'package:mobile_driver/features/routes/presentation/routes_list_controller.dart';
import 'package:mobile_driver/features/routes/presentation/widgets/route_widgets.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-11 Fast route setup — 1-tap publish for pre-matched routes (doc 06 D-11).
class FastRouteSetupScreen extends ConsumerWidget {
  const FastRouteSetupScreen({super.key, required this.suggestion});

  final SuggestedKnownRoute suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(fastRouteSetupControllerProvider(suggestion));
    final controller =
        ref.read(fastRouteSetupControllerProvider(suggestion).notifier);
    final validation = state.priceValidation;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routeFastSetupTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.routeFastSetupQuestion, style: AlongText.heading1),
              const SizedBox(height: AlongSpace.s8),
              Text(
                l10n.routeFastSetupSubtitle(suggestion.stages.length),
                style: AlongText.body.copyWith(color: AlongColors.ink500),
              ),
              const SizedBox(height: AlongSpace.s24),
              Expanded(
                child: ListView(
                  children: [
                    for (final stop in state.stops)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AlongSpace.s8),
                        child: ListTile(
                          title: Text(stop.displayName),
                          trailing: TextButton(
                            key: Key('fast_price_chip_${stop.sequence}'),
                            onPressed: () => _editPrice(context, stop, controller),
                            child: Text(
                              l10n.routePriceToEnd(
                                formatMoney(stop.priceToEnd.toBigInt().toInt()),
                              ),
                            ),
                          ),
                        ),
                      ),
                    LoadSurchargeField(
                      value: state.loadSurcharge,
                      onChanged: controller.setLoadSurcharge,
                    ),
                  ],
                ),
              ),
              if (!validation.isValid && validation.errorKey != null) ...[
                RoutePriceErrorBanner(errorKey: validation.errorKey!),
                const SizedBox(height: AlongSpace.s12),
              ],
              AlongButton(
                key: const Key('fast_route_publish_button'),
                label: l10n.routeYesPublish,
                variant: AlongButtonVariant.yellow,
                visualState: state.canPublish
                    ? AlongButtonVisualState.normal
                    : AlongButtonVisualState.disabled,
                onPressed: state.canPublish
                    ? () async {
                        final ok = await controller.publish();
                        if (!context.mounted) return;
                        if (ok) {
                          await ref
                              .read(routesListControllerProvider.notifier)
                              .refresh();
                          if (context.mounted) {
                            if (GoRouter.of(context).canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.routesTab);
                            }
                          }
                        }
                      }
                    : null,
              ),
              const SizedBox(height: AlongSpace.s12),
              AlongButton(
                key: const Key('fast_route_edit_prices_button'),
                label: l10n.routeEditPrices,
                variant: AlongButtonVariant.secondary,
                onPressed: state.stops.isEmpty
                    ? null
                    : () => _editPrice(context, state.stops.first, controller),
              ),
              const SizedBox(height: AlongSpace.s12),
              AlongButton(
                key: const Key('fast_route_draw_manually_button'),
                label: l10n.routeDrawManually,
                variant: AlongButtonVariant.tertiary,
                onPressed: () => context.pushReplacement(
                  AppRoutes.routeDraw,
                  extra: DrawRouteArgs(
                    initialStops: state.stops,
                    modeCode: suggestion.modeCode,
                    initialLoadSurcharge: state.loadSurcharge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editPrice(
    BuildContext context,
    dynamic stop,
    FastRouteSetupController controller,
  ) {
    PriceKeypadSheet.show(
      context,
      initialAmount: stop.priceToEnd as Decimal,
      suggestedAmounts: defaultPriceSuggestions(stop.priceToEnd as Decimal),
      onSet: (value) => controller.updateStopPrice(stop.sequence as int, value),
    );
  }
}
