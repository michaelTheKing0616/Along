import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
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
        AlongStop(
          name: 'You',
          eta: 'Now',
          detail: 'After Berger',
          current: true,
        ),
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
  const AlongSettlement(
    this.day,
    this.trips,
    this.amount, {
    this.pending = false,
  });

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
        _MotionRow(
          kind: _MotionKind.sheet,
          title: 'Sheet',
          note: 'Springs into place.',
        ),
        SizedBox(height: 12),
        _MotionRow(
          kind: _MotionKind.seat,
          title: 'Seat',
          note: 'Scales, then a tick.',
        ),
        SizedBox(height: 12),
        _MotionRow(
          kind: _MotionKind.fare,
          title: 'Fare',
          note: 'Fare counts up.',
        ),
        SizedBox(height: 12),
        _MotionRow(
          kind: _MotionKind.arrival,
          title: 'Arrival',
          note: 'Draws itself on.',
        ),
        SizedBox(height: 12),
        _MotionRow(
          kind: _MotionKind.route,
          title: 'Route',
          note: 'Draws along the trip.',
        ),
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
    final quiet = AlongType.caption(palette)
        .copyWith(color: palette.ink.withValues(alpha: 0.72));
    final picked = _times[_time];
    return _Page(
      title: 'Later',
      subtitle: 'Wuse to Nyanya',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _commute ? 'Repeats Mon to Fri' : 'One seat, this week',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: quiet,
          ),
          const SizedBox(height: 8),
          AlongButton(
            key: const Key('schedule_book'),
            label: _commute ? 'Book the commute' : 'Book ${_names[_day]}',
            onPressed: () {},
          ),
        ],
      ),
      children: [
        _RouteHero(time: picked.$1, note: picked.$2),
        const SizedBox(height: 20),
        Text('Day', style: AlongType.title(palette)),
        const SizedBox(height: 12),
        _DayRow(days: _days, dates: _dates, filled: _filled, onPick: _pickDay),
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
            accentEdge: true,
            onTap: () => setState(() => _time = i),
          ),
        ],
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
      footer: const AlongButton(
        key: Key('stops_share'),
        label: 'Share the trip',
        onPressed: _noop,
      ),
      children: [
        const _TripStrip(),
        const SizedBox(height: 20),
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
  /// Six passenger seats: two beside the driver, then four in back.
  static const _seatOrder = [
    'front_a',
    'front_b',
    'back_a',
    'back_b',
    'back_c',
    'back_d',
  ];

  late AlongRideOptions _options;
  late List<String> _held;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _held = _seed(widget.options.seatHolds);
  }

  @override
  void didUpdateWidget(covariant AlongFlowRideOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _options = widget.options;
      _held = _seed(widget.options.seatHolds);
    }
  }

  List<String> _seed(int holds) => _seatOrder.take(holds.clamp(0, 2)).toList();

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

  void _toggleHold(String id) {
    setState(() {
      if (_held.contains(id)) {
        _held.remove(id);
      } else if (_held.length < 2) {
        _held.add(id);
      }
      _options = _options.copyWith(seatHolds: _held.length);
    });
  }

  _CabinSeatData _passenger(String id) {
    return _CabinSeatData(
      id: id,
      held: _held.contains(id),
      holdKey: _holdKey(id),
    );
  }

  Key? _holdKey(String id) {
    String? more;
    for (final seat in _seatOrder) {
      if (!_held.contains(seat)) {
        more = seat;
        break;
      }
    }
    if (more == id) return const Key('seat_hold_more');
    if (_held.isNotEmpty && _held.last == id) {
      return const Key('seat_hold_less');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      title: 'Ride options',
      subtitle: 'You set these',
      footer: const AlongButton(
        key: Key('save_options'),
        label: 'Save options',
        onPressed: _noop,
      ),
      children: [
        _SwitchRow(
          title: 'Squeeze-free',
          detail: 'No shared seats',
          value: _options.squeezeFree,
          switchKey: const Key('squeeze_free'),
          onChanged: (value) =>
              setState(() => _options = _options.copyWith(squeezeFree: value)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Cabin', style: AlongType.title(palette))),
            Text(
              '${_held.length}',
              key: const Key('seat_holds'),
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette).copyWith(height: 1),
            ),
            const SizedBox(width: 6),
            Text('held', maxLines: 1, softWrap: false, style: _quiet(palette)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a row for women-only',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        Text(
          'Tap a seat to hold it',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: AlongType.bodyMuted(palette),
        ),
        const SizedBox(height: 12),
        _CabinDiagram(
          onSeat: _toggleHold,
          rows: [
            _CabinBandData(
              rowKey: const Key('women_row_1'),
              women: _options.womenOnlyRows.contains(1),
              onRow: () => _toggleRow(1),
              seats: [
                const _CabinSeatData(id: 'driver', driver: true),
                _passenger('front_a'),
                _passenger('front_b'),
              ],
            ),
            _CabinBandData(
              rowKey: const Key('women_row_2'),
              women: _options.womenOnlyRows.contains(2),
              onRow: () => _toggleRow(2),
              seats: [_passenger('back_a'), _passenger('back_b')],
            ),
            _CabinBandData(
              rowKey: const Key('women_row_3'),
              women: _options.womenOnlyRows.contains(3),
              onRow: () => _toggleRow(3),
              seats: [_passenger('back_c'), _passenger('back_d')],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _CabinLegend(),
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
      gutter: 16,
      footer: AlongButton(
        key: const Key('topup_add'),
        label: 'Add ${_naira(_choice)}',
        onPressed: () {},
      ),
      children: [
        _BalanceHero(balance: widget.balance),
        const SizedBox(height: 20),
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
    return _Page(
      title: 'Payout',
      subtitle: 'Your Along account',
      gutter: 16,
      footer: AlongButton(
        key: const Key('payout_settle'),
        label: pending == 0 ? 'Nothing to settle' : 'Settle ${_naira(pending)}',
        onPressed: pending == 0 ? null : () {},
      ),
      children: [
        _EarningsHero(pending: pending, paid: paid),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MoneyCard(name: 'Pending', amount: pending, open: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MoneyCard(name: 'Paid', amount: paid),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final row in rows) _SettlementRow(row: row),
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

/// Home again, while the network is coming back. The ring is the status.
class AlongFlowOfflineReconnecting extends StatelessWidget {
  const AlongFlowOfflineReconnecting({super.key});

  @override
  Widget build(BuildContext context) {
    return _MapStage(
      reconnecting: true,
      map: const AlongCityMap(
        phase: AlongDayPhase.afternoon,
        bare: true,
        fix: AlongFix.hidden,
        demoLabel: false,
      ),
      topButtons: true,
      card: const _OfflineCard(
        title: 'Reconnecting',
        body: 'Looking for the network…',
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

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.gutter = 24,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;

  /// Screen inset. Wallet and payout use 16 so amounts share the button margin.
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 16),
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
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: footer,
              ),
          ],
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
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w600, height: 1.2),
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
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return palette.accentInk;
                  }
                  return palette.surface;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return palette.accent;
                  }
                  return palette.ink.withValues(alpha: 0.18);
                }),
                trackOutlineColor: WidgetStateProperty.all(
                  const Color(0x00000000),
                ),
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
    this.outlined = false,
    this.accentEdge = false,
  });

  final String title;
  final String? detail;
  final bool selected;
  final bool outlined;
  final bool accentEdge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final inkFill = selected && !outlined && !accentEdge;
    final color = inkFill ? palette.onInk : palette.ink;
    final showMark = selected && outlined;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: DecoratedBox(
          decoration: AlongCraft.fill(
            inkFill ? palette.ink : palette.surface,
            corner: AlongRadius.row.x,
            side: accentEdge && selected
                ? BorderSide(color: palette.accent, width: 2)
                : outlined && selected
                ? BorderSide(color: palette.ink, width: 2)
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
    final traveled = stop.passed;
    return SizedBox(
      width: 24,
      child: Column(
        children: [
          const SizedBox(height: 2),
          _StopDot(stop: stop),
          if (!last)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: traveled
                        ? palette.ink
                        : palette.ink.withValues(alpha: 0.28),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StopDot extends StatelessWidget {
  const _StopDot({required this.stop});

  final AlongStop stop;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final passed = stop.passed;
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: stop.current
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.accent,
                    ),
                  ),
                ],
              )
            : Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passed ? palette.ink : const Color(0x00000000),
                  border: passed
                      ? null
                      : Border.all(
                          color: palette.ink.withValues(alpha: 0.36),
                          width: 1.5,
                        ),
                ),
              ),
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
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w600, height: 1.2),
                ),
                Text(
                  entry.when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: _quiet(palette),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _LedgerAmount(value: entry.amount, signed: true),
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
                  style: _quiet(palette),
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
                  style: AlongType.body(palette)
                      .copyWith(fontWeight: FontWeight.w600, height: 1.2),
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: _quiet(palette),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _LedgerAmount(value: row.amount),
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
    this.reconnecting = false,
  });

  final Widget map;
  final Widget card;
  final bool alignTop;
  final bool topButtons;
  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_quietMap),
              child: map,
            ),
          ),
          Positioned(
            top: 36,
            left: 12,
            right: 12,
            child: _OfflineBanner(reconnecting: reconnecting),
          ),
          if (topButtons) ...[
            const Positioned(
              top: 96,
              left: 16,
              child: AlongMapButton(icon: AlongIcons.menu, tooltip: 'Menu'),
            ),
            const Positioned(
              top: 96,
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

/// Keeps land, water, and parks, with the colour pulled back. Not a grey wash.
/// Saturation 0.72. Colour stays; it is only pulled back.
const _quietMap = <double>[
  0.780,
  0.200,
  0.020,
  0,
  0,
  0.060,
  0.920,
  0.020,
  0,
  0,
  0.060,
  0.200,
  0.740,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.reconnecting = false});

  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final label = AlongType.label(palette)
        .copyWith(fontWeight: FontWeight.w600, height: 1.1);
    final bar = DecoratedBox(
      decoration: AlongCraft.fill(
        palette.surface,
        corner: AlongRadius.control.x,
        side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _StatusMark(spin: reconnecting, color: palette.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reconnecting ? 'Reconnecting' : 'Offline · last updated 40s',
                maxLines: roomy ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                softWrap: roomy,
                style: label,
              ),
            ),
            if (!reconnecting) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _noop,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'Retry',
                  maxLines: 1,
                  softWrap: false,
                  style: label,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (roomy) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: bar,
      );
    }
    return SizedBox(height: 48, child: bar);
  }
}

