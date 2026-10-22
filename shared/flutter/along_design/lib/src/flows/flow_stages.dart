import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../components/seat_map.dart';
import '../elevation.dart';
import '../icons.dart';
import '../palette.dart';
import '../type.dart';
import 'city_map.dart';
import 'driver_portrait.dart';
import 'map_sketch.dart';
import 'spring_sheet.dart';
import 'vehicle_art.dart';

/// Premium flow frames for both apps. Copy is warm and plain. [jk-writing]
/// Layout groups with a 4pt scale and 48dp targets. [jk-layout] [jk-accessibility]

class AlongFlowOnboarding extends StatelessWidget {
  const AlongFlowOnboarding({super.key, this.legacyCopy = false});

  final bool legacyCopy;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Continue', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            'Along',
            style: AlongType.caption(palette).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text('Move around. Your way.', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text(
            legacyCopy
                ? 'Enter your number to continue'
                : 'We text a code to this number so the ride stays yours.',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 16),
          _Field(
            fill: palette.recessed,
            bordered: false,
            child: Row(
              children: [
                Text('+234', style: AlongType.title(palette)),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: palette.line.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: Text(
                    '801 234 5678',
                    style: AlongType.body(palette).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _FactRow(icon: AlongIcons.shield, label: 'Code by text'),
          const _FactRow(
            icon: AlongIcons.seat,
            label: 'The ride stays on this number',
          ),
          const _FactRow(
            icon: AlongIcons.wallet,
            label: 'No password to remember',
          ),
        ],
      ),
    );
  }
}

class AlongFlowHome extends StatelessWidget {
  const AlongFlowHome({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(child: AlongCityMap()),
          const Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.menu, tooltip: 'Menu'),
          ),
          const Positioned(
            top: 16,
            right: 16,
            child: AlongMapButton(icon: AlongIcons.locate, tooltip: 'Recenter'),
          ),
          const Positioned.fill(
            child: AlongSpringSheet(fraction: 0.58, child: _HomeSheetBody()),
          ),
        ],
      ),
    );
  }
}

class _HomeSheetBody extends StatelessWidget {
  const _HomeSheetBody();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text('Good evening, Adaeze', style: AlongType.title(palette)),
        const SizedBox(height: 8),
        _Field(
          fill: palette.recessed,
          bordered: false,
          child: Row(
            children: [
              Icon(AlongIcons.search, color: palette.ink, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Where to?', style: AlongType.heading(palette)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const _PlaceRow(
          icon: AlongIcons.locate,
          title: 'Home',
          detail: 'Wuse 2',
        ),
        const _PlaceRow(
          icon: AlongIcons.earnings,
          title: 'Work',
          detail: 'Central Area',
        ),
        const _SectionLabel('Recent'),
        const _PlaceRow(
          icon: AlongIcons.search,
          title: 'Nyanya',
          detail: 'Yesterday · ₦1,200',
        ),
        const _PlaceRow(
          icon: AlongIcons.search,
          title: 'Berger',
          detail: 'Tuesday · ₦800',
        ),
        const _SectionLabel('Seat radar'),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _RadarCard(
                kind: AlongVehicleKind.keke,
                title: 'Keke',
                detail: '2 seats · 4 min',
              ),
              SizedBox(width: 8),
              _RadarCard(
                kind: AlongVehicleKind.car,
                title: 'Along car',
                detail: '3 seats · 6 min',
              ),
              SizedBox(width: 8),
              _RadarCard(
                kind: AlongVehicleKind.danfo,
                title: 'Danfo',
                detail: '8 seats · 8 min',
              ),
            ],
          ),
        ),
        const _SectionLabel('Choose a ride'),
        SizedBox(
          height: 132,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _RideCard(
                kind: AlongVehicleKind.keke,
                title: 'Keke',
                eta: '4 min',
                fare: '₦400-600',
                selected: true,
              ),
              SizedBox(width: 8),
              _RideCard(
                kind: AlongVehicleKind.okada,
                title: 'Okada',
                eta: '3 min',
                fare: '₦300-500',
              ),
              SizedBox(width: 8),
              _RideCard(
                kind: AlongVehicleKind.car,
                title: 'Car',
                eta: '6 min',
                fare: '₦1,100-1,400',
              ),
              SizedBox(width: 8),
              _RideCard(
                kind: AlongVehicleKind.danfo,
                title: 'Danfo',
                eta: '8 min',
                fare: '₦200-350',
              ),
              SizedBox(width: 8),
              _RideCard(
                kind: AlongVehicleKind.bus,
                title: 'Bus',
                eta: '12 min',
                fare: '₦500-800',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _Promo(),
        const SizedBox(height: 16),
        const AlongButton(label: 'See rides', onPressed: _noop),
      ],
    );
  }
}

