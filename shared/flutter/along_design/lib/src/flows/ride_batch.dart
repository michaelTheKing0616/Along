import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../type.dart';
import 'city_map.dart';
import 'delights.dart';
import 'driver_portrait.dart';
import 'map_sketch.dart';

/// Driver-defined cabin rules. The screen reads this. It does not invent them.
class AlongRideOptions {
  const AlongRideOptions({
    this.squeezeFree = false,
    this.seatHolds = 0,
    this.womenOnlyRows = const <int>[],
  });

  /// No extra rider on a seat.
  final bool squeezeFree;

  /// Seats the driver keeps empty. 0, 1, or 2.
  final int seatHolds;

  /// Cabin rows the driver marks women-only. Empty means none.
  final List<int> womenOnlyRows;

  AlongRideOptions copyWith({
    bool? squeezeFree,
    int? seatHolds,
    List<int>? womenOnlyRows,
  }) {
    return AlongRideOptions(
      squeezeFree: squeezeFree ?? this.squeezeFree,
      seatHolds: seatHolds ?? this.seatHolds,
      womenOnlyRows: womenOnlyRows ?? this.womenOnlyRows,
    );
  }
}

/// One stop on an along or danfo trip.
class AlongStop {
  const AlongStop({
    required this.name,
    required this.eta,
    this.detail,
    this.passed = false,
    this.current = false,
  });

  final String name;
  final String eta;
  final String? detail;
  final bool passed;
  final bool current;
}

/// A corridor and the stops a rider sees on it.
class AlongRouteTimeline {
  const AlongRouteTimeline({required this.name, required this.stops});

  final String name;
  final List<AlongStop> stops;

  static const samples = <AlongRouteTimeline>[
    AlongRouteTimeline(
      name: 'Along',
      stops: [
        AlongStop(name: 'Wuse Market', eta: '7:02', passed: true),
        AlongStop(name: 'Berger', eta: '7:18', passed: true),
        AlongStop(name: 'You', eta: 'Now', detail: 'After Berger', current: true),
        AlongStop(name: 'AYA', eta: '7:41'),
        AlongStop(name: 'Nyanya', eta: '7:55'),
      ],
    ),
    AlongRouteTimeline(
      name: 'Danfo',
      stops: [
        AlongStop(name: 'Berger', eta: '7:05', passed: true),
        AlongStop(name: 'AYA', eta: '7:22', passed: true),
        AlongStop(
          name: 'You',
          eta: 'Now',
          detail: 'On this danfo',
          current: true,
        ),
        AlongStop(name: 'Nyanya', eta: '7:48'),
      ],
    ),
  ];
}

/// One line in the closed-loop wallet.
class AlongCreditEntry {
  const AlongCreditEntry(this.label, this.when, this.amount);

  final String label;
  final String when;

  /// Positive adds credit. Negative is a fare.
  final int amount;

  static const sample = <AlongCreditEntry>[
    AlongCreditEntry('Top up', 'Today', 2000),
    AlongCreditEntry('Fare', 'Yesterday', -1200),
    AlongCreditEntry('Refund', 'Monday', 600),
  ];
}

/// One day in a driver settlement.
class AlongSettlement {
  const AlongSettlement(this.day, this.trips, this.amount, {this.pending = false});

  final String day;
  final String trips;
  final int amount;
  final bool pending;

  static const sample = <AlongSettlement>[
    AlongSettlement('Wed', '12 trips', 18400, pending: true),
    AlongSettlement('Tue', '9 trips', 11200),
    AlongSettlement('Mon', '11 trips', 9800),
    AlongSettlement('Sun', '8 trips', 8800),
  ];
}

/// Rest poses for the five ride motions, each with one line.
class AlongFlowMotions extends StatelessWidget {
  const AlongFlowMotions({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Motion',
      subtitle: 'Each one, at rest.',
      children: const [
        _MotionRow(kind: _MotionKind.sheet, title: 'Sheet', note: 'Springs into place.'),
        SizedBox(height: 12),
        _MotionRow(kind: _MotionKind.seat, title: 'Seat', note: 'Scales, then a tick.'),
        SizedBox(height: 12),
        _MotionRow(kind: _MotionKind.fare, title: 'Fare', note: 'Fare counts up.'),
        SizedBox(height: 12),
        _MotionRow(kind: _MotionKind.arrival, title: 'Arrival', note: 'Draws itself on.'),
        SizedBox(height: 12),
        _MotionRow(kind: _MotionKind.route, title: 'Route', note: 'Draws along the trip.'),
      ],
    );
  }
}

