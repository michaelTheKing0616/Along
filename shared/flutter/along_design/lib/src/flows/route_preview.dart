import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../craft.dart';
import '../elevation.dart';
import '../palette.dart';
import '../type.dart';

/// A drawn street grid with an optional pickup-to-drop route.
///
/// Needs no tiles or network, so it renders the same in every host app
/// and in goldens. Use it where a live map is not worth the cost, such as
/// the trip options header, or as a stand-in while the map loads.
///
/// With [pickup] and [drop] (x = longitude, y = latitude) the markers keep
/// the real bearing between the two places, fitted into the clear band
/// between [topInset] and the summary tag. Name tags are measured and
/// placed on whichever side of their marker avoids the route, the other
/// marker, the other tag and the summary.
class AlongRoutePreview extends StatelessWidget {
  const AlongRoutePreview({
    super.key,
    this.route = true,
    this.semanticLabel,
    this.from,
    this.to,
    this.summary,
    this.pickup,
    this.drop,
    this.topInset = 88,
    this.bottomInset = 0,
  });

  /// Draws the route, pickup dot and drop pin. False leaves only streets.
  final bool route;
  final String? semanticLabel;

  /// Name tags beside the pickup and drop markers.
  final String? from;
  final String? to;

  /// Time and distance, shown as a tag in the lower right.
  final String? summary;

  /// Real coordinates as Offset(lng, lat). Null uses a default bearing.
  final Offset? pickup;
  final Offset? drop;

  /// Height covered by buttons on top, kept clear of markers and tags.
  final double topInset;

  /// Height hidden under an overlapping sheet, kept clear of tags.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style = _Tag.styleFor(palette);
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: LayoutBuilder(
        builder: (context, box) {
          final layout = RouteLayout.compute(
            size: Size(box.maxWidth, box.maxHeight),
            topInset: topInset,
            bottomInset: bottomInset,
            pickup: pickup,
            drop: drop,
            fromSize: from == null ? null : _Tag.measure(from!, style, scaler),
            toSize: to == null ? null : _Tag.measure(to!, style, scaler),
            summarySize: summary == null
                ? null
                : _Tag.measure(summary!, style, scaler, legend: false),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StreetsPainter(
                    palette,
                    AlongRoles.of(palette),
                    route ? layout : null,
                  ),
                ),
              ),
              if (route && layout.fromRect != null)
                Positioned.fromRect(
                  rect: layout.fromRect!,
                  child: _Tag(
                    text: from!,
                    palette: palette,
                    legend: _Legend.pickup,
                  ),
                ),
              if (route && layout.toRect != null)
                Positioned.fromRect(
                  rect: layout.toRect!,
                  child: _Tag(
                    text: to!,
                    palette: palette,
                    legend: _Legend.drop,
                  ),
                ),
              if (layout.summaryRect != null)
                Positioned.fromRect(
                  rect: layout.summaryRect!,
                  child: _Tag(text: summary!, palette: palette, strong: true),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Where the markers, route and tags go. Pure, so it is unit-testable.
@immutable
class RouteLayout {
  const RouteLayout({
    required this.a,
    required this.b,
    required this.path,
    this.fromRect,
    this.toRect,
    this.summaryRect,
  });

  final Offset a;
  final Offset b;
  final List<Offset> path;
  final Rect? fromRect;
  final Rect? toRect;
  final Rect? summaryRect;

  static const double _edge = 12;
  static const double _marker = 12;
  static const double _gap = 6;

  static RouteLayout compute({
    required Size size,
    double topInset = 88,
    double bottomInset = 0,
    Offset? pickup,
    Offset? drop,
    Size? fromSize,
    Size? toSize,
    Size? summarySize,
  }) {
    final w = size.width, h = size.height;
    final visible = h - bottomInset;
    final summaryRect = summarySize == null
        ? null
        : Rect.fromLTWH(
            w - 16 - summarySize.width,
            visible - 12 - summarySize.height,
            summarySize.width,
            summarySize.height,
          );
    // Band the route may use: below the buttons, above the summary row.
    final floor = (summaryRect?.top ?? visible - 12) - 18;
    final top = topInset + 20;
    final band = Rect.fromLTRB(
      w * 0.18,
      top,
      w * 0.82,
      floor < top + 48 ? top + 48 : floor,
    );

    var d = const Offset(1, 0.75); // default bearing: north-east
    if (pickup != null && drop != null) {
      final lat = (pickup.dy + drop.dy) / 2 * math.pi / 180;
      final dx = (drop.dx - pickup.dx) * math.cos(lat);
      final dy = drop.dy - pickup.dy;
      if (dx.abs() + dy.abs() > 1e-9) d = Offset(dx, dy);
    }
    // Screen y grows down; latitude grows up.
    final v = Offset(d.dx, -d.dy);
    final sx = v.dx.abs() < 1e-9 ? double.infinity : band.width / v.dx.abs();
    final sy = v.dy.abs() < 1e-9 ? double.infinity : band.height / v.dy.abs();
    final k = math.min(sx, sy);
    final c = band.center;
    final a = c - v * (k / 2);
    final b = c + v * (k / 2);
    // Streets run square, so the route bends once each way.
    final turnY = a.dy + (b.dy - a.dy) * 0.55;
    final path = [a, Offset(a.dx, turnY), Offset(b.dx, turnY), b];

    final bounds = Rect.fromLTRB(_edge, topInset + 4, w - _edge, visible - 8);
    final obstacles = <Rect>[
      for (var i = 0; i + 1 < path.length; i++)
        Rect.fromPoints(path[i], path[i + 1]).inflate(6),
      Rect.fromCircle(center: a, radius: _marker + 2),
      Rect.fromCircle(center: b, radius: _marker + 2),
      ?summaryRect?.inflate(6),
    ];
    Rect? place(Offset m, Size? s) {
      if (s == null) return null;
      final r = _marker + _gap;
      final options = [
        Offset(m.dx + r, m.dy - s.height / 2), // right
        Offset(m.dx - r - s.width, m.dy - s.height / 2), // left
        Offset(m.dx - s.width / 2, m.dy - r - s.height), // above
        Offset(m.dx - s.width / 2, m.dy + r), // below
        // Corner-anchored, for markers near an edge of the band.
        Offset(m.dx - 14, m.dy - r - s.height), // above, extending right
        Offset(m.dx + 14 - s.width, m.dy - r - s.height), // above, left
        Offset(m.dx - 14, m.dy + r), // below, extending right
        Offset(m.dx + 14 - s.width, m.dy + r), // below, left
      ];
      Rect? best;
      var bestScore = double.infinity;
      for (var i = 0; i < options.length; i++) {
        final rect = options[i] & s;
        var score = i * 0.5; // mild preference for the earlier sides
        final inside = rect.intersect(bounds);
        final outside =
            rect.width * rect.height -
            (inside.width > 0 && inside.height > 0
                ? inside.width * inside.height
                : 0);
        score += outside * 10;
        for (final o in obstacles) {
          final x = rect.intersect(o);
          if (x.width > 0 && x.height > 0) score += x.width * x.height;
        }
        if (score < bestScore) {
          bestScore = score;
          best = rect;
        }
      }
      if (best != null) obstacles.add(best.inflate(4));
      return best;
    }

    final toRect = place(b, toSize);
    final fromRect = place(a, fromSize);
    return RouteLayout(
      a: a,
      b: b,
      path: path,
      fromRect: fromRect,
      toRect: toRect,
      summaryRect: summaryRect,
    );
  }
}

enum _Legend { pickup, drop }

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.palette,
    this.strong = false,
    this.legend,
  });

