import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'delights.dart';
import 'demo_adapter.dart';
import 'driver_portrait.dart';
import 'vehicle_art.dart';

/// How the Abuja map is dressed.
enum AlongCityMapMode { browse, trip, online, routeHero, search, completed }

/// How sure the fix is. Approximate and stale are hollow and grey, and
/// they carry a word. Precise is a filled rider dot plus "You".
enum AlongFix { precise, approximate, stale, hidden }

/// Muted Abuja maps.
///
/// Tiles are pre-rendered at 3× from the vector styles in
/// `tool/map/style-light.json` and `style-dark.json` (land `#E6E7EA` /
/// `#16171A`, parks `#E4EEE4` / `#1A2620`, water `#D4E2EE` / `#1A2A36`,
/// white or `#C9CCD2` roads). They are drawn as baked, with no color matrix.
/// The daily planet stops at z15; neighborhood frames are the z16 slippy
/// grid, drawn by overzooming that z15 vector so building footprints stay
/// sharp. The corridor uses native zoom-12 tiles. Online demand is a hex
/// contour painted in map space, not a blurred heat tile.
class AlongCityMap extends StatelessWidget {
  const AlongCityMap({
    super.key,
    this.mode = AlongCityMapMode.browse,
    this.progress = 1,
    this.liveMarker = false,
    this.sheetInset = 0.46,
    this.bare = false,
    this.fix = AlongFix.precise,
    this.demoLabel = true,
  });

  final AlongCityMapMode mode;
  final double progress;

  /// Drops a rider dot on the corridor. Guardian and Safety use this.
  final bool liveMarker;

  /// Fraction of the map kept clear under a sheet, so a route can sit above it.
  final double sheetInset;

  /// Tiles only, plus the fix marker. Pickup and search use this so the
  /// decorative pins do not cover the place label.
  final bool bare;

  final AlongFix fix;

  /// Debug builds label simulated positions. Screens that already show a
  /// Demo mark pass false.
  final bool demoLabel;

  /// Sits about one tile south of Wuse Market, so the market stays in the
  /// strip above a full-screen sheet on both 360×800 and 320×640.
  static const neighborhoodCenter = LatLng(9.063022, 7.465938);
  static const corridorCenter = LatLng(9.0460, 7.5183);

  /// South of the busy cores so the GO button sits on quiet map.
  static const cityCenter = LatLng(9.012, 7.490);
  static const wuseMarket = LatLng(9.068555, 7.465938);
  static const nyanya = LatLng(9.023418, 7.570635);

  /// East-west street in the cached Wuse grid, south of the reservoir.
  /// Long enough that the drawn portion fills the band above the sheet.
  static const neighborhoodRoute = <LatLng>[
    LatLng(9.058278, 7.462292),
    LatLng(9.058278, 7.462871),
    LatLng(9.058278, 7.463450),
    LatLng(9.058278, 7.464030),
    LatLng(9.058278, 7.464609),
    LatLng(9.058278, 7.465189),
  ];

  /// Wuse Market to Nyanya, snapped to the white roads on the z12 tiles.
  /// The line bends with the highway instead of a single straight street.
  static const corridorRoute = <LatLng>[
    LatLng(9.068704, 7.465725),
    LatLng(9.051074, 7.461262),
    LatLng(9.048022, 7.463322),
    LatLng(9.045649, 7.478771),
    LatLng(9.048700, 7.483921),
    LatLng(9.051074, 7.505894),
    LatLng(9.041580, 7.522373),
    LatLng(9.040224, 7.538853),
    LatLng(9.042258, 7.544346),
    LatLng(9.034121, 7.558422),
    LatLng(9.036494, 7.570438),
    LatLng(9.026661, 7.575932),
  ];

  bool get _wide =>
      mode == AlongCityMapMode.routeHero ||
      mode == AlongCityMapMode.trip ||
      mode == AlongCityMapMode.completed;

  @override
  Widget build(BuildContext context) {
    return _HeldProgress(
      progress: progress,
      builder: (context, shown) => _frame(context, shown),
    );
  }