class _StatusMark extends StatefulWidget {
  const _StatusMark({required this.spin, required this.color});

  final bool spin;
  final Color color;

  @override
  State<_StatusMark> createState() => _StatusMarkState();
}

class _StatusMarkState extends State<_StatusMark>
    with SingleTickerProviderStateMixin {
  AnimationController? _turn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final play = widget.spin && AlongMotionPolicy.play(context);
    if (play && _turn == null) {
      _turn = AnimationController(vsync: this, duration: AlongDurations.scan)
        ..repeat();
    } else if (!play) {
      _turn?.stop();
    }
  }

  @override
  void dispose() {
    _turn?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.spin) {
      return SizedBox(
        width: 16,
        height: 16,
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ),
      );
    }
    final ring = CustomPaint(
      size: const Size.square(16),
      painter: _RingPainter(color: widget.color),
    );
    final turn = _turn;
    if (turn == null) return ring;
    return RotationTransition(turns: turn, child: ring);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..color = color;
    final arc = (Offset.zero & size).deflate(1.2);
    canvas.drawArc(arc, -1.2, 4.4, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _OfflineCard extends StatelessWidget {
  const _OfflineCard({
    required this.title,
    required this.body,
    this.action,
    this.actionKey,
    this.detail,
    this.leading,
    this.extra,
  });

  final String title;
  final String body;
  final String? action;
  final Key? actionKey;
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
            if (leading != null) ...[leading!, const SizedBox(height: 12)],
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
            if (extra != null) ...[const SizedBox(height: 12), extra!],
            const SizedBox(height: 8),
            Text(
              body,
              maxLines: 1,
              softWrap: false,
              style: AlongType.bodyMuted(palette),
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AlongButton(
                  key: actionKey,
                  label: action!,
                  onPressed: _noop,
                ),
              ),
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
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.2),
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
    final style = AlongType.body(palette)
        .copyWith(fontWeight: FontWeight.w600, height: 1.2);
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

TextStyle _quiet(AlongPalette palette) {
  return AlongType.caption(palette)
      .copyWith(color: palette.ink.withValues(alpha: 0.72));
}

/// One text run so the sign and the naira do not paint as "+₦₦".
class _LedgerAmount extends StatelessWidget {
  const _LedgerAmount({required this.value, this.signed = false});

  final int value;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final text = signed && value > 0 ? '+${_naira(value)}' : _naira(value);
    return Text(
      text,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.right,
      style: AlongType.body(palette).copyWith(
        fontWeight: FontWeight.w600,
        height: 1,
        fontFeatures: AlongType.figures,
      ),
    );
  }
}