class AlongFlowSeats extends StatelessWidget {
  const AlongFlowSeats({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Hold this seat', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text('Choose a seat', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text('Hiace · ABC-123-XY', style: AlongType.bodyMuted(palette)),
          const SizedBox(height: 4),
          Text(
            '4.9 · Trust 86',
            style: AlongType.caption(palette).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 16),
          const SeatMap(
            body: 'cabin',
            rows: [
              SeatMapRowView(
                id: 'front',
                seats: [
                  SeatMapSeat(
                    id: 'd',
                    label: 'Driver',
                    role: 'driver',
                    status: 'occupied',
                    statusWord: 'Driver',
                  ),
                  SeatMapSeat(
                    id: 'a',
                    label: 'Front',
                    role: 'passenger',
                    status: 'yours',
                    statusWord: 'Yours',
                  ),
                ],
              ),
              SeatMapRowView(
                id: 'mid',
                ruleTitle: 'Window stays open',
                seats: [
                  SeatMapSeat(
                    id: 'b',
                    label: 'Left',
                    role: 'passenger',
                    status: 'held',
                    statusWord: 'Held',
                  ),
                  SeatMapSeat(
                    id: 'c',
                    label: 'Right',
                    role: 'passenger',
                    status: 'occupied',
                    statusWord: 'Taken',
                  ),
                ],
              ),
              SeatMapRowView(
                id: 'back',
                seats: [
                  SeatMapSeat(
                    id: 'e',
                    label: 'Back left',
                    role: 'passenger',
                    status: 'free',
                    statusWord: 'Free',
                  ),
                  SeatMapSeat(
                    id: 'f',
                    label: 'Back right',
                    role: 'passenger',
                    status: 'free',
                    statusWord: 'Free',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _Legend(),
        ],
      ),
    );
  }
}

class AlongFlowLive extends StatelessWidget {
  const AlongFlowLive({super.key, this.progress = 0.62});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlongPalette.of(context).mapLand,
      body: Stack(
        children: [
          Positioned.fill(
            child: AlongCityMap(
              mode: AlongCityMapMode.trip,
              progress: progress,
            ),
          ),
          const Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.shield, tooltip: 'Safety'),
          ),
          const Positioned.fill(
            child: AlongSpringSheet(fraction: 0.46, child: _LiveSheet()),
          ),
        ],
      ),
    );
  }
}

class _LiveSheet extends StatelessWidget {
  const _LiveSheet();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('6', style: AlongType.numeric(palette).copyWith(fontSize: 40)),
            const SizedBox(width: 8),
            Text('min away', style: AlongType.heading(palette)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: 0.62,
            minHeight: 6,
            backgroundColor: palette.recessed,
            color: palette.accent,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const AlongDriverPortrait(size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chinedu', style: AlongType.title(palette)),
                  Text(
                    '4.9 · Trust 86',
                    style: AlongType.caption(palette).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('Left seat', style: AlongType.caption(palette)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: palette.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ABC-123-XY',
                style: AlongType.caption(palette).copyWith(
                  color: palette.onInk,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        const Row(
          children: [
            _SafetyAction(icon: AlongIcons.share, label: 'Share'),
            _SafetyAction(icon: AlongIcons.sos, label: 'SOS', danger: true),
            _SafetyAction(icon: AlongIcons.shield, label: 'Guardian'),
          ],
        ),
      ],
    );
  }
}

class AlongFlowSos extends StatelessWidget {
  const AlongFlowSos({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(
        label: 'Hold to alert',
        variant: AlongButtonVariant.danger,
        onPressed: _noop,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Icon(AlongIcons.sos, color: palette.danger, size: 32),
          const SizedBox(height: 12),
          Text('We stay with you', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text(
            'Hold the button to alert the people you chose. Your location goes with the alert.',
            style: AlongType.body(palette),
          ),
          const SizedBox(height: 16),
          const _PlaceRow(
            icon: AlongIcons.shield,
            title: 'Adaeze',
            detail: 'Mum',
          ),
          const _PlaceRow(
            icon: AlongIcons.shield,
            title: 'Chidi',
            detail: 'Brother',
          ),
          const SizedBox(height: 8),
          Text('Location is included', style: AlongType.caption(palette)),
        ],
      ),
    );
  }
}

class AlongFlowGuardian extends StatelessWidget {
  const AlongFlowGuardian({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Save', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text('Guardian', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text(
            'A check-in on this ride, only when you ask for it.',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 12),
          const _RuleRow(label: 'Off the route', value: '400 m'),
          const _RuleRow(label: 'Still for', value: '3 min'),
          const _RuleRow(label: 'Check-in every', value: '15 min'),
          const _RuleRow(label: 'Safe word', value: 'Set'),
        ],
      ),
    );
  }
}

