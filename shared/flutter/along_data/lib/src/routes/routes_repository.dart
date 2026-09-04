import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Driver route profile publish and graph bundle fetch.
class RoutesRepository {
  RoutesRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<Map<String, dynamic>> publishDriverRoute(
    Map<String, dynamic> request,
  ) async {
    try {
      return await _gateway.rpc('publish_driver_route', params: request);
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
