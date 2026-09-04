import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

/// Manages MapLibre tile cache with a 150 MB LRU cap (doc 05 §8, doc 07 §4).
class TileCacheManager {
  TileCacheManager({
    required this.cacheDirectory,
    this.maxBytes = defaultMaxBytes,
  });

  static const defaultMaxBytes = 150 * 1024 * 1024;

  final Directory cacheDirectory;
  final int maxBytes;

  static const fixturePmtilesAsset = 'assets/fixtures/abuja_fixture.pmtiles';

  /// Seeds the cache directory with the Abuja fixture PMTiles for offline tests.
  Future<CachedTileBundle> seedAbujaFixture() async {
    await cacheDirectory.create(recursive: true);
    final target = File(p.join(cacheDirectory.path, 'abuja_fixture.pmtiles'));
    if (!await target.exists()) {
      final bytes = await rootBundle.load(fixturePmtilesAsset);
      await target.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }
    return CachedTileBundle(
      pmtilesPath: target.path,
      cacheDirectory: cacheDirectory,
    );
  }

  /// Returns total bytes used by `.pmtiles` files in the cache directory.
  Future<int> currentUsageBytes() async {
    if (!await cacheDirectory.exists()) return 0;
    var total = 0;
    await for (final entity in cacheDirectory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.pmtiles')) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Evicts oldest `.pmtiles` files until usage is under [maxBytes].
  Future<void> enforceLimit() async {
    if (!await cacheDirectory.exists()) return;

    final files = <File>[];
    await for (final entity in cacheDirectory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.pmtiles')) {
        files.add(entity);
      }
    }

    files.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );

    var usage = await currentUsageBytes();
    for (final file in files) {
      if (usage <= maxBytes) break;
      usage -= await file.length();
      await file.delete();
    }
  }
}

/// Local cached tile bundle ready for offline style resolution.
class CachedTileBundle {
  const CachedTileBundle({
    required this.pmtilesPath,
    required this.cacheDirectory,
  });

  final String pmtilesPath;
  final Directory cacheDirectory;
}
