#!/usr/bin/env dart
// Generates a minimal PMTiles v3 header for Abuja fixture tests (P1-E-02).
// Regenerate: dart run tool/generate_abuja_fixture.dart

import 'dart:io';
import 'dart:typed_data';

void main() {
  final outPaths = [
    'assets/fixtures/abuja_fixture.pmtiles',
    'test/fixtures/abuja_fixture.pmtiles',
  ];

  final bytes = _buildMinimalPmtilesHeader(
    minLonE7: (7.35 * 1e7).round(),
    minLatE7: (9.00 * 1e7).round(),
    maxLonE7: (7.55 * 1e7).round(),
    maxLatE7: (9.20 * 1e7).round(),
    centerLonE7: (7.3986 * 1e7).round(),
    centerLatE7: (9.0765 * 1e7).round(),
    minZoom: 10,
    maxZoom: 14,
    centerZoom: 12,
  );

  for (final path in outPaths) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    stdout.writeln('Wrote ${file.path} (${bytes.length} bytes)');
  }
}

Uint8List _buildMinimalPmtilesHeader({
  required int minLonE7,
  required int minLatE7,
  required int maxLonE7,
  required int maxLatE7,
  required int centerLonE7,
  required int centerLatE7,
  required int minZoom,
  required int maxZoom,
  required int centerZoom,
}) {
  final buffer = ByteData(127);
  var offset = 0;

  void writeBytes(List<int> values) {
    for (final value in values) {
      buffer.setUint8(offset++, value);
    }
  }

  void writeUint64(int value) {
    buffer.setUint64(offset, value, Endian.little);
    offset += 8;
  }

  void writeInt32(int value) {
    buffer.setInt32(offset, value, Endian.little);
    offset += 4;
  }

  writeBytes('PMTiles'.codeUnits);
  buffer.setUint8(offset++, 3); // version
  writeUint64(127); // root directory offset (after header)
  writeUint64(0); // root directory length
  writeUint64(0); // json metadata offset
  writeUint64(0); // json metadata length
  writeUint64(0); // leaf directory offset
  writeUint64(0); // leaf directory length
  writeUint64(127); // tile data offset
  writeUint64(0); // tile data length
  writeUint64(0); // addressed tiles count
  writeUint64(0); // tile entries count
  writeUint64(0); // tile contents count
  buffer.setUint8(offset++, 1); // clustered
  buffer.setUint8(offset++, 0); // internal compression: none
  buffer.setUint8(offset++, 1); // tile compression: gzip
  buffer.setUint8(offset++, 1); // tile type: mvt
  buffer.setUint8(offset++, minZoom);
  buffer.setUint8(offset++, maxZoom);
  writeInt32(minLonE7);
  writeInt32(minLatE7);
  writeInt32(maxLonE7);
  writeInt32(maxLatE7);
  buffer.setUint8(offset++, centerZoom);

  assert(offset == 127);
  return buffer.buffer.asUint8List();
}