class AlongFlowPlate extends StatelessWidget {
  const AlongFlowPlate({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Continue', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text('Check the plate', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text(
            'Fit the plate in the frame. You can still ride if the camera stays off.',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1916),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.accent, width: 3),
                  ),
                  child: Text(
                    'ABC-123-XY',
                    style: AlongType.numeric(palette)
                        .copyWith(fontSize: 22, letterSpacing: 1.2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Plate matches',
            style: AlongType.title(palette).copyWith(color: palette.success),
          ),
        ],
      ),
    );
  }
}

class AlongFlowWallet extends StatelessWidget {
  const AlongFlowWallet({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Pay ₦1,200', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text('Pay Chinedu', style: AlongType.heading(palette)),
          const SizedBox(height: 4),
          Text(
            '₦1,200',
            style: AlongType.numeric(palette).copyWith(fontSize: 40),
          ),
          const SizedBox(height: 4),
          Text(
            'Amount locked to this trip',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 16),
          const _RuleRow(label: 'Base fare', value: '₦1,000'),
          const _RuleRow(label: 'Seat', value: '₦200'),
          const _RuleRow(label: 'Bank transfer', value: 'On'),
          const _RuleRow(label: 'Cash', value: 'Off'),
        ],
      ),
    );
  }
}

class AlongFlowDay extends StatelessWidget {
  const AlongFlowDay({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Save the day', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text('Build my day', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text('Abuja, morning run', style: AlongType.bodyMuted(palette)),
          const SizedBox(height: 16),
          const _Stop(time: '06:30', title: 'Wuse park', detail: 'Start'),
          const _Stop(time: '07:10', title: 'Berger', detail: 'Pickup'),
          const _Stop(time: '07:45', title: 'Nyanya', detail: 'Last stop'),
          const SizedBox(height: 8),
          const _RuleRow(label: 'Vehicle', value: 'Hiace'),
          const _RuleRow(label: 'Seats', value: '14'),
          const _RuleRow(label: 'Corridor', value: 'Nyanya'),
        ],
      ),
    );
  }
}

class AlongFlowOnline extends StatelessWidget {
  const AlongFlowOnline({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.online),
          ),
          const Positioned(
            top: 16,
            left: 16,
            child: _MapChip(label: 'Seat demand · Nyanya'),
          ),
          Positioned.fill(
            child: AlongSpringSheet(
              fraction: 0.46,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: palette.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('You are online', style: AlongType.heading(palette)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wuse park · 3 seats open',
                    style: AlongType.bodyMuted(palette),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₦18,400',
                    style: AlongType.numeric(palette).copyWith(fontSize: 40),
                  ),
                  Text(
                    'So far today · 6 trips',
                    style: AlongType.caption(palette),
                  ),
                  const Spacer(),
                  const AlongButton(
                    label: 'Go offline',
                    variant: AlongButtonVariant.secondary,
                    onPressed: _noop,
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

class AlongFlowOffer extends StatelessWidget {
  const AlongFlowOffer({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const Row(
        children: [
          Expanded(
            child: AlongButton(
              label: 'Decline',
              variant: AlongButtonVariant.secondary,
              onPressed: _noop,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: AlongButton(label: 'Accept', onPressed: _noop),
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              height: 188,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AlongCityMap(mode: AlongCityMapMode.routeHero),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: _MapChip(label: '4.2 km · 18 min'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'New ride',
                  style: AlongType.caption(
                    palette,
                  ).copyWith(fontWeight: FontWeight.w700, color: palette.ink),
                ),
              ),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.ink, width: 2),
                ),
                child: Text(
                  '12',
                  style: AlongType.numeric(palette).copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₦1,800',
            style: AlongType.numeric(palette).copyWith(fontSize: 40),
          ),
          const SizedBox(height: 8),
          const _Stop(time: '6 min', title: 'Wuse Market', detail: 'Pickup'),
          const _Stop(time: '4.2 km', title: 'Nyanya', detail: 'Dropoff'),
          const SizedBox(height: 8),
          const _RuleRow(label: 'Seats', value: '2'),
          const _RuleRow(label: 'Vehicle', value: 'Hiace'),
          const _RiderRow(),
          const _RuleRow(label: 'Trust', value: '86'),
        ],
      ),
    );
  }
}

class AlongFlowEarnings extends StatelessWidget {
  const AlongFlowEarnings({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Cash out', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text('Today', style: AlongType.caption(palette)),
          Text(
            '₦48,200',
            style: AlongType.numeric(palette).copyWith(fontSize: 40),
          ),
          Text('11 trips', style: AlongType.bodyMuted(palette)),
          const SizedBox(height: 16),
          const _WeekBars(),
          const SizedBox(height: 8),
          const _RuleRow(label: 'Nyanya', value: '₦1,800'),
          const _RuleRow(label: 'Wuse', value: '₦1,200'),
          const _RuleRow(label: 'Garki', value: '₦900'),
          const _RuleRow(label: 'Berger', value: '₦1,400'),
          const _RuleRow(label: 'Jabi', value: '₦1,600'),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.child, required this.bottom});

  final Widget child;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: child),
              const SizedBox(height: 12),
              bottom,
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.child, this.fill, this.bordered = true});

