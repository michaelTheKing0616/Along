import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the current plate with spaces or dashes', () {
    for (final raw in ['ABC-123XY', 'ABC 123 XY', 'ABC-123-XY', 'abc123xy']) {
      final plate = parseNigerianPlate(raw);
      expect(plate?.canonical, 'ABC123XY', reason: raw);
      expect(plate?.display, 'ABC-123XY', reason: raw);
    }
  });

  test('normalises O/0 and I/1 in the slot they belong to', () {
    expect(parseNigerianPlate('ABC-I23XY')?.canonical, 'ABC123XY');
    expect(parseNigerianPlate('AB0-123XY')?.canonical, 'ABO123XY');
    expect(parseNigerianPlate('AB123CDE')?.display, 'AB-123-CDE');
  });

  test('reads a plate out of a noisy camera line', () {
    final plates = extractNigerianPlates('LAGOS\nABC 123 XY\nNIGERIA');
    expect(plates.map((plate) => plate.canonical), contains('ABC123XY'));
  });

  test('fuzzy-matches one edit and rejects a different plate', () {
    final close = judgePlateReading(
      ocrText: 'ABC-123XZ',
      expectedPlate: 'ABC-123-XY',
    );
    expect(close?.kind, PlateMatchKind.match);
    expect(close?.distance, 1);

    final exact = judgePlateReading(
      ocrText: 'seen near ABC-I23-XY today',
      expectedPlate: 'ABC-123XY',
    );
    expect(exact?.kind, PlateMatchKind.match);
    expect(exact?.distance, 0);

    final other = judgePlateReading(
      ocrText: 'XYZ-999AA',
      expectedPlate: 'ABC-123XY',
    );
    expect(other?.kind, PlateMatchKind.mismatch);
    expect(other!.distance, greaterThan(1));
  });

  test('keeps scanning when the frame has no plate', () {
    expect(
      judgePlateReading(ocrText: 'hello lagos', expectedPlate: 'ABC-123XY'),
      isNull,
    );
  });

  test('the log stores the result and not an image path', () {
    PlateScanLog.record(PlateMatchKind.match);
    expect(PlateScanLog.last, 'match');
    expect(PlateScanLog.last, isNot(contains('/')));
    expect(PlateScanLog.last, isNot(contains('jpg')));
  });
}