  Widget _frame(BuildContext context, double shown) {
    final palette = AlongPalette.of(context);
    final dark = palette.brightness == Brightness.dark;
    final drawn = AlongMotionPolicy.reduced(context)
        ? 1.0
        : shown.clamp(0.0, 1.0);
    final route = _wide ? corridorRoute : neighborhoodRoute;
    final showRoute =
        mode == AlongCityMapMode.trip ||
        mode == AlongCityMapMode.routeHero ||
        mode == AlongCityMapMode.completed;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trip = mode == AlongCityMapMode.trip;
        final completed = mode == AlongCityMapMode.completed;
        final city = mode == AlongCityMapMode.online;
        final fit = showRoute
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(route),
                padding: trip
                    ? EdgeInsets.fromLTRB(
                        28,
                        72,
                        28,
                        constraints.maxHeight * sheetInset + 36,
                      )
                    : completed
                    ? const EdgeInsets.fromLTRB(32, 28, 40, 64)
                    : const EdgeInsets.fromLTRB(36, 36, 36, 36),
                // z12 tiles scale down when the corridor needs a wider frame.
                minZoom: trip || completed ? 10 : 12,
                maxZoom: trip || completed ? 12 : 12.4,
              )
            : null;
        return FlutterMap(
          options: MapOptions(
            initialCenter: city
                ? cityCenter
                : _wide
                ? corridorCenter
                : neighborhoodCenter,
            initialZoom: city ? 11.15 : (_wide ? 12 : 16),
            initialCameraFit: fit,
            minZoom: city
                ? 11.15
                : _wide
                ? (trip || completed ? 10 : 12)
                : 16,
            maxZoom: city
                ? 11.15
                : _wide
                ? (trip || completed ? 12 : 12.4)
                : 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            backgroundColor: dark
                ? const Color(0xFF16171A)
                : const Color(0xFFE6E7EA),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'assets/map/tiles/${dark ? 'dark' : 'light'}/{z}_{x}_{y}.png',
              tileProvider: AssetTileProvider(),
              userAgentPackageName: 'app.along.design',
              tileDisplay: const TileDisplay.instantaneous(),
              retinaMode: false,
              minNativeZoom: 12,
              maxNativeZoom: 16,
              keepBuffer: 1,
              panBuffer: 0,
            ),
            if (mode == AlongCityMapMode.online)
              PolygonLayer(polygons: _demandHexes(palette.accent)),
            if (showRoute)
              Positioned.fill(
                child: _RouteOverlay(
                  route: route,
                  progress: drawn,
                  palette: palette,
                ),
              ),
            MarkerLayer(
              rotate: true,
              markers: _markers(context, palette, drawn),
            ),
            if (kDebugMode && demoLabel && !_positionCarriesDemo)
              const Positioned(top: 8, right: 8, child: AlongDemoMark()),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(child: _Attribution(palette: palette)),
            ),
            const Positioned.fill(child: AlongVignette()),
          ],
        );
      },
    );
  }

  /// A puck or a stale car already says Demo, so the corner chip stays off.
  bool get _positionCarriesDemo {
    if (bare) return fix != AlongFix.hidden;
    return mode == AlongCityMapMode.browse ||
        mode == AlongCityMapMode.online ||
        mode == AlongCityMapMode.search ||
        (mode == AlongCityMapMode.trip && fix == AlongFix.stale);
  }

  double _typeScale(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (scale < 1) return 1;
    if (scale > 2.5) return 2.5;
    return scale;
  }

  List<Marker> _markers(
    BuildContext context,
    AlongPalette palette,
    double drawn,
  ) {
    final markers = <Marker>[];
    if (bare) {
      if (fix != AlongFix.hidden) {
        markers.add(_puck(context, wuseMarket, palette));
      }
      return markers;
    }
    if (mode == AlongCityMapMode.routeHero ||
        mode == AlongCityMapMode.completed) {
      markers.add(_endpoint(context, wuseMarket, 'Wuse', true, palette));
      markers.add(_endpoint(context, nyanya, 'Nyanya', false, palette));
      if (liveMarker) {
        markers.add(
          _riderDot(context, _along(corridorRoute, 0.62).point, palette),
        );
      }
      return markers;
    }
    if (mode == AlongCityMapMode.trip) {
      markers.add(
        _endpoint(context, corridorRoute.first, 'Wuse', true, palette),
      );
      markers.add(
        _endpoint(context, corridorRoute.last, 'Nyanya', false, palette),
      );
      final at = _along(corridorRoute, drawn);
      markers.add(
        _vehicle(
          context,
          at.point,
          AlongVehicleKind.car,
          null,
          at.heading,
          palette,
          emphasized: true,
        ),
      );
      return markers;
    }
    if (mode == AlongCityMapMode.browse) {
      markers.add(_pin(context, wuseMarket, 'Wuse', false, palette));
      markers.add(
        _pin(context, const LatLng(9.06905, 7.46485), 'Park', true, palette),
      );
    }
    if (mode == AlongCityMapMode.search) {
      markers.add(_radar(wuseMarket, palette));
      markers.add(
        _driver(
          context,
          const LatLng(9.06902, 7.46662),
          '4 min',
          false,
          palette,
        ),
      );
      markers.add(
        _driver(
          context,
          const LatLng(9.06805, 7.46515),
          '6 min',
          true,
          palette,
        ),
      );
      markers.add(
        _driver(
          context,
          const LatLng(9.06928, 7.46470),
          '8 min',
          false,
          palette,
        ),
      );
    }
    if (mode == AlongCityMapMode.online) {
      markers.add(
        _vehicle(
          context,
          const LatLng(9.06842, 7.46505),
          AlongVehicleKind.keke,
          2,
          -0.4,
          palette,
        ),
      );
      markers.add(
        _vehicle(
          context,
          const LatLng(9.06878, 7.46670),
          AlongVehicleKind.danfo,
          6,
          0.8,
          palette,
        ),
      );
    } else if (mode == AlongCityMapMode.browse) {
      markers.add(
        _cluster(context, const LatLng(9.06848, 7.46515), 3, palette),
      );
      markers.add(
        _cluster(context, const LatLng(9.06922, 7.46585), 2, palette),
      );
    }
    if (mode == AlongCityMapMode.browse ||
        mode == AlongCityMapMode.online ||
        mode == AlongCityMapMode.search) {
      markers.add(_puck(context, const LatLng(9.06812, 7.46525), palette));
    }
    return markers;
  }

  Marker _endpoint(
    BuildContext context,
    LatLng at,
    String label,
    bool pickup,
    AlongPalette palette,
  ) {
    final roles = palette.roles;
    final color = pickup ? roles.pickup : roles.dropoff;
    final word = pickup ? 'Pickup' : 'Drop';
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 96 * s,
      height: 48 * s,
      alignment: Alignment.bottomCenter,
      child: AlongPinDrop(
        child: Semantics(
          label: '$word $label',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pickup ? AlongIcons.locate : AlongIcons.path,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.caption(palette).copyWith(
                          fontSize: 10,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: pickup ? 12 : 10,
                height: pickup ? 12 : 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: pickup ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: pickup ? null : BorderRadius.circular(2),
                  border: Border.all(color: palette.surface, width: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Marker _pin(
    BuildContext context,
    LatLng at,
    String label,
    bool park,
    AlongPalette palette,
  ) {
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 72 * s,
      height: 42 * s,
      alignment: Alignment.bottomCenter,
      child: AlongPinDrop(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: park ? palette.mapPark : palette.surface,
                shape: BoxShape.circle,
                border: Border.all(color: palette.ink, width: 2),
                boxShadow: AlongElevation.float(palette.ink),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette).copyWith(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _vehicle(
    BuildContext context,
    LatLng at,
    AlongVehicleKind kind,
    int? seats,
    double heading,
    AlongPalette palette, {
    bool emphasized = false,
  }) {
    final s = _typeScale(context);
    final stale = emphasized && fix == AlongFix.stale;
    final plate = (emphasized ? 58.0 : 52.0) * s;
    final width = stale ? math.max(plate, 156 * s) : plate;
    final height = stale ? plate + 44 * s : plate;
    return Marker(
      point: at,
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: plate,
            height: plate,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 8,
                  child: Container(
                    width: emphasized ? 28 : 22,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (emphasized)
                  Container(
                    width: plate,
                    height: plate,
                    decoration: BoxDecoration(
                      color: stale
                          ? palette.roles.stale.withValues(alpha: 0.18)
                          : palette.surface,
                      shape: BoxShape.circle,
                      border: stale
                          ? Border.all(color: palette.roles.stale, width: 2)
                          : null,
                      boxShadow: AlongElevation.float(palette.ink),
                    ),
                  ),
                AlongTopDownMark(
                  kind: kind,
                  heading: heading,
                  size: (emphasized ? 40 : 36) * (s > 1.15 ? s : 1),
                ),
                if (seats != null)
                  Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.accentInk, width: 1),
                      ),
                      child: Text(
                        '$seats',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.numeric(palette).copyWith(
                          fontSize: 11,
                          height: 1,
                          color: palette.accentInk,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (stale)
            _FixCaption(
              palette: palette,
              label: DemoAdapter.gps.ageLabel,
              demo: kDebugMode && demoLabel,
            ),
        ],
      ),
    );
  }

  Marker _riderDot(BuildContext context, LatLng at, AlongPalette palette) {
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 48 * s,
      height: 40 * s,
      alignment: Alignment.bottomCenter,
      child: Semantics(
        label: 'You',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'You',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette).copyWith(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: palette.roles.riderDot,
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _radar(LatLng at, AlongPalette palette) {
    return Marker(
      point: at,
      width: 96,
      height: 96,
      alignment: Alignment.center,
      child: _PulseRadar(palette: palette),
    );
  }

  Marker _driver(
    BuildContext context,
    LatLng at,
    String eta,
    bool rider,
    AlongPalette palette,
  ) {
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 74 * s,
      height: 58 * s,
      alignment: Alignment.bottomCenter,
      child: Column(
        children: [
          AlongDriverPortrait(
            size: 36,
            asset: rider
                ? AlongDriverPortrait.adaeze
                : AlongDriverPortrait.chinedu,
            verified: true,
          ),
          const SizedBox(height: 2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AlongElevation.float(palette.ink),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              child: Text(
                eta,
                maxLines: 1,
                softWrap: false,
                style: AlongType.caption(palette).copyWith(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _cluster(
    BuildContext context,
    LatLng at,
    int count,
    AlongPalette palette,
  ) {
    final s = _typeScale(context);
    return Marker(
      point: at,
      width: 36 * s,
      height: 36 * s,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: palette.ink, width: 1.5),
          boxShadow: AlongElevation.rest(palette.ink),
        ),
        child: Text(
          '$count',
          maxLines: 1,
          softWrap: false,
          style: AlongType.title(palette).copyWith(fontSize: 15, height: 1),
        ),
      ),
    );
  }

  Marker _puck(BuildContext context, LatLng at, AlongPalette palette) {
    final scale = _typeScale(context);
    final hollow = fix == AlongFix.approximate || fix == AlongFix.stale;
    final showDemo = kDebugMode && demoLabel;
    final word = switch (fix) {
      AlongFix.precise => 'You',
      AlongFix.approximate => 'Approx',
      AlongFix.stale => 'Stale',
      AlongFix.hidden => '',
    };
    final fill = hollow ? palette.roles.stale : palette.roles.riderDot;
    final caption = [
      if (showDemo) 'Demo',
      word,
      if (hollow) DemoAdapter.gps.ageLabel,
    ].join(' ');
    return Marker(
      point: at,
      width: (hollow ? 156 : 72) * scale,
      height: ((showDemo ? 16 : 0) + 16 + (hollow ? 16 : 0) + 20) * scale,
      alignment: Alignment.bottomCenter,
      child: Semantics(
        label: caption,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDemo) _SolidWord(palette: palette, text: 'Demo'),
            _SolidWord(palette: palette, text: word),
            if (hollow)
              _SolidWord(palette: palette, text: DemoAdapter.gps.ageLabel),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: hollow ? const Color(0x00000000) : fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hollow ? palette.roles.stale : palette.surface,
                  width: hollow ? 2 : 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidWord extends StatelessWidget {
  const _SolidWord({required this.palette, required this.text});

  final AlongPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            fontSize: 10,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

class _FixCaption extends StatelessWidget {
  const _FixCaption({
    required this.palette,
    required this.label,
    required this.demo,
  });

  final AlongPalette palette;
  final String label;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: demo ? 'Demo $label' : label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (demo) _SolidWord(palette: palette, text: 'Demo'),
          _SolidWord(palette: palette, text: label),
        ],
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.palette});

  final AlongPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '© OpenStreetMap',
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            fontSize: 10,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

class _PulseRadar extends StatefulWidget {
  const _PulseRadar({required this.palette});

  final AlongPalette palette;

  @override
  State<_PulseRadar> createState() => _PulseRadarState();
}

class _PulseRadarState extends State<_PulseRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulse.value = 0.42;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return CustomPaint(
          painter: _PulsePainter(
            t: _pulse.value,
            color: widget.palette.accent,
            ink: widget.palette.ink,
          ),
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.t, required this.color, required this.ink});

  final double t;
  final Color color;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 2;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = 18 + phase * (maxR - 18);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - phase) * 0.55),
      );
    }
    canvas.drawCircle(
      center,
      16,
      Paint()..color = color.withValues(alpha: 0.22),
    );
    canvas.drawCircle(center, 7, Paint()..color = ink);
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => oldDelegate.t != t;
}

class _HeldProgress extends StatefulWidget {
  const _HeldProgress({required this.progress, required this.builder});

  final double progress;
  final Widget Function(BuildContext context, double shown) builder;

  @override
  State<_HeldProgress> createState() => _HeldProgressState();
}

class _HeldProgressState extends State<_HeldProgress>
    with SingleTickerProviderStateMixin {
  late double _shown;
  late final AnimationController _move;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _shown = widget.progress;
    _move =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addListener(() {
          final t = Curves.easeInOut.transform(_move.value);
          setState(() => _shown = _from + (widget.progress - _from) * t);
        });
  }

  @override
  void didUpdateWidget(covariant _HeldProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress == widget.progress) return;
    if (!AlongMotionPolicy.play(context)) {
      _move.stop();
      setState(() => _shown = widget.progress);
      return;
    }
    _from = _shown;
    _move.forward(from: 0);
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _shown);
}

class _RoutePoint {
  const _RoutePoint(this.point, this.heading);

  final LatLng point;
  final double heading;
}

_RoutePoint _along(List<LatLng> route, double progress) {
  if (route.length < 2) {
    return _RoutePoint(route.first, 0);
  }
  final last = route.length - 1;
  final scaled = progress.clamp(0.0, 1.0) * last;
  final index = scaled.floor().clamp(0, last - 1);
  final t = scaled - index;
  final a = route[index];
  final b = route[index + 1];
  final point = LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
  final heading = math.atan2(
    b.longitude - a.longitude,
    b.latitude - a.latitude,
  );
  return _RoutePoint(point, heading);
}

/// Hex demand across Abuja. Intensity follows the districts, then feathers
/// out so the field is not a hard rectangle. The south edge stays quiet
/// so the GO button is not sitting on a hot core.
List<Polygon> _demandHexes(Color accent) {
  const radius = 1280.0;
  const mPerLat = 111320.0;
  const hotspots = <(double, double, double)>[
    (9.076, 7.458, 1),
    (9.062, 7.492, 0.62),
    (9.088, 7.498, 0.84),
    (9.070, 7.430, 0.5),
    (9.084, 7.418, 0.4),
    (9.058, 7.530, 0.34),
    (9.094, 7.470, 0.28),
  ];
  final mPerLon = mPerLat * math.cos(9.05 * math.pi / 180);
  final dx = radius * math.sqrt(3);
  final dy = radius * 1.5;
  const originLat = 9.072;
  const originLon = 7.470;
  final polygons = <Polygon>[];
  for (var r = -5; r <= 5; r++) {
    for (var q = -5; q <= 5; q++) {
      final x = dx * (q + r / 2);
      final y = dy * r;
      final lat = originLat + y / mPerLat;
      final lon = originLon + x / mPerLon;
      final dLat = (lat - originLat) * mPerLat;
      final dLon = (lon - originLon) * mPerLon;
      final fromCore = math.sqrt(dLat * dLat + dLon * dLon);
      final edgeT = ((fromCore - 900) / 7200).clamp(0.0, 1.0);
      final feather = 1 - edgeT * edgeT * (3 - 2 * edgeT);
      // Die north of the GO button so the control sits on quiet map.
      final south = ((lat - 9.042) / 0.018).clamp(0.0, 1.0);
      var demand = 0.0;
      for (final spot in hotspots) {
        final sLat = (lat - spot.$1) * mPerLat;
        final sLon = (lon - spot.$2) * mPerLon;
        final dist = math.sqrt(sLat * sLat + sLon * sLon);
        demand += spot.$3 * math.exp(-(dist * dist) / (2 * 2100 * 2100));
      }
      demand = (demand * _hexJitter(q, r)).clamp(0.0, 1.4);
      final alpha = feather * south * (0.04 + demand.clamp(0.0, 1.0) * 0.62);
      if (alpha < 0.05 || lat < 9.045) continue;
      final hot = demand > 0.85 && feather > 0.85;
      polygons.add(
        Polygon(
          points: _hexRing(LatLng(lat, lon), radius * 0.98, mPerLat, mPerLon),
          color: accent.withValues(alpha: alpha.clamp(0.0, 0.7)),
          borderColor: accent.withValues(alpha: hot ? 0.35 : 0),
          borderStrokeWidth: hot ? 1 : 0,
        ),
      );
    }
  }
  return polygons;
}

double _hexJitter(int q, int r) {
  final n = (q * 73856093) ^ (r * 19349663);
  return 0.72 + 0.28 * ((n & 0xFFFF) / 65535);
}

List<LatLng> _hexRing(
  LatLng center,
  double radius,
  double mPerLat,
  double mPerLon,
) {
  return [
    for (var i = 0; i < 6; i++)
      LatLng(
        center.latitude +
            radius * math.cos(math.pi / 6 + i * math.pi / 3) / mPerLat,
        center.longitude +
            radius * math.sin(math.pi / 6 + i * math.pi / 3) / mPerLon,
      ),
  ];
}

class _RouteOverlay extends StatefulWidget {
  const _RouteOverlay({
    required this.route,
    required this.progress,
    required this.palette,
  });

  final List<LatLng> route;
  final double progress;
  final AlongPalette palette;

  @override
  State<_RouteOverlay> createState() => _RouteOverlayState();
}

class _RouteOverlayState extends State<_RouteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AlongDurations.routeDraw,
    );
    // The traveled stroke is the selected route. A looping pulse is decoration.
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final pulse = AlongMotionPolicy.play(context) ? _pulse.value : 0.0;
          return CustomPaint(
            painter: _RoutePainter(
              camera: camera,
              route: widget.route,
              progress: widget.progress,
              palette: widget.palette,
              pulse: pulse,
            ),
          );
        },
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.camera,
    required this.route,
    required this.progress,
    required this.palette,
    this.pulse = 0,
  });

  final MapCamera camera;
  final List<LatLng> route;
  final double progress;
  final AlongPalette palette;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final roles = palette.roles;
    final casing = roles.routeCasing;
    final full = _smooth(_screen(route));
    final grey = roles.stale.withValues(alpha: 0.55);
    canvas.drawPath(full, _stroke(11, casing));
    canvas.drawPath(full, _stroke(6.5, grey));
    if (progress > 0.02) {
      final traveled = _smooth(_points());
      canvas.drawPath(traveled, _stroke(12, casing));
      canvas.drawPath(traveled, _stroke(7, roles.route));
      if (pulse > 0) {
        alongPaintRoutePulse(
          canvas,
          traveled,
          pulse,
          palette.ink.withValues(alpha: 0.55),
        );
      }
    }
  }

  List<Offset> _screen(List<LatLng> points) {
    return [for (final point in points) camera.latLngToScreenOffset(point)];
  }

  Paint _stroke(double width, Color color) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
  }

  List<Offset> _points() {
    final count = route.length;
    final last = ((count - 1) * progress).floor().clamp(0, count - 1);
    final points = <Offset>[
      for (var i = 0; i <= last; i++) camera.latLngToScreenOffset(route[i]),
    ];
    if (last < count - 1) {
      final start = route[last];
      final end = route[last + 1];
      final t = (count - 1) * progress - last;
      points.add(
        camera.latLngToScreenOffset(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * t,
            start.longitude + (end.longitude - start.longitude) * t,
          ),
        ),
      );
    }
    return points;
  }

  Path _smooth(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    if (points.length < 3) {
      if (points.length == 2) path.lineTo(points.last.dx, points.last.dy);
      return path;
    }
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}