  final Widget child;
  final Color? fill;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: fill ?? palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: bordered ? Border.all(color: palette.line) : null,
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: AlongType.caption(palette)
            .copyWith(fontWeight: FontWeight.w700, color: palette.muted),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
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
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.recessed,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: palette.ink),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AlongType.body(palette))),
          Text(
            detail,
            style: AlongType.caption(palette)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AlongType.body(palette))),
        ],
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  const _RadarCard({
    required this.kind,
    required this.title,
    required this.detail,
  });

  final AlongVehicleKind kind;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: 168,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.recessed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AlongVehicleMark(kind: kind, width: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AlongType.title(palette).copyWith(fontSize: 15),
                ),
                Text(detail, style: AlongType.caption(palette)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({
    required this.kind,
    required this.title,
    required this.eta,
    required this.fare,
    this.selected = false,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final String fare;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: 132,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: selected
            ? palette.accent.withValues(alpha: 0.28)
            : palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? palette.accentInk
              : palette.line.withValues(alpha: 0.45),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlongVehicleMark(kind: kind, width: 64),
          const Spacer(),
          Text(title, style: AlongType.title(palette).copyWith(fontSize: 16)),
          Text(
            eta,
            style: AlongType.caption(palette)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          Text(
            fare,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 13, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _Promo extends StatelessWidget {
  const _Promo();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: palette.recessed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 72,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Evening along', style: AlongType.title(palette)),
                Text(
                  '₦200 off Wuse to Nyanya',
                  style: AlongType.caption(palette).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendItem(label: 'Free', status: 'free'),
        _LegendItem(label: 'Taken', status: 'occupied'),
        _LegendItem(label: 'Held', status: 'held'),
        _LegendItem(label: 'Yours', status: 'yours'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final color = switch (status) {
      'occupied' => palette.ink,
      'held' => palette.surface,
      'yours' => palette.accent,
      _ => palette.success.withValues(alpha: 0.2),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: status == 'held' ? palette.accent : palette.ink,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AlongType.caption(palette)),
      ],
    );
  }
}

class _SafetyAction extends StatelessWidget {
  const _SafetyAction({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Column(
        children: [
          Material(
            color: danger ? palette.danger : palette.recessed,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _noop,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  icon,
                  color: danger ? palette.dangerOn : palette.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AlongType.caption(palette)),
        ],
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(99),
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: Text(
        label,
        style: AlongType.caption(palette).copyWith(
          fontWeight: FontWeight.w700,
          color: palette.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _RiderRow extends StatelessWidget {
  const _RiderRow();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const AlongDriverPortrait(
            size: 40,
            asset: AlongDriverPortrait.adaeze,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Adaeze', style: AlongType.title(palette))),
          Text('Rider', style: AlongType.caption(palette)),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(child: Text(label, style: AlongType.body(palette))),
          Text(
            value,
            style: AlongType.title(palette)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.time, required this.title, required this.detail});

  final String time;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              time,
              style: AlongType.caption(palette).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
              border: Border.all(color: palette.accentInk),
            ),
          ),
          Expanded(child: Text(title, style: AlongType.body(palette))),
          Text(detail, style: AlongType.caption(palette)),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    const bars = <(String, double, bool)>[
      ('M', 28, false),
      ('Tu', 40, false),
      ('W', 32, false),
      ('Th', 64, true),
      ('F', 44, false),
      ('Sa', 24, false),
      ('Su', 18, false),
    ];
    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: bar.$2,
                      decoration: BoxDecoration(
                        color: bar.$3
                            ? palette.accent
                            : palette.ink.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(bar.$1, style: AlongType.caption(palette)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _noop() {}
