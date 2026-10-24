import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:along_map/along_map.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/routes/presentation/draw_route_controller.dart';
import 'package:mobile_driver/features/routes/presentation/price_keypad_sheet.dart';
import 'package:mobile_driver/features/routes/presentation/routes_list_controller.dart';
import 'package:mobile_driver/features/routes/presentation/widgets/route_widgets.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-12 Draw route — map tap stops, snap chip, reorder, publish (doc 06 D-12).
class DrawRouteScreen extends ConsumerStatefulWidget {
  const DrawRouteScreen({super.key, required this.args});

  final DrawRouteArgs args;

  @override
  ConsumerState<DrawRouteScreen> createState() => _DrawRouteScreenState();
}

class _DrawRouteScreenState extends ConsumerState<DrawRouteScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final home = ref.watch(driverHomeControllerProvider);
    final state = ref.watch(drawRouteControllerProvider(widget.args));
    final controller = ref.read(
      drawRouteControllerProvider(widget.args).notifier,
    );
    final validation = state.priceValidation;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routeDrawTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: AlongMap(
              key: const Key('draw_route_map'),
              styleUrl: AlongStyleLoader.resolveBasemapStyleUrl(
                tilesBase: config.tilesBaseUrl,
                citySlug: home.citySlug,
              ),
              allowDemoStyleFallback: false,
              initialCameraPosition: home.mapCenter == null
                  ? null
                  : MapCamera.forCenter(
                      lat: home.mapCenter!.lat,
                      lng: home.mapCenter!.lng,
                    ),
              onMapClick: (_, latLng) {
                controller.addStopAt(
                  GeoPoint(lat: latLng.latitude, lng: latLng.longitude),
                );
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Material(
              elevation: 8,
              shape: AlongCraft.borderVertical(top: AlongRadius.sheet.x),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(AlongSpace.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.routeDrawHint, style: AlongText.body),
                    const SizedBox(height: AlongSpace.s8),
                    Expanded(
                      child: state.stops.isEmpty
                          ? Center(
                              child: Text(
                                l10n.routeDrawEmptyStops,
                                style: AlongText.body.copyWith(
                                  color: AlongColors.ink500,
                                ),
                              ),
                            )
                          : ReorderableListView.builder(
                              itemCount: state.stops.length,
                              onReorder: controller.reorderStop,
                              itemBuilder: (context, index) {
                                final stop = state.stops[index];
                                return RouteStopRow(
                                  key: ValueKey('draw_stop_${stop.sequence}'),
                                  index: index,
                                  stop: stop,
                                  onPriceTap: () =>
                                      _editPrice(context, stop, controller),
                                  onLabelChanged: stop.isNewStop
                                      ? (label) => controller.updateStopLabel(
                                          stop.sequence,
                                          label,
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                    LoadSurchargeField(
                      value: state.loadSurcharge,
                      onChanged: controller.setLoadSurcharge,
                    ),
                    const SizedBox(height: AlongSpace.s8),
                    if (!validation.isValid && validation.errorKey != null) ...[
                      RoutePriceErrorBanner(errorKey: validation.errorKey!),
                      const SizedBox(height: AlongSpace.s8),
                    ],
                    AlongButton(
                      key: const Key('draw_route_publish_button'),
                      label: l10n.routePublish,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editPrice(
    BuildContext context,
    dynamic stop,
    DrawRouteController controller,
  ) {
    PriceKeypadSheet.show(
      context,
      initialAmount: stop.priceToEnd as Decimal,
      suggestedAmounts: defaultPriceSuggestions(stop.priceToEnd as Decimal),
      onSet: (value) => controller.updateStopPrice(stop.sequence as int, value),
    );
  }
}
