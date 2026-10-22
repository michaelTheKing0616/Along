import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../components/along_button.dart';
import '../components/skeleton.dart';
import '../components/seat_map.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
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
          Text('Move around.', style: AlongType.display(palette)),
          Text('Your way.', style: AlongType.display(palette)),
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
          const SizedBox(height: 20),
          const _FleetCard(),
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
            child: AlongSpringSheet(fraction: 0.72, child: _HomeSheetBody()),
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
        Text('Good evening, Adaeze', style: AlongType.heading(palette)),
        const SizedBox(height: 8),
        _Field(
          fill: palette.recessed,
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
        const SizedBox(height: 12),
        const _QuickActions(),
        const SizedBox(height: 12),
        const _PromoCarousel(),
        const _SectionLabel('Seat radar'),
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _RadarCard(
                kind: AlongVehicleKind.keke,
                title: 'Keke',
                detail: '2 left · 4 min',
                fare: '₦400',
              ),
              SizedBox(width: 8),
              _RadarCard(
                kind: AlongVehicleKind.car,
                title: 'Car',
                detail: '3 left · 6 min',
                fare: '₦1,100',
              ),
              SizedBox(width: 8),
              _RadarCard(
                kind: AlongVehicleKind.danfo,
                title: 'Danfo',
                detail: '8 left · 8 min',
                fare: '₦200',
              ),
            ],
          ),
        ),
        const _SectionLabel('Nearby rides'),
        const _RideRow(
          kind: AlongVehicleKind.keke,
          title: 'Keke',
          eta: '4 min',
          seats: '2 left',
          fare: '₦400-600',
          chips: ['Window open'],
          selected: true,
        ),
        const _RideRow(
          kind: AlongVehicleKind.car,
          title: 'Car',
          eta: '6 min',
          seats: '3 left',
          fare: '₦1,100',
          chips: ['AC', 'Trust 86'],
        ),
        const SizedBox(height: 8),
        const _PlaceRow(
          icon: AlongIcons.schedule,
          title: 'Nyanya',
          detail: 'Yesterday · ₦1,200',
        ),
        const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          const _MapHero(height: 168, label: 'Wuse to Nyanya · 18 min'),
          const SizedBox(height: 12),
          const _PersonCard(
            name: 'Chinedu',
            detail: 'Hiace · ABC-123-XY',
            trailing: '₦1,200',
          ),
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
            child: AlongSpringSheet(fraction: 0.62, child: _LiveSheet()),
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
    return ListView(
      padding: EdgeInsets.zero,
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
        const SizedBox(height: 12),
        Row(
          children: [
            const AlongDriverPortrait(size: 56, verified: true),
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
                  Text(
                    'ABC-123-XY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: AlongType.caption(palette).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const _RoundIcon(icon: AlongIcons.chat, tooltip: 'Chat'),
            const SizedBox(width: 8),
            const _RoundIcon(icon: AlongIcons.call, tooltip: 'Call'),
          ],
        ),
        const SizedBox(height: 12),
        const _Timeline(),
        const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          const _MapHero(height: 200, label: 'Location goes with the alert'),
          const SizedBox(height: 12),
          const _FactRow(icon: AlongIcons.locate, label: 'Live location'),
          const _FactRow(icon: AlongIcons.share, label: 'The people you chose'),
          const _FactRow(icon: AlongIcons.sos, label: 'Only while you hold'),
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
          const _MapHero(height: 240, label: 'This ride · Wuse to Nyanya'),
          const SizedBox(height: 12),
          const _RuleRow(label: 'Off the route', value: '400 m'),
          const _RuleRow(label: 'Still for', value: '3 min'),
          const _RuleRow(label: 'Check-in every', value: '15 min'),
          const _RuleRow(label: 'Safe word', value: 'Set'),
          const SizedBox(height: 8),
          const _PersonCard(
            name: 'Adaeze',
            detail: 'Gets the check-in',
            trailing: 'Mum',
            verified: false,
          ),
          const _PersonCard(
            name: 'Chidi',
            detail: 'Gets the check-in',
            trailing: 'Brother',
            verified: false,
          ),
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
          const SizedBox(height: 12),
          const _PersonCard(
            name: 'Chinedu',
            detail: 'Hiace · matches this plate',
            trailing: '4.9',
          ),
          const SizedBox(height: 8),
          const _FleetCard(
            kind: AlongVehicleKind.danfo,
            caption: 'The Hiace on this ride',
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
          const _MapHero(height: 240, label: 'Wuse to Nyanya'),
          const SizedBox(height: 12),
          const _PersonCard(
            name: 'Chinedu',
            detail: 'Gets this fare',
            trailing: 'Hiace',
          ),
          const SizedBox(height: 8),
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
          const _MapHero(height: 280, label: 'Wuse park to Nyanya'),
          const SizedBox(height: 12),
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
              fraction: 0.58,
              child: ListView(
                padding: EdgeInsets.zero,
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
                  const SizedBox(height: 8),
                  Text(
                    '₦18,400',
                    style: AlongType.numeric(palette).copyWith(fontSize: 40),
                  ),
                  Text('Today · 6 trips', style: AlongType.caption(palette)),
                  const SizedBox(height: 12),
                  const _GoalRow(),
                  const SizedBox(height: 12),
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
          Text('11 trips · goal ₦60,000', style: AlongType.bodyMuted(palette)),
          const SizedBox(height: 8),
          const _GoalMeter(progress: 0.8),
          const SizedBox(height: 16),
          const _WeekBars(),
          const SizedBox(height: 16),
          const _PayoutCard(),
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

class AlongFlowRides extends StatelessWidget {
  const AlongFlowRides({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlongPalette.of(context).mapLand,
      body: const Stack(
        children: [
          Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.trip, progress: 1),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.back, tooltip: 'Back'),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _MapChip(label: '4.2 km · 18 min'),
          ),
          Positioned.fill(
            child: AlongSpringSheet(fraction: 0.64, child: _RideSheet()),
          ),
        ],
      ),
    );
  }
}

class _RideSheet extends StatelessWidget {
  const _RideSheet();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a ride', style: AlongType.display(palette)),
        const SizedBox(height: 4),
        Text(
          'Wuse to Nyanya · 4.2 km',
          style: AlongType.bodyMuted(palette)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 12),
        const Expanded(child: _RideList()),
        const SizedBox(height: 8),
        const AlongButton(label: 'Confirm keke', onPressed: _noop),
      ],
    );
  }
}