class _RouteHero extends StatelessWidget {
  const _RouteHero({required this.time, required this.note});

  final String time;
  final String note;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomyRoute = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return AlongCraft.clip(
      corner: AlongRadius.card.x,
      child: DecoratedBox(
        decoration: AlongCraft.fill(
          palette.surface,
          corner: AlongRadius.card.x,
          side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CorridorPainter(palette: palette),
                    ),
                  ),
                  const Positioned(
                    left: 10,
                    bottom: 10,
                    child: _MapTag('Wuse'),
                  ),
                  const Positioned(
                    right: 10,
                    top: 10,
                    child: _MapTag('Nyanya'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next departure',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: _quiet(palette),
                  ),
                  Row(
                    children: [
                      Text(
                        time,
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.title(palette).copyWith(height: 1.1),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: AlongType.label(
                            palette,
                          ).copyWith(fontWeight: FontWeight.w600, height: 1.1),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Wuse Market → Nyanya',
                    maxLines: roomyRoute ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: roomyRoute,
                    style: AlongType.body(palette)
                        .copyWith(fontWeight: FontWeight.w600, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTag extends StatelessWidget {
  const _MapTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.fill(palette.surface, corner: AlongRadius.xs.x),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette)
              .copyWith(fontWeight: FontWeight.w600, height: 1.1),
        ),
      ),
    );
  }
}

class _CorridorPainter extends CustomPainter {
  const _CorridorPainter({required this.palette});

  final AlongPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.mapLand);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.34),
        width: size.width * 0.24,
        height: size.height * 0.34,
      ),
      Paint()..color = palette.mapPark,
    );
    final water = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.5,
        size.width * 0.3,
        size.height,
      )
      ..lineTo(0, size.height);
    canvas.drawPath(water, Paint()..color = palette.mapWater);
    final start = Offset(size.width * 0.12, size.height * 0.64);
    final end = Offset(size.width * 0.86, size.height * 0.36);
    final spine = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.6,
        size.width * 0.52,
        size.height * 0.4,
        end.dx,
        end.dy,
      );
    canvas.drawPath(
      spine,
      Paint()
        ..color = palette.mapRoad
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(size.width * 0.46, size.height * 0.16),
      Offset(size.width * 0.54, size.height * 0.86),
      Paint()
        ..color = palette.mapRoad
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      spine,
      Paint()
        ..color = palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(start, 5, Paint()..color = palette.ink);
    canvas.drawCircle(end, 5, Paint()..color = palette.surface);
    canvas.drawCircle(
      end,
      5,
      Paint()
        ..color = palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CorridorPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _TripStrip extends StatelessWidget {
  const _TripStrip();

  @override
  Widget build(BuildContext context) {
    return AlongCraft.clip(
      corner: AlongRadius.card.x,
      child: const SizedBox(
        height: 168,
        child: AlongCityMap(
          mode: AlongCityMapMode.trip,
          progress: 0.55,
          zoom: 12,
          center: AlongCityMap.corridorCenter,
          demoLabel: false,
          sheetInset: 0,
        ),
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AlongCraft.clip(
      corner: AlongRadius.card.x,
      child: DecoratedBox(
        decoration: AlongCraft.fill(
          palette.surface,
          corner: AlongRadius.card.x,
          side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: ColoredBox(color: palette.accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance',
                    maxLines: 1,
                    softWrap: false,
                    style: _quiet(palette),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AlongMoney(
                      value: balance,
                      style: AlongType.display(palette),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'It stays in Along',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: AlongType.bodyMuted(palette),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsHero extends StatelessWidget {
  const _EarningsHero({required this.pending, required this.paid});

  final int pending;
  final int paid;

  static const _goal = 60000;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final total = pending + paid;
    final progress = (total / _goal).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    return DecoratedBox(
      decoration: AlongCraft.fill(
        palette.surface,
        corner: AlongRadius.card.x,
        side: BorderSide(color: palette.ink.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _GoalRing(progress: progress),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This week',
                        maxLines: 1,
                        softWrap: false,
                        style: _quiet(palette),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AlongMoney(
                          value: total,
                          style: AlongType.title(palette),
                        ),
                      ),
                      Text(
                        'Goal ${_naira(_goal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: _quiet(palette),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$pct% of weekly goal',
              maxLines: 1,
              softWrap: false,
              style: AlongType.label(palette),
            ),
            const SizedBox(height: 14),
            const _WeekBars(),
          ],
        ),
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: 88,
      height: 88,
      child: CustomPaint(
        painter: _GoalPainter(
          progress: progress,
          track: palette.ink.withValues(alpha: 0.16),
          ink: palette.ink,
        ),
        child: Center(
          child: Text(
            '${(progress * 100).round()}%',
            maxLines: 1,
            softWrap: false,
            style: AlongType.title(palette).copyWith(height: 1),
          ),
        ),
      ),
    );
  }
}

class _GoalPainter extends CustomPainter {
  const _GoalPainter({
    required this.progress,
    required this.track,
    required this.ink,
  });

  final double progress;
  final Color track;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final arc = (Offset.zero & size).deflate(3);
    canvas.drawArc(arc, 0, math.pi * 2, false, stroke..color = track);
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      stroke..color = ink,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ink != ink;
}

class _WeekBars extends StatelessWidget {
  const _WeekBars();

  static const _days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  static const _amounts = [8800, 9800, 11200, 18400, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final peak = _amounts.reduce(math.max).toDouble();
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _days.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: _amounts[i] == 0
                              ? 12
                              : 12 + 36 * (_amounts[i] / peak),
                          child: DecoratedBox(
                            decoration: AlongCraft.fill(
                              i == 3
                                  ? palette.ink
                                  : palette.ink.withValues(
                                      alpha: _amounts[i] == 0 ? 0.16 : 0.45,
                                    ),
                              corner: AlongRadius.xs.x,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final day in _days)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    day,
                    maxLines: 1,
                    softWrap: false,
                    style: _quiet(palette),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CabinSeatData {
  const _CabinSeatData({
    required this.id,
    this.driver = false,
    this.held = false,
    this.holdKey,
  });

  final String id;
  final bool driver;
  final bool held;
  final Key? holdKey;
}

class _CabinBandData {
  const _CabinBandData({
    required this.rowKey,
    required this.women,
    required this.onRow,
    required this.seats,
  });

  final Key rowKey;
  final bool women;
  final VoidCallback onRow;
  final List<_CabinSeatData> seats;
}

/// One chassis. Front is the driver plus two passengers. Back is four seats.
class _CabinDiagram extends StatelessWidget {
  const _CabinDiagram({required this.rows, required this.onSeat});

  final List<_CabinBandData> rows;
  final ValueChanged<String> onSeat;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return CustomPaint(
      painter: _HullPainter(palette: palette),
      foregroundPainter: _GlassPainter(palette: palette),
      child: ClipPath(
        clipper: const _HullClipper(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _CabinBand(data: rows[i], onSeat: onSeat),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CabinBand extends StatelessWidget {
  const _CabinBand({required this.data, required this.onSeat});

  final _CabinBandData data;
  final ValueChanged<String> onSeat;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return GestureDetector(
      onTap: data.onRow,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: data.women ? palette.accent.withValues(alpha: 0.22) : null,
          border: data.women
              ? Border(
                  top: BorderSide(color: palette.accent, width: 2),
                  bottom: BorderSide(color: palette.accent, width: 2),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < data.seats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _OptionSeat(data: data.seats[i], onTap: onSeat),
                  ],
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  key: data.rowKey,
                  onTap: data.onRow,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 24,
                    child: data.women
                        ? MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(textScaler: TextScaler.noScaling),
                            child: Icon(
                              AlongIcons.check,
                              size: 16,
                              color: palette.ink,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSeat extends StatelessWidget {
  const _OptionSeat({required this.data, required this.onTap});

  final _CabinSeatData data;
  final ValueChanged<String> onTap;

  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    final kind = data.driver
        ? 'driver'
        : data.held
        ? 'held'
        : 'open';
    return GestureDetector(
      key: data.holdKey,
      onTap: data.driver ? null : () => onTap(data.id),
      behavior: HitTestBehavior.opaque,
      child: _TopSeat(kind: kind, size: size),
    );
  }
}

/// Rounded backrest bar and a cushion. Same proportions at every size.
class _TopSeat extends StatelessWidget {
  const _TopSeat({required this.kind, this.size = 44});

  /// `open`, `held`, or `driver`.
  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = AlongPalette.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TopSeatPainter(
          kind: kind,
          ink: const Color(0xFF141210),
          paper: dark ? const Color(0xFFF3EEE8) : const Color(0xFFFFFFFF),
          line: dark ? const Color(0xFFE4DCD2) : const Color(0xFF141210),
        ),
      ),
    );
  }
}

class _TopSeatPainter extends CustomPainter {
  const _TopSeatPainter({
    required this.kind,
    required this.ink,
    required this.paper,
    required this.line,
  });

  final String kind;
  final Color ink;
  final Color paper;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final held = kind == 'held';
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = held ? paper : line;
    final fill = Paint()..color = held ? ink.withValues(alpha: 0.92) : paper;
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.08,
        size.width * 0.76,
        size.height * 0.22,
      ),
      Radius.circular(size.height * 0.11),
    );
    final pan = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.06,
        size.height * 0.38,
        size.width * 0.88,
        size.height * 0.52,
      ),
      Radius.circular(size.width * 0.16),
    );
    canvas.drawRRect(back, fill);
    canvas.drawRRect(back, stroke);
    canvas.drawRRect(pan, fill);
    canvas.drawRRect(pan, stroke);
    final hub = Offset(size.width * 0.50, size.height * 0.64);
    if (kind == 'driver') {
      canvas.drawCircle(hub, size.width * 0.13, stroke);
      canvas.drawCircle(hub, size.width * 0.035, Paint()..color = line);
    }
    if (held) _lock(canvas, size);
  }

  void _lock(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = paper;
    final w = size.width * 0.28;
    final h = size.height * 0.32;
    final left = (size.width - w) / 2;
    final top = size.height * 0.50;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top + h * 0.38, w, h * 0.56),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(body, stroke);
    final shackle = Path()
      ..moveTo(left + w * 0.22, top + h * 0.46)
      ..lineTo(left + w * 0.22, top + h * 0.32)
      ..quadraticBezierTo(left + w * 0.22, top, left + w * 0.50, top)
      ..quadraticBezierTo(left + w * 0.78, top, left + w * 0.78, top + h * 0.32)
      ..lineTo(left + w * 0.78, top + h * 0.46);
    canvas.drawPath(shackle, stroke);
  }

  @override
  bool shouldRepaint(covariant _TopSeatPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.ink != ink ||
      oldDelegate.paper != paper ||
      oldDelegate.line != line;
}

const _mirrorBand = 16.0;

Rect _hullRect(Size size) {
  return Rect.fromLTWH(
    _mirrorBand,
    2,
    size.width - _mirrorBand * 2,
    size.height - 4,
  );
}

Path _hullPath(Size size) {
  final rect = _hullRect(size);
  final corner = math.min(40.0, rect.shortestSide * 0.22);
  return AlongCraft.path(rect, corner);
}

class _HullPainter extends CustomPainter {
  const _HullPainter({required this.palette});

  final AlongPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = palette.brightness == Brightness.dark;
    final fill = Paint()
      ..color = dark ? const Color(0xFF2A2824) : const Color(0xFFF4F1EB);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = dark ? const Color(0xFFE4DCD2) : const Color(0xFF141210);
    final hull = _hullRect(size);
    final mirror = Rect.fromLTWH(2, hull.top + hull.height * 0.16, 22, 16);
    final mirrors = [
      mirror,
      Rect.fromLTWH(size.width - 24, mirror.top, 22, 16),
    ];
    for (final rect in mirrors) {
      canvas.drawPath(AlongCraft.path(rect, 4), fill);
    }
    final body = _hullPath(size);
    canvas.drawPath(body, fill);
    for (final rect in mirrors) {
      canvas.drawPath(AlongCraft.path(rect, 4), stroke);
    }
    canvas.drawPath(body, stroke);
  }

  @override
  bool shouldRepaint(covariant _HullPainter oldDelegate) =>
      oldDelegate.palette.brightness != palette.brightness;
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter({required this.palette});

  final AlongPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = palette.brightness == Brightness.dark;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..color = (dark ? const Color(0xFFE4DCD2) : const Color(0xFF141210))
          .withValues(alpha: 0.45);
    final hull = _hullRect(size);
    final glass = Path()
      ..moveTo(hull.left + hull.width * 0.24, hull.top + 26)
      ..quadraticBezierTo(
        hull.center.dx,
        hull.top + 16,
        hull.right - hull.width * 0.24,
        hull.top + 26,
      );
    final rear = Path()
      ..moveTo(hull.left + hull.width * 0.28, hull.bottom - 22)
      ..quadraticBezierTo(
        hull.center.dx,
        hull.bottom - 14,
        hull.right - hull.width * 0.28,
        hull.bottom - 22,
      );
    canvas.drawPath(glass, stroke);
    canvas.drawPath(rear, stroke);
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) =>
      oldDelegate.palette.brightness != palette.brightness;
}

class _HullClipper extends CustomClipper<Path> {
  const _HullClipper();

  @override
  Path getClip(Size size) => _hullPath(size);

  @override
  bool shouldReclip(covariant _HullClipper oldClipper) => false;
}

class _CabinLegend extends StatelessWidget {
  const _CabinLegend();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LegendGlyph(
            label: 'Open',
            child: _TopSeat(kind: 'open', size: 22),
          ),
          const SizedBox(width: 12),
          const _LegendGlyph(
            label: 'Held',
            child: _TopSeat(kind: 'held', size: 22),
          ),
          const SizedBox(width: 12),
          _LegendGlyph(
            label: 'Women-only',
            child: DecoratedBox(
              decoration: AlongCraft.fill(
                palette.accent.withValues(alpha: 0.22),
                corner: AlongRadius.xs.x,
                side: BorderSide(color: palette.accent, width: 1.5),
              ),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: _TopSeat(kind: 'open', size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const _LegendGlyph(
            label: 'Driver',
            child: _TopSeat(kind: 'driver', size: 22),
          ),
        ],
      ),
    );
  }
}

class _LegendGlyph extends StatelessWidget {
  const _LegendGlyph({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette),
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
