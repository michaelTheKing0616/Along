import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stages = <String, Widget Function({bool legacy})>{
    'onboarding': ({bool legacy = false}) =>
        AlongFlowOnboarding(legacyCopy: legacy),
    'home': ({bool legacy = false}) => const AlongFlowHome(),
    'rides': ({bool legacy = false}) => const AlongFlowRides(),
    'seats': ({bool legacy = false}) => const AlongFlowSeats(),
    'search': ({bool legacy = false}) => const AlongFlowSearch(),
    'live': ({bool legacy = false}) => const AlongFlowLive(),
    'rating': ({bool legacy = false}) => const AlongFlowRating(),
    'sos': ({bool legacy = false}) => const AlongFlowSos(),
    'guardian': ({bool legacy = false}) => const AlongFlowGuardian(),
    'plate': ({bool legacy = false}) => const AlongFlowPlate(),
    'wallet': ({bool legacy = false}) => const AlongFlowWallet(),
    'day': ({bool legacy = false}) => const AlongFlowDay(),
    'online': ({bool legacy = false}) => const AlongFlowOnline(),
    'offer': ({bool legacy = false}) => const AlongFlowOffer(),
    'earnings': ({bool legacy = false}) => const AlongFlowEarnings(),
    'pickup': ({bool legacy = false}) => const AlongFlowPickup(),
    'quote': ({bool legacy = false}) => const AlongFlowQuote(),
    'matching': ({bool legacy = false}) => const AlongFlowMatching(),
    'recovery': ({bool legacy = false}) => const AlongFlowRecovery(),
    'pin': ({bool legacy = false}) => const AlongFlowTripPin(),
    'driver': ({bool legacy = false}) => const AlongFlowDriver(),
    'nav': ({bool legacy = false}) => const AlongFlowNav(),
    'receipt': ({bool legacy = false}) => const AlongFlowReceipt(),
    'notices': ({bool legacy = false}) => const AlongFlowNotices(),
    'settings': ({bool legacy = false}) => const AlongFlowSettings(),
    'pass': ({bool legacy = false}) => const AlongFlowPass(),
    'split': ({bool legacy = false}) => const AlongFlowSplit(),
    'loading': ({bool legacy = false}) => const AlongFlowLoading(),
    'refresh': ({bool legacy = false}) => const AlongFlowRefresh(),
    'phases': ({bool legacy = false}) => const AlongFlowPhases(),
    'motions': ({bool legacy = false}) => const AlongFlowMotions(),
    'schedule': ({bool legacy = false}) => const AlongFlowSchedule(),
    'stops': ({bool legacy = false}) => const AlongFlowStops(),
    'options': ({bool legacy = false}) => const AlongFlowRideOptions(
      options: AlongRideOptions(
        squeezeFree: true,
        seatHolds: 1,
        womenOnlyRows: [2],
      ),
    ),
    'topup': ({bool legacy = false}) => const AlongFlowTopUp(),
    'payout': ({bool legacy = false}) => const AlongFlowPayout(),
    'offline_home': ({bool legacy = false}) => const AlongFlowOfflineHome(),
    'offline_matching': ({bool legacy = false}) =>
        const AlongFlowOfflineMatching(),
    'offline_live': ({bool legacy = false}) => const AlongFlowOfflineLive(),
  };

  for (final stage in stages.entries) {
    // `goldens/flows/before/` is the frozen pass-1 baseline. Do not regenerate it
    // from these widgets.
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final size in const [Size(360, 800), Size(320, 640)]) {
        final tone = brightness == Brightness.dark ? 'dark' : 'light';
        final label = '${size.width.toInt()}x${size.height.toInt()}';
        testWidgets('${stage.key} $tone $label', (tester) async {
          await _pump(
            tester,
            child: stage.value(),
            brightness: brightness,
            size: size,
          );
          _expectNoLabelWrap(tester, '${stage.key} $tone $label');
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              'goldens/flows/after/${stage.key}_${tone}_$label.png',
            ),
          );
        });
      }
    }
  }

  for (final layout in ['2x4', 'danfo']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final size in const [Size(360, 800), Size(320, 640)]) {
        final tone = brightness == Brightness.dark ? 'dark' : 'light';
        final label = '${size.width.toInt()}x${size.height.toInt()}';
        testWidgets('seat layout $layout $tone $label', (tester) async {
          await _pump(
            tester,
            child: _SeatLayoutPage(
              rows: layout == 'danfo' ? _danfoRows() : _sedanRows(),
            ),
            brightness: brightness,
            size: size,
          );
          _expectNoLabelWrap(tester, 'seat layout $layout $tone $label');
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              'goldens/flows/after/seats_${layout}_${tone}_$label.png',
            ),
          );
        });
      }
    }
  }

  testWidgets('live route mid draw light 360', (tester) async {
    await _pump(
      tester,
      child: const AlongFlowLive(progress: 0.35),
      size: const Size(360, 800),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/flows/after/live_route_35_light_360x800.png'),
    );
  });

  testWidgets('live route mid draw dark 360', (tester) async {
    await _pump(
      tester,
      child: const AlongFlowLive(progress: 0.35),
      brightness: Brightness.dark,
      size: const Size(360, 800),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/flows/after/live_route_35_dark_360x800.png'),
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  Size size = const Size(360, 800),
  Brightness brightness = Brightness.light,
  bool legacy = false,
}) async {
  // The previous screen's decoded tiles stay in the cache after their
  // ImageInfo is disposed. The next map then waits forever on those three
  // edge tiles (rides 320 after rides 360).
  imageCache.clear();
  imageCache.clearLiveImages();
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final theme = legacy
      ? alongTheme().copyWith(
          scaffoldBackgroundColor: AlongPalette.legacy.bg,
          textTheme: AlongType.textTheme(AlongPalette.legacy),
          extensions: [AlongPalette.legacy],
        )
      : alongTheme(brightness: brightness);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: child,
      ),
    ),
  );
  await tester.pump();
  final context = tester.element(find.byType(MaterialApp));
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    await tester.runAsync(() => precacheImage(image.image, context));
  }
  if (find.byType(FlutterMap).evaluate().isNotEmpty) {
    for (var attempt = 0; attempt < 12; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump();
      if (_rawImagesMissing(tester) != 0) continue;
      await tester.pump();
      if (_rawImagesMissing(tester) == 0) break;
    }
  }
  await tester.pump();
  final overflow = tester.takeException();
  expect(overflow, isNull, reason: 'layout overflow');
  if (find.byType(FlutterMap).evaluate().isNotEmpty) {
    expect(_rawImagesMissing(tester), 0, reason: 'map tile failed to paint');
  }
}