class _RideList extends StatelessWidget {
  const _RideList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        _RideRow(
          kind: AlongVehicleKind.keke,
          title: 'Keke',
          eta: '4 min',
          seats: '2 left',
          fare: '₦400-600',
          chips: ['Window open', 'Women in back'],
          selected: true,
        ),
        _RideRow(
          kind: AlongVehicleKind.okada,
          title: 'Okada',
          eta: '3 min',
          seats: '1 left',
          fare: '₦300-500',
          chips: ['Helmet on'],
        ),
        _RideRow(
          kind: AlongVehicleKind.car,
          title: 'Car',
          eta: '6 min',
          seats: '3 left',
          fare: '₦1,100-1,400',
          chips: ['AC', 'Trust 86'],
        ),
        _RideRow(
          kind: AlongVehicleKind.danfo,
          title: 'Danfo',
          eta: '8 min',
          seats: '8 left',
          fare: '₦200-350',
          chips: ['Along the corridor'],
        ),
        _RideRow(
          kind: AlongVehicleKind.bus,
          title: 'Bus',
          eta: '12 min',
          seats: '14 left',
          fare: '₦500-800',
          chips: ['Seats assigned'],
        ),
      ],
    );
  }
}

class AlongFlowSearch extends StatelessWidget {
  const AlongFlowSearch({super.key});

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
            child: AlongMapButton(icon: AlongIcons.back, tooltip: 'Back'),
          ),
          const Positioned(
            top: 64,
            left: 0,
            right: 0,
            child: Center(child: _SearchRadar()),
          ),
          Positioned.fill(
            child: AlongSpringSheet(
              fraction: 0.42,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Text('Finding a keke', style: AlongType.heading(palette)),
                  const SizedBox(height: 4),
                  Text(
                    'Usually 4 min in Wuse',
                    style: AlongType.bodyMuted(palette),
                  ),
                  const SizedBox(height: 12),
                  const AlongSkeleton(width: 180, height: 14),
                  const SizedBox(height: 8),
                  const AlongSkeleton(height: 14),
                  const SizedBox(height: 16),
                  const AlongButton(
                    label: 'Cancel',
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

class AlongFlowRating extends StatelessWidget {
  const AlongFlowRating({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _Page(
      bottom: const AlongButton(label: 'Send thanks', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Center(child: AlongDriverPortrait(size: 72, verified: true)),
          const SizedBox(height: 12),
          Center(
            child: Text('How was Chinedu?', style: AlongType.heading(palette)),
          ),
          const SizedBox(height: 8),
          const Center(child: _Stars(filled: 4, size: 28)),
          const SizedBox(height: 16),
          const _MapHero(height: 148, label: 'Wuse to Nyanya · 4.2 km'),
          const SizedBox(height: 16),
          Text('Add a tip', style: AlongType.caption(palette)),
          const SizedBox(height: 8),
          const Row(
            children: [
              _TipChip('₦100'),
              SizedBox(width: 8),
              _TipChip('₦200', selected: true),
              SizedBox(width: 8),
              _TipChip('₦500'),
            ],
          ),
          const SizedBox(height: 16),
          Text('Receipt', style: AlongType.caption(palette)),
          const SizedBox(height: 4),
          const _RuleRow(label: 'Wuse to Nyanya', value: '4.2 km'),
          const _RuleRow(label: 'Base fare', value: '₦1,000'),
          const _RuleRow(label: 'Seat', value: '₦200'),
          const _RuleRow(label: 'Tip', value: '₦200'),
          const _RuleRow(label: 'Total', value: '₦1,400'),
        ],
      ),
    );
  }
}

class _MapHero extends StatelessWidget {
  const _MapHero({required this.height, required this.label});

  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(
              child: AlongCityMap(mode: AlongCityMapMode.routeHero),
            ),
            Positioned(left: 10, bottom: 10, child: _MapChip(label: label)),
          ],
        ),
      ),
    );
  }
}

