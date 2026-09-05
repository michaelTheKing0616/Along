import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:decimal/decimal.dart';

/// In-progress stop while drawing a route (D-12).
class RouteStopDraft {
  const RouteStopDraft({
    required this.sequence,
    required this.location,
    required this.priceToEnd,
    this.routeStageId,
    this.matchedStageName,
    this.customLabel,
    this.isNewStop = false,
  });

  final int sequence;
  final GeoPoint location;
  final String? routeStageId;
  final String? matchedStageName;
  final String? customLabel;
  final Decimal priceToEnd;
  final bool isNewStop;

  String get displayName =>
      matchedStageName ?? customLabel ?? 'Stop ${sequence + 1}';

  RouteStopDraft copyWith({
    int? sequence,
    GeoPoint? location,
    String? routeStageId,
    String? matchedStageName,
    String? customLabel,
    Decimal? priceToEnd,
    bool? isNewStop,
    bool clearMatchedStage = false,
    bool clearCustomLabel = false,
  }) {
    return RouteStopDraft(
      sequence: sequence ?? this.sequence,
      location: location ?? this.location,
      routeStageId: clearMatchedStage ? null : routeStageId ?? this.routeStageId,
      matchedStageName:
          clearMatchedStage ? null : matchedStageName ?? this.matchedStageName,
      customLabel: clearCustomLabel ? null : customLabel ?? this.customLabel,
      priceToEnd: priceToEnd ?? this.priceToEnd,
      isNewStop: isNewStop ?? this.isNewStop,
    );
  }

  RouteProfileStopInput toPublishInput() {
    return RouteProfileStopInput(
      sequence: sequence,
      routeStageId: routeStageId,
      location: routeStageId == null ? location : null,
      customLabel: isNewStop ? customLabel : null,
      priceToEnd: priceToEnd.toDouble(),
    );
  }
}

List<RouteStopDraft> draftsFromSuggestion(SuggestedKnownRoute suggestion) {
  final sorted = [...suggestion.stages]
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  return [
    for (var i = 0; i < sorted.length; i++)
      RouteStopDraft(
        sequence: sorted[i].sequence,
        location: const GeoPoint(lat: 9.0765, lng: 7.3986),
        routeStageId: sorted[i].stageId,
        matchedStageName: sorted[i].name,
        priceToEnd: Decimal.parse(sorted[i].defaultPriceToEnd.toString()),
      ),
  ];
}

List<RouteStopDraft> draftsFromProfile(DriverRouteProfileRow profile) {
  final sorted = [...profile.stops]..sort((a, b) => a.sequence.compareTo(b.sequence));
  return [
    for (var i = 0; i < sorted.length; i++)
      RouteStopDraft(
        sequence: sorted[i].sequence,
        location: const GeoPoint(lat: 9.0765, lng: 7.3986),
        routeStageId: sorted[i].routeStageId,
        customLabel: sorted[i].customLabel,
        matchedStageName: sorted[i].customLabel == null && sorted[i].routeStageId != null
            ? 'Stage ${sorted[i].sequence}'
            : null,
        priceToEnd: Decimal.parse(sorted[i].priceToEnd.toString()),
      ),
  ];
}
