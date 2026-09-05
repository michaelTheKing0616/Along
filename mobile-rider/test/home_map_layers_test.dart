import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' as dto;
import 'package:along_map/along_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/features/home/domain/ambient_cell_mapper.dart';

void main() {
  group('AmbientCellMapper', () {
    test('marks cells stale when sample age exceeds presence.stale_after_s', () {
      const staleAfterS = 45;
      final asOf = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final now = asOf.add(const Duration(seconds: staleAfterS + 1));

      final cells = AmbientCellMapper.toMapCells(
        apiCells: [
          dto.AmbientCell(
            cell: 'abc',
            centroid: const dto.Point(lat: 9.07, lng: 7.39),
            mode: const dto.ModeRef(
              code: 'keke',
              label: 'Keke',
              icon_key: 'mode-keke',
              color_token: 'modeKeke',
            ),
            count_bucket: '3-5',
            heading_sectors: [0, 2, 0, 0, 0, 0, 0, 0],
            serves_destination: true,
            eta_band_s: 120,
          ),
        ],
        asOf: asOf,
        staleAfterS: staleAfterS,
        now: now,
      );

      expect(cells.single.stale, isTrue);
    });

    test('fresh cells are not stale within presence.stale_after_s', () {
      const staleAfterS = 45;
      final asOf = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final now = asOf.add(const Duration(seconds: 30));

      final cells = AmbientCellMapper.toMapCells(
        apiCells: [
          dto.AmbientCell(
            cell: 'abc',
            centroid: const dto.Point(lat: 9.07, lng: 7.39),
            mode: const dto.ModeRef(
              code: 'keke',
              label: 'Keke',
              icon_key: 'mode-keke',
              color_token: 'modeKeke',
            ),
            count_bucket: '1-2',
            heading_sectors: [1, 0, 0, 0, 0, 0, 0, 0],
            serves_destination: false,
            eta_band_s: 60,
          ),
        ],
        asOf: asOf,
        staleAfterS: staleAfterS,
        now: now,
      );

      expect(cells.single.stale, isFalse);
    });
  });

  group('HomeMapLayerPolicy', () {
    test('home active layers never include vehicle overlay', () {
      const layers = {
        HomeMapOverlayLayer.puck,
        HomeMapOverlayLayer.ambientCells,
      };

      expect(HomeMapLayerPolicy.isVehicleLayerAllowed(layers), isFalse);
      expect(layers.contains(HomeMapOverlayLayer.ambientCells), isTrue);
    });
  });

  group('GeoJsonBuilder stale ambient styling', () {
    test('includes stale property for map style expressions', () {
      final geojson = GeoJsonBuilder.ambientCells(const [
        AmbientCell(
          center: GeoPoint(lat: 9.07, lng: 7.39),
          bucket: 5,
          count: 4,
          stale: true,
        ),
      ]);

      final props =
          ((geojson['features'] as List).single as Map)['properties'] as Map;
      expect(props['stale'], isTrue);
    });
  });
}
