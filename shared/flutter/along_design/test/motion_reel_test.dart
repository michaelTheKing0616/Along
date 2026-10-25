import 'dart:io';
import 'dart:ui' as ui;

import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('motion reel plays the real ride screens', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    addTearDown(() => AlongMotionPolicy.debugPlayMotion = false);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final record = Platform.environment['RECORD_MOTION'] == '1';
    if (!record) {
      await _pumpReel(tester, Brightness.light);
      await _waitForTiles(tester);
      expect(find.byType(RawImage), findsWidgets);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('Wuse Market to Nyanya'), findsOneWidget);
      expect(find.text('Confirm fare'), findsOneWidget);
      expect(find.text('₦1,500'), findsOneWidget);
      expect(find.textContaining('18,400'), findsNothing);
      expect(find.textContaining('6,400'), findsNothing);
      expect(find.byType(AlongCityMap), findsOneWidget);
      expect(find.byType(AlongMapSketch), findsNothing);
      await tester.pump(const Duration(milliseconds: 5200));
      expect(find.text('Choose a seat'), findsOneWidget);
      expect(find.byType(AlongStrokeCheck), findsWidgets);
      expect(find.text('Hold front right · ₦1,200'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 5000));
      expect(find.text('Arrived'), findsOneWidget);
      expect(find.text('Send thanks'), findsOneWidget);
      expect(find.text('Wuse → Nyanya · ₦1,200'), findsOneWidget);
      expect(tester.takeException(), isNull);
      return;
    }

    for (final brightness in [Brightness.light, Brightness.dark]) {
      final tone = brightness == Brightness.dark ? 'dark' : 'light';
      await _pumpReel(tester, brightness);
      await _waitForTiles(tester);
      expect(find.byType(RawImage), findsWidgets);
      final dir = Directory('/tmp/along-motion-frames-$tone');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      final boundary = tester.renderObject(
        find.byKey(const Key('motion_reel_boundary')),
      ) as RenderRepaintBoundary;
      const frames = 900;
      const step = Duration(microseconds: 16667);
      for (var i = 0; i < frames; i++) {
        await tester.pump(step);
        final image = await tester.runAsync(
          () => boundary.toImage(pixelRatio: 1),
        );
        final bytes = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.png),
        );
        image!.dispose();
        File('${dir.path}/${i.toString().padLeft(4, '0')}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      }
      expect(tester.takeException(), isNull);
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}

Future<void> _pumpReel(WidgetTester tester, Brightness brightness) async {
  imageCache.clear();
  imageCache.clearLiveImages();
  const boundaryKey = Key('motion_reel_boundary');
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(360, 800),
        disableAnimations: false,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: alongTheme(brightness: brightness),
        home: const RepaintBoundary(key: boundaryKey, child: AlongMotionReel()),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _waitForTiles(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    await tester.runAsync(() => precacheImage(image.image, context));
  }
  for (var attempt = 0; attempt < 16; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump();
    final missing = find.byType(RawImage).evaluate().where((element) {
      return (element.widget as RawImage).image == null;
    }).length;
    if (missing == 0 && find.byType(RawImage).evaluate().isNotEmpty) return;
  }
}