/// Book a later seat, or the weekday commute.
class AlongFlowSchedule extends StatefulWidget {
  const AlongFlowSchedule({super.key});

  @override
  State<AlongFlowSchedule> createState() => _AlongFlowScheduleState();
}

class _AlongFlowScheduleState extends State<AlongFlowSchedule> {
  static const _dates = [19, 20, 21, 22, 23, 24, 25];
  static const _days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const _names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _times = [
    ('7:10', 'Quiet'),
    ('7:40', 'Usual'),
    ('8:10', 'Later'),
  ];

  var _day = 3;
  var _time = 1;
  var _commute = true;

  bool _filled(int index) => _commute ? index < 5 : index == _day;

  void _pickDay(int index) {
    setState(() {
      _day = index;
      if (index >= 5) _commute = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final label = AlongType.label(palette).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.1,
    );
    return _Page(
      title: 'Later',
      subtitle: 'Wuse to Nyanya',
      children: [
        Text('Day', style: AlongType.title(palette)),
        const SizedBox(height: 12),
        _DayRow(
          days: _days,
          dates: _dates,
          filled: _filled,
          onPick: _pickDay,
        ),
        const SizedBox(height: 8),
        _SwitchRow(
          title: 'Every weekday',
          value: _commute,
          switchKey: const Key('commute_switch'),
          onChanged: (value) => setState(() => _commute = value),
        ),
        const SizedBox(height: 16),
        Text('Time', style: AlongType.title(palette)),
        const SizedBox(height: 12),
        for (var i = 0; i < _times.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ChoiceRow(
            title: _times[i].$1,
            detail: _times[i].$2,
            selected: i == _time,
            onTap: () => setState(() => _time = i),
          ),
        ],
        const SizedBox(height: 16),
        AlongButton(
          key: const Key('schedule_book'),
          label: _commute ? 'Book the commute' : 'Book ${_names[_day]}',
          onPressed: () {},
        ),
        const SizedBox(height: 4),
        Text(
          _commute ? 'Repeats Mon to Fri' : 'One seat, this week',
          maxLines: 1,
          softWrap: false,
          style: label.copyWith(color: palette.ink.withValues(alpha: 0.72)),
        ),
      ],
    );
  }
}

/// Stops, the rider's place, and an ETA on each stop.
class AlongFlowStops extends StatelessWidget {
  const AlongFlowStops({super.key, this.routes = AlongRouteTimeline.samples});

  final List<AlongRouteTimeline> routes;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      title: 'Stops',
      subtitle: 'Along and danfo',
      children: [
        for (var r = 0; r < routes.length; r++) ...[
          if (r > 0) const SizedBox(height: 20),
          Text(routes[r].name, style: AlongType.title(palette)),
          const SizedBox(height: 8),
          for (var i = 0; i < routes[r].stops.length; i++)
            _StopRow(
              stop: routes[r].stops[i],
              last: i == routes[r].stops.length - 1,
            ),
        ],
      ],
    );
  }
}

/// Squeeze-free, held seats, and women-only rows. All from [options].
class AlongFlowRideOptions extends StatefulWidget {
  const AlongFlowRideOptions({super.key, required this.options});

  final AlongRideOptions options;

  @override
  State<AlongFlowRideOptions> createState() => _AlongFlowRideOptionsState();
}

