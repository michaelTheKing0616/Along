import 'dart:io';

import 'package:along_map/along_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CorridorTilePrecacheService records corridor request', () async {
    final tempDir = Directory.systemTemp.createTempSync('along_corridor_test');
    final service = CorridorTilePrecacheService(cacheDirectory: tempDir);

    await service.precacheCorridor(
      const CorridorPrecacheRequest(
        corridorId: 'abuja-cbd',
        bbox: CorridorBbox(
          minLat: 9.0,
          minLng: 7.3,
          maxLat: 9.1,
          maxLng: 7.5,
        ),
        pmtilesUrl: 'https://tiles.example/abuja.pmtiles',
      ),
    );

    expect(service.recordedRequests, hasLength(1));
    expect(service.recordedRequests.single.corridorId, 'abuja-cbd');
  });
}