class _FleetCard extends StatelessWidget {
  const _FleetCard({
    this.kind = AlongVehicleKind.keke,
    this.caption = 'Keke, okada, car, danfo, bus',
  });

  final AlongVehicleKind kind;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 248,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Column(
        children: [
          const Spacer(),
          AlongVehicleMark(kind: kind, width: 220),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AlongType.caption(palette)
                .copyWith(fontWeight: FontWeight.w700, color: palette.ink),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.name,
    required this.detail,
    required this.trailing,
    this.verified = true,
  });

  final String name;
  final String detail;
  final String trailing;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Row(
        children: [
          _Face(name: name, verified: verified),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AlongType.title(palette)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(detail, style: AlongType.caption(palette)),
              ],
            ),
          ),
          Text(
            trailing,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.1),
          ),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.name, required this.verified});

  final String name;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    if (name == 'Adaeze') {
      return const AlongDriverPortrait(
        size: 48,
        asset: AlongDriverPortrait.adaeze,
        verified: true,
      );
    }
    if (name == 'Chinedu') {
      return AlongDriverPortrait(size: 48, verified: verified);
    }
    final palette = AlongPalette.of(context);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.recessed,
        shape: BoxShape.circle,
      ),
      child: Text(
        name.substring(0, 1),
        style: AlongType.title(palette).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next cash out', style: AlongType.caption(palette)),
          const SizedBox(height: 4),
          Text('Friday', style: AlongType.heading(palette)),
          Text(
            '₦48,200 available',
            style: AlongType.bodyMuted(palette)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
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
  const _Field({required this.child, this.fill});

  final Widget child;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: fill ?? palette.surface,
        borderRadius: BorderRadius.circular(18),
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
    required this.fare,
  });

  final AlongVehicleKind kind;
  final String title;
  final String detail;
  final String fare;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: 196,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Row(
        children: [
          AlongVehicleMark(kind: kind, width: 72),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AlongType.title(palette).copyWith(fontSize: 15),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AlongType.caption(palette),
                ),
                Text(
                  fare,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AlongType.numeric(palette)
                      .copyWith(fontSize: 14, height: 1.2, letterSpacing: 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  const _RideRow({
    required this.kind,
    required this.title,
    required this.eta,
    required this.seats,
    required this.fare,
    required this.chips,
    this.selected = false,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final String seats;
  final String fare;
  final List<String> chips;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: selected ? palette.surface : palette.recessed,
        borderRadius: BorderRadius.circular(16),
        border: selected ? Border.all(color: palette.accent, width: 2) : null,
        boxShadow: selected ? AlongElevation.lifted(palette.ink) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AlongVehicleMark(kind: kind, width: 64),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: AlongType.title(palette).copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 16,
                                  height: 16,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: palette.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    AlongIcons.check,
                                    size: 12,
                                    color: palette.accentInk,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            seats,
                            maxLines: 1,
                            softWrap: false,
                            style: AlongType.caption(palette).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 104,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fare,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: AlongType.numeric(palette).copyWith(
                              fontSize: 13,
                              height: 1.15,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            eta,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: AlongType.caption(palette).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _ChipLine(chips: chips),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of chips under the name. At most two labels that fit whole, then `+n`.
/// Measured a pixel tight of the real glyph width so the row cannot overflow.
class _ChipLine extends StatelessWidget {
  const _ChipLine({required this.chips});

  static const _gap = 4.0;
  static const _pad = 5.0;

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox(height: 24);
    final palette = AlongPalette.of(context);
    final style = AlongType.caption(palette).copyWith(
      fontSize: 12,
      height: 1,
      fontWeight: FontWeight.w600,
      color: palette.ink,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final limit = constraints.maxWidth;
        final shown = <String>[];
        var used = 0.0;
        for (final chip in chips) {
          if (shown.length == 2) break;
          final remainingAfter = chips.length - shown.length - 1;
          final badge = remainingAfter > 0
              ? _chipWidth('+$remainingAfter', style) + _gap
              : 0.0;
          final width = _chipWidth(chip, style);
          final gap = shown.isEmpty ? 0.0 : _gap;
          if (used + gap + width + badge <= limit) {
            shown.add(chip);
            used += gap + width;
          } else {
            break;
          }
        }
        if (shown.isEmpty && chips.isNotEmpty) {
          // A single rule still has to paint. It ellipsizes inside the chip
          // only when the label is wider than the whole row.
          shown.add(chips.first);
        }
        final hidden = chips.length - shown.length;
        return SizedBox(
          height: 24,
          width: limit,
          child: Row(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                _Chip(shown[i]),
              ],
              if (hidden > 0) ...[
                const SizedBox(width: _gap),
                _Chip('+$hidden'),
              ],
            ],
          ),
        );
      },
    );
  }
}

double _chipWidth(String label, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  // +1 covers the subpixel gap between TextPainter and the glyph run.
  return painter.width + (_ChipLine._pad * 2) + 1;
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: _ChipLine._pad),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: palette.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: AlongType.caption(palette).copyWith(
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.86;
        return SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _enter(
                SizedBox(
                  width: width,
                  child: const _Promo(
                    title: 'Evening along',
                    detail: '₦200 off Wuse to Nyanya',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: width,
                child: const _Promo(
                  title: 'Night seats',
                  detail: '₦100 off after 9',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Promo extends StatelessWidget {
  const _Promo({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 88,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const AlongVehicleMark(kind: AlongVehicleKind.keke, width: 56),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AlongType.title(palette),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
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
      height: 64,
      child: Row(
        children: [
          const AlongDriverPortrait(
            size: 40,
            asset: AlongDriverPortrait.adaeze,
            verified: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adaeze', style: AlongType.title(palette)),
                Text(
                  '4.9 rider',
                  style: AlongType.caption(palette).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const _Stars(filled: 5, size: 14),
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
      ('M', 56, false),
      ('Tu', 80, false),
      ('W', 64, false),
      ('Th', 112, true),
      ('F', 88, false),
      ('Sa', 48, false),
      ('Su', 36, false),
    ];
    return SizedBox(
      height: 148,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _Quick(icon: AlongIcons.home, label: 'Home'),
        _Quick(icon: AlongIcons.work, label: 'Work'),
        _Quick(icon: AlongIcons.schedule, label: 'Plan'),
        _Quick(icon: AlongIcons.seat, label: 'Seats'),
      ],
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              boxShadow: AlongElevation.float(palette.ink),
            ),
            child: Icon(icon, color: palette.ink, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: AlongType.caption(palette)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TimeStop(title: 'Wuse Market', detail: 'Picked up', done: true),
        _TimeStop(title: 'Berger', detail: 'Now', done: true, current: true),
        _TimeStop(title: 'Nyanya', detail: '12 min', done: false, last: true),
      ],
    );
  }
}

class _TimeStop extends StatelessWidget {
  const _TimeStop({
    required this.title,
    required this.detail,
    required this.done,
    this.current = false,
    this.last = false,
  });

  final String title;
  final String detail;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: done ? palette.accent : palette.recessed,
                    shape: BoxShape.circle,
                    border: current
                        ? Border.all(color: palette.ink, width: 2)
                        : null,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: palette.line.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: AlongType.body(palette))),
          Text(
            detail,
            style: AlongType.caption(palette).copyWith(
              color: current ? palette.ink : palette.muted,
              fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.recessed,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _noop,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: palette.ink, size: 22),
          ),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        const _GoalRing(progress: 0.75),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('6 of 8 trips', style: AlongType.title(palette)),
              Text('Daily goal', style: AlongType.caption(palette)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '4-day streak',
            style: AlongType.caption(
              palette,
            ).copyWith(color: palette.accentInk, fontWeight: FontWeight.w700),
          ),
        ),
      ],
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
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          track: palette.line.withValues(alpha: 0.35),
          ink: palette.accent,
        ),
        child: Center(
          child: Text(
            '6',
            style: AlongType.numeric(palette).copyWith(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _GoalMeter extends StatelessWidget {
  const _GoalMeter({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: palette.recessed,
        color: palette.accent,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.ink,
  });

  final double progress;
  final Color track;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(4),
      0,
      math.pi * 2,
      false,
      stroke..color = track,
    );
    canvas.drawArc(
      rect.deflate(4),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      stroke..color = ink,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Stars extends StatelessWidget {
  const _Stars({required this.filled, required this.size});

  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            AlongIcons.star,
            size: size,
            color: i < filled ? palette.accent : palette.line,
          ),
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.surface : palette.recessed,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: palette.accent, width: 2) : null,
          boxShadow: selected ? AlongElevation.card(palette.ink) : null,
        ),
        child: Text(
          label,
          style: AlongType.title(palette)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}

class _SearchRadar extends StatefulWidget {
  const _SearchRadar();

  @override
  State<_SearchRadar> createState() => _SearchRadarState();
}

class _SearchRadarState extends State<_SearchRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (AlongMotionPolicy.inWidgetTest) {
      _controller.value = 0.38;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Lottie.asset(
            'assets/motion/radar.json',
            package: 'along_design',
            width: 200,
            height: 200,
            animate: !AlongMotionPolicy.inWidgetTest,
            repeat: true,
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: const Size.square(200),
                painter: _SweepPainter(
                  turn: _controller.value,
                  color: palette.accent,
                  ink: palette.ink,
                ),
              );
            },
          ),
          const AlongVehicleMark(kind: AlongVehicleKind.keke, width: 120),
        ],
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({required this.turn, required this.color, required this.ink});

  final double turn;
  final Color color;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ink.withValues(alpha: 0.35);
    for (final radius in [46.0, 72.0, 96.0]) {
      canvas.drawCircle(center, radius, paint);
    }
    final sweep = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: 96),
        turn * math.pi * 2 - 0.6,
        0.6,
        false,
      )
      ..close();
    canvas.drawPath(sweep, Paint()..color = color.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.turn != turn;
}

Widget _enter(Widget child) {
  if (AlongMotionPolicy.inWidgetTest) return child;
  return child.animate().fadeIn(duration: 220.ms).slideY(begin: 0.06, end: 0);
}

void _noop() {}