class _AlongFlowRideOptionsState extends State<AlongFlowRideOptions> {
  late AlongRideOptions _options;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
  }

  @override
  void didUpdateWidget(covariant AlongFlowRideOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) _options = widget.options;
  }

  void _toggleRow(int row) {
    final next = [..._options.womenOnlyRows];
    if (next.contains(row)) {
      next.remove(row);
    } else {
      next.add(row);
    }
    next.sort();
    setState(() => _options = _options.copyWith(womenOnlyRows: next));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final holds = _options.seatHolds.clamp(0, 2);
    return _Page(
      title: 'Ride options',
      subtitle: 'You set these',
      children: [
        _SwitchRow(
          title: 'Squeeze-free',
          detail: 'No shared seats',
          value: _options.squeezeFree,
          switchKey: const Key('squeeze_free'),
          onChanged: (value) => setState(
            () => _options = _options.copyWith(squeezeFree: value),
          ),
        ),
        const SizedBox(height: 8),
        Text('Seats held', style: AlongType.title(palette)),
        const SizedBox(height: 4),
        Text(
          'You keep these',
          maxLines: 1,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StepButton(
              key: const Key('seat_hold_less'),
              label: '−',
              enabled: holds > 0,
              onTap: () => setState(
                () => _options = _options.copyWith(seatHolds: holds - 1),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$holds',
              key: const Key('seat_holds'),
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1,
              ),
            ),
            const SizedBox(width: 12),
            _StepButton(
              key: const Key('seat_hold_more'),
              label: '+',
              enabled: holds < 2,
              onTap: () => setState(
                () => _options = _options.copyWith(seatHolds: holds + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Women-only', style: AlongType.title(palette)),
        const SizedBox(height: 4),
        Text(
          'Rows you reserve',
          maxLines: 1,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        const SizedBox(height: 8),
        for (var row = 1; row <= 3; row++) ...[
          if (row > 1) const SizedBox(height: 8),
          _ChoiceRow(
            key: Key('women_row_$row'),
            title: 'Row $row',
            selected: _options.womenOnlyRows.contains(row),
            marked: true,
            onTap: () => _toggleRow(row),
          ),
        ],
        const SizedBox(height: 16),
        const AlongButton(
          key: Key('save_options'),
          label: 'Save options',
          onPressed: _noop,
        ),
      ],
    );
  }
}

/// Closed-loop Along credit. Top up, then the recent lines.
class AlongFlowTopUp extends StatefulWidget {
  const AlongFlowTopUp({
    super.key,
    this.balance = 4200,
    this.choices = const [1000, 2000, 5000],
    this.selected = 2000,
    this.history = AlongCreditEntry.sample,
  });

  final int balance;
  final List<int> choices;
  final int selected;
  final List<AlongCreditEntry> history;

  @override
  State<AlongFlowTopUp> createState() => _AlongFlowTopUpState();
}

class _AlongFlowTopUpState extends State<AlongFlowTopUp> {
  late int _choice;

  @override
  void initState() {
    super.initState();
    _choice = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      title: 'Wallet',
      subtitle: 'Along credit',
      children: [
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance',
                maxLines: 1,
                softWrap: false,
                style: AlongType.label(palette),
              ),
              const SizedBox(height: 4),
              AlongMoney(value: widget.balance, style: AlongType.display(palette)),
              const SizedBox(height: 4),
              Text(
                'It stays in Along',
                maxLines: 1,
                softWrap: false,
                style: AlongType.bodyMuted(palette),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Add credit', style: AlongType.title(palette)),
        const SizedBox(height: 12),
        for (var i = 0; i < widget.choices.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ChoiceRow(
            key: Key('topup_${widget.choices[i]}'),
            title: _naira(widget.choices[i]),
            selected: widget.choices[i] == _choice,
            outlined: true,
            onTap: () => setState(() => _choice = widget.choices[i]),
          ),
        ],
        const SizedBox(height: 16),
        Text('History', style: AlongType.title(palette)),
        const SizedBox(height: 8),
        for (final entry in widget.history) _HistoryRow(entry: entry),
        const SizedBox(height: 16),
        AlongButton(
          key: const Key('topup_add'),
          label: 'Add ${_naira(_choice)}',
          onPressed: () {},
        ),
      ],
    );
  }
}

/// What the driver is owed, and what already settled.
class AlongFlowPayout extends StatelessWidget {
  const AlongFlowPayout({
    super.key,
    this.pending = 18400,
    this.paid = 29800,
    this.rows = AlongSettlement.sample,
  });

  final int pending;
  final int paid;
  final List<AlongSettlement> rows;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      title: 'Payout',
      subtitle: 'Your Along account',
      children: [
        Text(
          'This week',
          maxLines: 1,
          softWrap: false,
          style: AlongType.label(palette),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AlongMoney(
              value: pending + paid,
              style: AlongType.display(palette),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MoneyCard(name: 'Pending', amount: pending, open: true),
            ),
            const SizedBox(width: 12),
            Expanded(child: _MoneyCard(name: 'Paid', amount: paid)),
          ],
        ),
        const SizedBox(height: 16),
        for (final row in rows) _SettlementRow(row: row),
        const SizedBox(height: 16),
        AlongButton(
          key: const Key('payout_settle'),
          label: pending == 0 ? 'Nothing to settle' : 'Settle ${_naira(pending)}',
          onPressed: pending == 0 ? null : () {},
        ),
      ],
    );
  }
}

