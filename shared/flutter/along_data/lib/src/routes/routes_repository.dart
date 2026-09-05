import 'package:along_core/along_core.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Driver route profile row from `my_route_profiles` (doc 03 §6).
class DriverRouteProfileRow {
  const DriverRouteProfileRow({
    required this.id,
    required this.modeCode,
    required this.active,
    required this.stops,
    this.routeId,
    this.name,
    this.loadSurchargeAmount,
    this.loadSurchargeCurrency,
  });

  final String id;
  final String? routeId;
  final String modeCode;
  final String? name;
  final bool active;
  final num? loadSurchargeAmount;
  final String? loadSurchargeCurrency;
  final List<DriverRouteStopRow> stops;

  factory DriverRouteProfileRow.fromJson(Map<String, dynamic> json) {
    final stopsRaw = json['stops'] as List<dynamic>? ?? [];
    return DriverRouteProfileRow(
      id: json['id'] as String,
      routeId: json['route_id'] as String?,
      modeCode: json['mode_code'] as String,
      name: json['name'] as String?,
      active: json['active'] as bool? ?? true,
      loadSurchargeAmount: json['load_surcharge_amount'] as num?,
      loadSurchargeCurrency: json['load_surcharge_currency'] as String?,
      stops: stopsRaw
          .cast<Map<String, dynamic>>()
          .map(DriverRouteStopRow.fromJson)
          .toList(growable: false),
    );
  }
}

class DriverRouteStopRow {
  const DriverRouteStopRow({
    required this.sequence,
    required this.priceToEnd,
    required this.currency,
    this.routeStageId,
    this.customLabel,
  });

  final int sequence;
  final String? routeStageId;
  final String? customLabel;
  final num priceToEnd;
  final String currency;

  factory DriverRouteStopRow.fromJson(Map<String, dynamic> json) {
    return DriverRouteStopRow(
      sequence: (json['sequence'] as num).toInt(),
      routeStageId: json['route_stage_id'] as String?,
      customLabel: json['custom_label'] as String?,
      priceToEnd: json['price_to_end'] as num,
      currency: json['currency'] as String? ?? 'NGN',
    );
  }
}

/// Canonical route suggestion from `suggest_known_route` (doc 03 §6).
class SuggestedKnownRoute {
  const SuggestedKnownRoute({
    required this.routeId,
    required this.modeCode,
    required this.stages,
  });

  final String routeId;
  final String modeCode;
  final List<SuggestedKnownStage> stages;

  factory SuggestedKnownRoute.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>;
    final stagesRaw = json['stages'] as List<dynamic>? ?? [];
    return SuggestedKnownRoute(
      routeId: route['id'] as String,
      modeCode: route['mode_code'] as String,
      stages: stagesRaw
          .cast<Map<String, dynamic>>()
          .map(SuggestedKnownStage.fromJson)
          .toList(growable: false),
    );
  }
}

class SuggestedKnownStage {
  const SuggestedKnownStage({
    required this.stageId,
    required this.sequence,
    required this.name,
    required this.defaultPriceToEnd,
  });

  final String stageId;
  final int sequence;
  final String name;
  final num defaultPriceToEnd;

  factory SuggestedKnownStage.fromJson(Map<String, dynamic> json) {
    final stage = json['stage'] as Map<String, dynamic>;
    return SuggestedKnownStage(
      stageId: stage['id'] as String,
      sequence: (stage['sequence'] as num).toInt(),
      name: stage['name'] as String? ?? 'Stop',
      defaultPriceToEnd: json['default_price_to_end'] as num? ?? 0,
    );
  }
}

/// Publish payload stop for `upsert_route_profile`.
class RouteProfileStopInput {
  const RouteProfileStopInput({
    required this.sequence,
    required this.priceToEnd,
    this.routeStageId,
    this.location,
    this.customLabel,
  });

  final int sequence;
  final String? routeStageId;
  final GeoPoint? location;
  final String? customLabel;
  final num priceToEnd;

  Map<String, dynamic> toJson() {
    return {
      'sequence': sequence,
      if (routeStageId != null) 'route_stage_id': routeStageId,
      if (location != null)
        'location': {'lat': location!.lat, 'lng': location!.lng},
      if (customLabel != null && customLabel!.isNotEmpty)
        'custom_label': customLabel,
      'price_to_end': priceToEnd,
    };
  }
}

/// Driver route profile publish and graph bundle fetch (doc 03 §6).
class RoutesRepository {
  RoutesRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<List<DriverRouteProfileRow>> fetchMyRouteProfiles() async {
    try {
      final raw = await _gateway.rpc('my_route_profiles');
      final list = raw is List<dynamic>
          ? raw
          : (raw as Map<String, dynamic>?)?['profiles'] as List<dynamic>? ?? [];
      return list
          .cast<Map<String, dynamic>>()
          .map(DriverRouteProfileRow.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<SuggestedKnownRoute?> suggestKnownRoute() async {
    try {
      final raw = await _gateway.rpc('suggest_known_route');
      if (raw == null) return null;
      return SuggestedKnownRoute.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<Map<String, dynamic>> upsertRouteProfile({
    String? id,
    required String modeCode,
    String? name,
    Money? loadSurcharge,
    required List<RouteProfileStopInput> stops,
  }) async {
    try {
      final payload = <String, dynamic>{
        'mode_code': modeCode,
        'stops': stops.map((s) => s.toJson()).toList(growable: false),
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (loadSurcharge != null)
          'load_surcharge': {
            'amount': loadSurcharge.toApiString(),
            'currency': loadSurcharge.currency,
          },
      };
      final raw = await _gateway.rpc(
        'upsert_route_profile',
        params: {'p_profile': payload},
      );
      return raw as Map<String, dynamic>;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> deactivateRouteProfile(String id) async {
    try {
      await _gateway.rpc('deactivate_route_profile', params: {'p_id': id});
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<num?> suggestedStopPrice({
    required String profileId,
    required int sequence,
    required GeoPoint location,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'suggested_stop_price',
        params: {
          'p_profile_id': profileId,
          'p_sequence': sequence,
          'p_location': {'lat': location.lat, 'lng': location.lng},
        },
      );
      return raw as num?;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<Map<String, dynamic>> fetchGraphBundle({
    required String cityId,
    required String graphVersion,
  }) async {
    try {
      return await _gateway.invokeFunction(
        'graph-bundle',
        body: {
          'city_id': cityId,
          'graph_version': graphVersion,
        },
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
