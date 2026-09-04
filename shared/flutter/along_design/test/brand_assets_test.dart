import 'dart:convert';
import 'dart:typed_data';

import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P0-E-06 brand assets', () {
    test('SVG wordmarks load and contain vector paths', () async {
      for (final path in [alongLogoBlackSvg, alongLogoYellowSvg]) {
        final svg = await rootBundle.loadString(path);
        expect(svg, contains('<svg'));
        expect(svg, contains('<path'));
        expect(svg, isNot(contains('stitch_logo_geometric_sharp')));
      }

      final black = await rootBundle.loadString(alongLogoBlackSvg);
      expect(black, contains('#0A0A0A'));

      final yellow = await rootBundle.loadString(alongLogoYellowSvg);
      expect(yellow, contains('#F7D117'));
    });

    test('Android legacy launcher icons exist at all densities', () async {
      const expectedSizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };

      for (final entry in androidLegacyLauncherIcons.entries) {
        final data = await rootBundle.load(entry.value);
        expect(data.lengthInBytes, greaterThan(100));
        final (width, height) = _pngDimensions(data);
        expect(width, expectedSizes[entry.key]);
        expect(height, expectedSizes[entry.key]);
      }
    });

    test('Android adaptive icon layers exist at all densities', () async {
      const expectedSizes = {
        'mdpi': 108,
        'hdpi': 162,
        'xhdpi': 216,
        'xxhdpi': 324,
        'xxxhdpi': 432,
      };

      for (final density in expectedSizes.keys) {
        for (final layer in [
          androidAdaptiveForegroundIcons,
          androidAdaptiveBackgroundIcons,
        ]) {
          final data = await rootBundle.load(layer[density]!);
          final (width, height) = _pngDimensions(data);
          expect(width, expectedSizes[density]);
          expect(height, expectedSizes[density]);
        }
      }

      for (final xmlPath in androidAdaptiveIconXml) {
        final xml = await rootBundle.loadString(xmlPath);
        expect(xml, contains('adaptive-icon'));
        expect(xml, contains('ic_launcher_background'));
        expect(xml, contains('ic_launcher_foreground'));
      }
    });

    test('iOS AppIcon.appiconset assets load', () async {
      for (final path in iosAppIconAssets) {
        if (path.endsWith('.json')) {
          final json = jsonDecode(await rootBundle.loadString(path)) as Map;
          expect(json['images'], isA<List>());
          continue;
        }
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(100));
        final (width, height) = _pngDimensions(data);
        expect(width, height);
        expect(width, greaterThan(0));
      }
    });

    test('splash assets load', () async {
      final logo = await rootBundle.load(alongSplashLogo);
      final (logoW, logoH) = _pngDimensions(logo);
      expect(logoW, 512);
      expect(logoH, 512);

      final bg = await rootBundle.load(alongSplashBackground);
      expect(bg.lengthInBytes, greaterThan(0));
    });

    testWidgets('icons render at representative densities', (tester) async {
      final samples = [
        androidLegacyLauncherIcons['mdpi']!,
        androidLegacyLauncherIcons['xxxhdpi']!,
        androidAdaptiveForegroundIcons['mdpi']!,
        androidAdaptiveForegroundIcons['xxxhdpi']!,
        iosAppIconAssets.firstWhere((p) => p.contains('1024x1024')),
      ];

      for (final asset in samples) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Image.asset(
                asset,
                package: 'along_design',
                width: 48,
                height: 48,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, isA<AssetBundleImageProvider>());
      }
    });
  });
}

(int width, int height) _pngDimensions(ByteData data) {
  final bytes = data.buffer.asUint8List();
  expect(bytes.length, greaterThan(24));
  expect(bytes[0], 0x89);
  expect(bytes[1], 0x50);
  final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
  final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
  return (width, height);
}