/// Home, with the network down. Saved places stay.
class AlongFlowOfflineHome extends StatelessWidget {
  const AlongFlowOfflineHome({super.key});

  @override
  Widget build(BuildContext context) {
    return _MapStage(
      map: const AlongCityMap(
        phase: AlongDayPhase.afternoon,
        bare: true,
        fix: AlongFix.hidden,
        demoLabel: false,
      ),
      topButtons: true,
      card: const _OfflineCard(
        title: 'Poor network',
        body: 'Saved places stay here',
        action: 'Try again',
        actionKey: Key('offline_home_retry'),
        extra: Column(
          children: [
            _PlaceLine(icon: AlongIcons.home, title: 'Home', detail: 'Garki'),
            _PlaceLine(
              icon: AlongIcons.work,
              title: 'Work',
              detail: 'Wuse Market',
            ),
          ],
        ),
      ),
    );
  }
}

/// Matching, paused because the network dropped.
class AlongFlowOfflineMatching extends StatelessWidget {
  const AlongFlowOfflineMatching({super.key});

  @override
  Widget build(BuildContext context) {
    return _MapStage(
      map: const AlongCityMap(
        center: AlongCityMap.wuseMarket,
        bare: true,
        demoLabel: false,
        fix: AlongFix.hidden,
        sheetInset: 0,
      ),
      card: const _OfflineCard(
        title: 'Search paused',
        body: 'The network dropped',
        detail: 'Wuse Market',
        action: 'Try again',
        actionKey: Key('offline_match_retry'),
      ),
    );
  }
}

