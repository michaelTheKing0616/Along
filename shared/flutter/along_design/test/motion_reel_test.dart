import 'dart:io';
import 'dart:ui' as ui;

import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('motion reel runs the five ride transitions', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    addTearDown(() => AlongMotionPolicy.debugPlayMotion = false);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const boundaryKey = Key('motion_reel_boundary');
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(360, 800), disableAnimations: false),
        child: MaterialApp(
          home: RepaintBoundary(key: boundaryKey, child: AlongMotionReel()),
        ),
      ),
    );
    await tester.pump();

    final record = Platform.environment['RECORD_MOTION'] == '1';
    if (!record) {
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Wuse to Nyanya'), findsOneWidget);
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Arrived'), findsOneWidget);
      expect(tester.takeException(), isNull);
      return;
    }

    final dir = Directory('/tmp/along-motion-frames');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final boundary =
        tester.renderObject(find.byKey(boundaryKey)) as RenderRepaintBoundary;
    const frames = 150;
    const step = Duration(milliseconds: 100);
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
  }, timeout: const Timeout(Duration(minutes: 3)));
}