  final String text;
  final AlongPalette palette;
  final bool strong;
  final _Legend? legend;

  static const double _maxWidth = 150;
  static const EdgeInsets _pad = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 7,
  );
  static const double _legendSpace = 14;

  static TextStyle styleFor(AlongPalette palette) =>
      AlongType.caption(palette)
          .copyWith(fontWeight: FontWeight.w600, height: 1.2);

  static Size measure(
    String text,
    TextStyle style,
    TextScaler scaler, {
    bool legend = true,
  }) {
    final extra = _pad.horizontal + (legend ? _legendSpace : 0);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: _maxWidth - extra);
    final size = Size(
      (tp.width + extra).ceilToDouble(),
      math.max(32, tp.height + _pad.vertical).ceilToDouble(),
    );
    tp.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final roles = AlongRoles.of(palette);
    final dark = palette.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: AlongCraft.compactFill(
        strong ? palette.ink : palette.surface,
        32,
        // A light-ink shadow halos on the dark map; tone carries lift there.
        shadow: dark ? const <BoxShadow>[] : AlongElevation.rest(palette.ink),
      ),
      child: Padding(
        padding: _pad,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The tag repeats its marker's shape, so the pair reads as one.
            if (legend == _Legend.pickup)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: roles.pickup,
                  shape: BoxShape.circle,
                ),
              ),
            if (legend == _Legend.drop)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: roles.dropoff,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
            if (legend != null) const SizedBox(width: _legendSpace - 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styleFor(palette)
                    .copyWith(color: strong ? palette.onInk : palette.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  _StreetsPainter(this.p, this.r, this.layout);

  final AlongPalette p;
  final AlongRoles r;
  final RouteLayout? layout;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Offset.zero & s, Paint()..color = p.mapLand);
    // Park and water blocks, placed in fractions so any size reads well.
    final rr = Radius.circular(w * 0.04);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .62, h * .08, w * .3, h * .2),
        rr,
      ),
      Paint()..color = p.mapPark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .06, h * .6, w * .22, h * .3),
        rr,
      ),
      Paint()..color = p.mapPark,
    );
    final water = Path()
      ..moveTo(0, h * .34)
      ..cubicTo(w * .2, h * .3, w * .3, h * .46, w * .52, h * .44)
      ..lineTo(w * .52, h * .5)
      ..cubicTo(w * .3, h * .52, w * .2, h * .37, 0, h * .41)
      ..close();
    canvas.drawPath(water, Paint()..color = p.mapWater);

    final dark =
        ThemeData.estimateBrightnessForColor(p.mapLand) == Brightness.dark;
    // Dark roads are pale; dim them so the route stays the brightest line.
    final road = dark ? p.mapRoad.withValues(alpha: 0.35) : p.mapRoad;
    final minor = Paint()
      ..color = road
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final x in [.14, .38, .86]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * (x + .06), h), minor);
    }
    for (final y in [.16, .56, .8]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * (y - .04)), minor);
    }
    final major = Paint()
      ..color = road
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * .7), Offset(w, h * .22), major);
    canvas.drawLine(Offset(w * .56, 0), Offset(w * .6, h), major);

    final route = layout;
    if (route == null) return;
    final a = route.a, b = route.b;
    final path = Path()..moveTo(a.dx, a.dy);
    for (final pt in route.path.skip(1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = r.routeCasing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = r.route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(a, 9, Paint()..color = p.surface);
    canvas.drawCircle(a, 6, Paint()..color = r.pickup);
    // Drop: a squared marker, so it reads apart from the round pickup.
    final drop = RRect.fromRectAndRadius(
      Rect.fromCenter(center: b, width: 18, height: 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(drop.inflate(3), Paint()..color = p.surface);
    canvas.drawRRect(drop, Paint()..color = r.dropoff);
  }

  @override
  bool shouldRepaint(_StreetsPainter old) => old.p != p || old.layout != layout;
}