/// A live trip that has not heard from the network.
class AlongFlowOfflineLive extends StatelessWidget {
  const AlongFlowOfflineLive({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _MapStage(
      map: const AlongCityMap(
        mode: AlongCityMapMode.trip,
        progress: 0.62,
        sheetInset: 0.36,
        demoLabel: false,
      ),
      card: _OfflineCard(
        title: 'Live trip',
        body: 'The trip stays here',
        action: 'Refresh',
        actionKey: const Key('offline_live_refresh'),
        leading: Row(
          children: [
            const AlongDriverPortrait(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chinedu',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.title(palette).copyWith(height: 1.1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last update 2 min ago',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.bodyMuted(palette),
                  ),
                ],
              ),
            ),
          ],
        ),
        extra: const _RouteLine(),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                maxLines: roomy ? 2 : 1,
                softWrap: roomy,
                style: AlongType.display(palette),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AlongType.bodyMuted(palette),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

enum _MotionKind { sheet, seat, fare, arrival, route }

class _MotionRow extends StatelessWidget {
  const _MotionRow({
    required this.kind,
    required this.title,
    required this.note,
  });

  final _MotionKind kind;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return Row(
      children: [
        _MotionTile(kind: kind),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: AlongType.title(palette).copyWith(height: 1.1),
              ),
              const SizedBox(height: 2),
              Text(
                note,
                maxLines: roomy ? 2 : 1,
                softWrap: roomy,
                style: AlongType.caption(palette).copyWith(
                  color: palette.ink.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 56px squircle. Radius 24 stays under half of 56, so the tile is not a disc.
class _MotionTile extends StatelessWidget {
  const _MotionTile({required this.kind});

  final _MotionKind kind;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: 56,
      height: 56,
      child: DecoratedBox(
        decoration: AlongCraft.fill(
          palette.surface,
          corner: AlongRadius.card.x,
          side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
        ),
        child: CustomPaint(
          painter: _MotionMarkPainter(kind: kind, color: palette.ink),
        ),
      ),
    );
  }
}

class _MotionMarkPainter extends CustomPainter {
  _MotionMarkPainter({required this.kind, required this.color});

  final _MotionKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    switch (kind) {
      case _MotionKind.sheet:
        _sheet(canvas, stroke);
      case _MotionKind.seat:
        _seat(canvas, stroke);
      case _MotionKind.fare:
        _fare(canvas, stroke);
      case _MotionKind.arrival:
        _arrival(canvas, stroke);
      case _MotionKind.route:
        _route(canvas, stroke);
    }
  }

  void _sheet(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(16, 42)
      ..lineTo(16, 26)
      ..quadraticBezierTo(16, 18, 24, 18)
      ..lineTo(32, 18)
      ..quadraticBezierTo(40, 18, 40, 26)
      ..lineTo(40, 42);
    canvas.drawPath(path, stroke);
    canvas.drawLine(const Offset(24, 24), const Offset(32, 24), stroke);
  }

  void _seat(Canvas canvas, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 14, 18, 14),
        const Radius.circular(5),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 30, 24, 12),
        const Radius.circular(4),
      ),
      stroke,
    );
  }

  void _fare(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(16, 36)
      ..lineTo(24, 28)
      ..lineTo(32, 31)
      ..lineTo(42, 18);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(const Offset(42, 18), 2.25, stroke);
  }

  void _arrival(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(18, 29)
      ..lineTo(25, 36)
      ..lineTo(40, 20);
    canvas.drawPath(path, stroke);
  }

  void _route(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(15, 38)
      ..cubicTo(24, 38, 28, 18, 40, 22);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(const Offset(15, 38), 2.25, stroke);
    canvas.drawCircle(const Offset(40, 22), 2.25, stroke);
  }

  @override
  bool shouldRepaint(covariant _MotionMarkPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.days,
    required this.dates,
    required this.filled,
    required this.onPick,
  });

  final List<String> days;
  final List<int> dates;
  final bool Function(int index) filled;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final raw = (constraints.maxWidth - gap * 6) / 7;
        final side = raw > 40 ? 40.0 : raw;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < days.length; i++)
              SizedBox(
                width: side,
                child: _DayCell(
                  label: days[i],
                  date: dates[i],
                  side: side,
                  filled: filled(i),
                  onTap: () => onPick(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.date,
    required this.side,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final int date;
  final double side;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final day = AlongType.label(palette).copyWith(height: 1);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: side,
            height: roomy ? null : 40,
            child: DecoratedBox(
              decoration: AlongCraft.fill(
                filled ? palette.ink : const Color(0x00000000),
                corner: side >= 36 ? AlongRadius.control.x : AlongRadius.xs.x,
                side: filled
                    ? BorderSide.none
                    : BorderSide(color: palette.ink, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$date',
                  maxLines: 1,
                  softWrap: false,
                  style: day.copyWith(
                    color: filled ? palette.onInk : palette.ink,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: day,
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.switchKey,
    required this.onChanged,
    this.detail,
  });

  final String title;
  final String? detail;
  final bool value;
  final Key switchKey;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.body(palette).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.bodyMuted(palette),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            height: 48,
            child: FittedBox(
              child: Switch(
                key: switchKey,
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.detail,
    this.marked = false,
    this.outlined = false,
  });

  final String title;
  final String? detail;
  final bool selected;
  final bool marked;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final inkFill = selected && !marked && !outlined;
    final color = inkFill ? palette.onInk : palette.ink;
    final showMark = selected && (marked || outlined);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: DecoratedBox(
          decoration: AlongCraft.fill(
            inkFill ? palette.ink : palette.surface,
            corner: AlongRadius.row.x,
            side: outlined && selected
                ? BorderSide(color: palette.ink, width: 2)
                : marked && selected
                ? BorderSide(color: palette.ink, width: 1.5)
                : marked
                ? BorderSide(color: palette.ink.withValues(alpha: 0.14))
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.body(palette).copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.label(palette).copyWith(color: color),
                  ),
                if (showMark) ...[
                  const SizedBox(width: 8),
                  Icon(AlongIcons.check, size: 24, color: palette.ink),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: AlongCraft.fill(
              palette.recessed,
              corner: AlongRadius.control.x,
            ),
            child: Center(
              child: FittedBox(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette).copyWith(height: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop, required this.last});

  final AlongStop stop;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final here = stop.current;
    final name = AlongType.body(palette).copyWith(
      fontWeight: here ? FontWeight.w600 : FontWeight.w400,
      height: 1.2,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(stop: stop, last: last),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: last ? 2 : 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          maxLines: 1,
                          softWrap: false,
                          style: name,
                        ),
                        if (stop.detail != null)
                          Text(
                            stop.detail!,
                            maxLines: 1,
                            softWrap: false,
                            style: AlongType.bodyMuted(palette),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    stop.eta,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.label(palette).copyWith(
                      fontWeight: here ? FontWeight.w600 : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.stop, required this.last});

  final AlongStop stop;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final strong = stop.passed || stop.current;
    final color = strong ? palette.ink : palette.ink.withValues(alpha: 0.36);
    final dot = stop.current ? 12.0 : 8.0;
    return SizedBox(
      width: 16,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: strong ? color : const Color(0x00000000),
              shape: BoxShape.circle,
              border: strong ? null : Border.all(color: color, width: 1.5),
            ),
          ),
          if (!last)
            Expanded(
              child: Container(
                width: 2,
                color: palette.ink.withValues(alpha: 0.24),
              ),
            ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(palette, radius: AlongRadius.card.x),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: child,
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final AlongCreditEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.body(palette).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                Text(
                  entry.when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AlongType.bodyMuted(palette),
                ),
              ],
            ),
          ),
          AlongMoney(
            value: entry.amount,
            style: AlongType.body(palette).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.name,
    required this.amount,
    this.open = false,
  });

  final String name;
  final int amount;

  /// Pending is the open settlement. Paid is the quieter dot.
  final bool open;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: AlongCraft.fill(
        palette.surface,
        corner: AlongRadius.card.x,
        side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: open
                      ? palette.ink
                      : palette.ink.withValues(alpha: 0.36),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AlongType.label(palette),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AlongMoney(value: amount, style: AlongType.title(palette)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.row});

  final AlongSettlement row;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final status = row.pending ? 'Pending' : 'Paid';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row.day} · ${row.trips}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AlongType.body(palette).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AlongType.label(palette).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: AlongMoney(
                value: row.amount,
                style: AlongType.body(palette).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStage extends StatelessWidget {
  const _MapStage({
    required this.map,
    required this.card,
    this.alignTop = false,
    this.topButtons = false,
  });

  final Widget map;
  final Widget card;
  final bool alignTop;
  final bool topButtons;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          Positioned.fill(child: map),
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Color(0x33000000)),
            ),
          ),
          const Positioned(
            top: 32,
            left: 16,
            right: 16,
            child: _OfflineBanner(),
          ),
          if (topButtons) ...[
            const Positioned(
              top: 80,
              left: 16,
              child: AlongMapButton(icon: AlongIcons.menu, tooltip: 'Menu'),
            ),
            const Positioned(
              top: 80,
              right: 16,
              child: AlongMapButton(
                icon: AlongIcons.locate,
                tooltip: 'Recenter',
              ),
            ),
          ],
          Positioned(
            left: 12,
            right: 12,
            top: alignTop ? 12 : null,
            bottom: alignTop ? null : 12,
            child: card,
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.fill(
        palette.surface,
        corner: AlongRadius.control.x,
        side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          'Offline · last updated 40s',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
          style: AlongType.label(palette).copyWith(
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  const _OfflineCard({
    required this.title,
    required this.body,
    required this.action,
    required this.actionKey,
    this.detail,
    this.leading,
    this.extra,
  });

  final String title;
  final String body;
  final String action;
  final Key actionKey;
  final String? detail;
  final Widget? leading;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(
        palette,
        radius: AlongRadius.card.x,
        shadow: AlongElevation.sheet(palette.ink),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(height: 12),
            ],
            Text(
              title,
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette).copyWith(height: 1.1),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                maxLines: 1,
                softWrap: false,
                style: AlongType.bodyMuted(palette),
              ),
            ],
            if (extra != null) ...[
              const SizedBox(height: 12),
              extra!,
            ],
            const SizedBox(height: 8),
            Text(
              body,
              maxLines: 1,
              softWrap: false,
              style: AlongType.bodyMuted(palette),
            ),
            const SizedBox(height: 12),
            AlongButton(key: actionKey, label: action, onPressed: _noop),
          ],
        ),
      ),
    );
  }
}

class _PlaceLine extends StatelessWidget {
  const _PlaceLine({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          AlongIcon(icon, size: 20, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: AlongType.body(palette).copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: AlongType.bodyMuted(palette),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final style = AlongType.body(palette).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    return Row(
      children: [
        Flexible(
          child: Text(
            'Wuse Market',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: style,
          ),
        ),
        const SizedBox(width: 8),
        AlongIcon(AlongIcons.arrowRight, size: 20, color: palette.ink),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Nyanya',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: style,
          ),
        ),
      ],
    );
  }
}

String _naira(int value) {
  final raw = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '−₦' : '₦');
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
    buf.write(raw[i]);
  }
  return buf.toString();
}

void _noop() {}