int _rawImagesMissing(WidgetTester tester) {
  return find.byType(RawImage).evaluate().where((element) {
    return (element.widget as RawImage).image == null;
  }).length;
}

/// Short labels stay on one line. Ellipsis is allowed. A wrapped chip,
/// fare, or row label fails the golden run before the pixels are compared.
void _expectNoLabelWrap(WidgetTester tester, String stage) {
  final problems = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final render = element.renderObject;
    if (render is! RenderParagraph) continue;
    final plain = render.text.toPlainText();
    if (plain.trim().isEmpty) continue;
    if (render.didExceedMaxLines) {
      problems.add('clipped: $plain');
    }
    if (plain.length > 40) continue;
    final boxes = render.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: plain.length),
    );
    final tops = boxes.map((box) => box.top).toList()..sort();
    var lines = tops.isEmpty ? 1 : 1;
    for (var i = 1; i < tops.length; i++) {
      // Fallback glyphs (the naira) sit a pixel off the Latin baseline.
      if (tops[i] - tops[i - 1] > 6) lines++;
    }
    if (lines > 1) problems.add('wrapped: $plain');
  }
  expect(problems, isEmpty, reason: '$stage\n${problems.join('\n')}');
}

class _SeatLayoutPage extends StatelessWidget {
  const _SeatLayoutPage({required this.rows});

  final List<SeatMapRowView> rows;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlongPalette.of(context).bg,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SeatMap(
          body: 'cabin',
          rows: rows,
          footer: AlongSeatContext.sample,
        ),
      ),
    );
  }
}

List<SeatMapRowView> _sedanRows() {
  return const [
    SeatMapRowView(
      id: 'front',
      seats: [
        SeatMapSeat(
          id: 'fm',
          label: 'FM',
          role: 'passenger',
          status: 'yours',
          statusWord: 'Yours',
          price: '₦1,200',
        ),
        SeatMapSeat(
          id: 'fr',
          label: 'FR',
          role: 'passenger',
          status: 'held',
          statusWord: 'Held',
          price: '₦900',
        ),
        SeatMapSeat(
          id: 'drv',
          label: 'Driver',
          role: 'driver',
          status: 'occupied',
          statusWord: 'Driver',
        ),
      ],
    ),
    SeatMapRowView(
      id: 'back',
      seats: [
        SeatMapSeat(
          id: 'b1',
          label: 'BL',
          role: 'passenger',
          status: 'free',
          statusWord: 'Free',
          price: '₦700',
        ),
        SeatMapSeat(
          id: 'b2',
          label: 'ML',
          role: 'passenger',
          status: 'occupied',
          statusWord: 'Taken',
        ),
        SeatMapSeat(
          id: 'b3',
          label: 'MR',
          role: 'passenger',
          status: 'free',
          statusWord: 'Free',
          price: '₦700',
        ),
        SeatMapSeat(
          id: 'b4',
          label: 'BR',
          role: 'passenger',
          status: 'held',
          statusWord: 'Held',
          price: '₦800',
        ),
      ],
    ),
  ];
}

List<SeatMapRowView> _danfoRows() {
  SeatMapSeat seat(
    String id,
    String label,
    String status,
    String word, {
    String? price,
  }) {
    return SeatMapSeat(
      id: id,
      label: label,
      role: 'passenger',
      status: status,
      statusWord: word,
      price: price,
    );
  }

  return [
    SeatMapRowView(
      id: 'cab',
      seats: [
        const SeatMapSeat(
          id: 'drv',
          label: 'Driver',
          role: 'driver',
          status: 'occupied',
          statusWord: 'Driver',
        ),
        seat('c2', '2', 'held', 'Held', price: '₦500'),
      ],
    ),
    SeatMapRowView(
      id: 'r2',
      seats: [
        seat('2a', 'A', 'free', 'Free', price: '₦400'),
        seat('2b', 'B', 'yours', 'Yours', price: '₦400'),
        seat('2c', 'C', 'free', 'Free', price: '₦400'),
        seat('2d', 'D', 'occupied', 'Taken'),
      ],
    ),
    SeatMapRowView(
      id: 'r3',
      seats: [
        seat('3a', 'A', 'held', 'Held', price: '₦400'),
        seat('3b', 'B', 'free', 'Free', price: '₦400'),
        seat('3c', 'C', 'free', 'Free', price: '₦400'),
        seat('3d', 'D', 'free', 'Free', price: '₦400'),
      ],
    ),
    SeatMapRowView(
      id: 'r4',
      seats: [
        seat('4a', 'A', 'free', 'Free', price: '₦350'),
        seat('4b', 'B', 'occupied', 'Taken'),
        seat('4c', 'C', 'free', 'Free', price: '₦350'),
        seat('4d', 'D', 'held', 'Held', price: '₦350'),
      ],
    ),
  ];
}
