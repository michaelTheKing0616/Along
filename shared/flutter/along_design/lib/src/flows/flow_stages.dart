import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../components/along_button.dart';
import '../components/seat_map.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../theme.dart';
import '../type.dart';
import 'city_map.dart';
import 'driver_portrait.dart';
import 'map_sketch.dart';
import 'spring_sheet.dart';
import 'vehicle_art.dart';

/// Premium flow frames for both apps. Copy is warm and plain. [jk-writing]
/// Layout groups with a 4pt scale and 48dp targets. [jk-layout] [jk-accessibility]

class AlongFlowOnboarding extends StatelessWidget {
  const AlongFlowOnboarding({
    super.key,
    this.legacyCopy = false,
    this.step = 0,
  });

  final bool legacyCopy;

  /// 0 is the poster. 1 is the phone step, still one tap away.
  final int step;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    if (step > 0) return _phoneStep(palette);
    // The poster is a photograph. Keep the light paper theme so the
    // headline and the button stay readable in the dark gallery too.
    return Theme(data: alongTheme(), child: const _Poster());
  }

  Widget _phoneStep(AlongPalette palette) {
    return _Page(
      bottom: const AlongButton(label: 'Text me the code', onPressed: _noop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your number', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text(
            legacyCopy
                ? 'Enter your number to continue'
                : 'We text a code to this number so the ride stays yours.',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 16),
          _Field(
            fill: palette.surface,
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
          const SizedBox(height: 8),
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
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fraction = constraints.maxHeight >= 760 ? 0.36 : 0.44;
                return AlongSpringSheet(
                  fraction: fraction,
                  snaps: [fraction, 0.88],
                  child: const _HomeSheetBody(),
                );
              },
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const _PlaceRow(
          icon: AlongIcons.home,
          title: 'Home',
          detail: 'Garki · 12 min',
        ),
        const _PlaceRow(
          icon: AlongIcons.work,
          title: 'Work',
          detail: 'Wuse Market',
        ),
        const _Fold(
          label: 'Recent and rides',
          child: Column(
            children: [
              _VehicleChips(),
              SizedBox(height: 8),
              _PlaceRow(
                icon: AlongIcons.schedule,
                title: 'Nyanya',
                detail: 'Yesterday · ₦1,200',
              ),
              _PlaceRow(
                icon: AlongIcons.schedule,
                title: 'Jabi',
                detail: 'Tuesday · ₦900',
              ),
              _PlaceRow(
                icon: AlongIcons.schedule,
                title: 'Berger',
                detail: 'Monday · ₦1,400',
              ),
              _PromoCarousel(),
              _RideRow(
                kind: AlongVehicleKind.keke,
                title: 'Keke',
                eta: '4 min',
                seats: '2 left',
                fare: '₦400-600',
                rules: ['Window open'],
                selected: true,
              ),
              _RideRow(
                kind: AlongVehicleKind.car,
                title: 'Car',
                eta: '6 min',
                seats: '3 left',
                fare: '₦1,100',
                rules: ['AC', 'Trust 86'],
              ),
              SizedBox(height: 8),
              _QuickActions(),
              AlongButton(label: 'See rides', onPressed: _noop),
            ],
          ),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a seat', style: AlongType.display(palette)),
          const SizedBox(height: 4),
          Text('Sedan · ABC-123-XY', style: AlongType.bodyMuted(palette)),
          const SizedBox(height: 8),
          const Expanded(
            child: SeatMap(
              body: 'cabin',
              rows: [
                SeatMapRowView(
                  id: 'front',
                  seats: [
                    SeatMapSeat(
                      id: 'fl',
                      label: 'FL',
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
                  ruleTitle: 'Window stays open',
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
              ],
            ),
          ),
          const _Fold(
            label: 'Driver and key',
            child: Column(
              children: [
                _Legend(),
                SizedBox(height: 8),
                _PersonCard(
                  name: 'Chinedu',
                  detail: 'Hiace · ABC-123-XY',
                  trailing: '₦1,200',
                ),
              ],
            ),
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
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fraction = constraints.maxHeight >= 760 ? 0.40 : 0.50;
                return AlongSpringSheet(
                  fraction: fraction,
                  snaps: [fraction, 0.72],
                  child: const _LiveSheet(),
                );
              },
            ),
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
          children: [
            const AlongVehicleMark(
              kind: AlongVehicleKind.car,
              width: 108,
              height: 60,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABC-123-XY',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.title(palette).copyWith(
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Silver sedan',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.meta(palette),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const AlongDriverPortrait(size: 40, verified: true),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chinedu',
                maxLines: 1,
                softWrap: false,
                style: AlongType.title(palette)
                    .copyWith(fontSize: 16, height: 1.1),
              ),
            ),
            Text(
              '4.9',
              maxLines: 1,
              softWrap: false,
              style: AlongType.meta(palette),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('6 min', style: AlongType.heading(palette)),
        Text(
          'Nyanya',
          maxLines: 1,
          softWrap: false,
          style: AlongType.title(palette).copyWith(fontSize: 16, height: 1.15),
        ),
        const _Fold(
          label: 'Share and call',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text('ABC-123-XY', maxLines: 1, softWrap: false),
              SizedBox(height: 4),
              Text('4.9 · Trust 86', maxLines: 1, softWrap: false),
              SizedBox(height: 8),
              _Timeline(),
              SizedBox(height: 8),
              Row(
                children: [
                  _RoundIcon(icon: AlongIcons.chat, tooltip: 'Chat'),
                  SizedBox(width: 8),
                  _RoundIcon(icon: AlongIcons.call, tooltip: 'Call'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _SafetyAction(icon: AlongIcons.share, label: 'Share'),
                  _SafetyAction(
                    icon: AlongIcons.sos,
                    label: 'SOS',
                    danger: true,
                  ),
                  _SafetyAction(icon: AlongIcons.shield, label: 'Guardian'),
                ],
              ),
            ],
          ),
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
      bottom: const SizedBox.shrink(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final short = constraints.maxHeight < 620;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Safety', style: AlongType.display(palette)),
              const SizedBox(height: 4),
              Text(
                'Your location goes with the alert.',
                maxLines: 1,
                softWrap: false,
                style: AlongType.bodyMuted(palette),
              ),
              SizedBox(height: short ? 8 : 12),
              Center(child: _HoldRing(size: short ? 152 : 176)),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TrustedFaces(),
                        _SafetyLine(
                          icon: AlongIcons.share,
                          label: 'Share trip',
                        ),
                        _SafetyLine(icon: AlongIcons.call, label: 'Call 112'),
                        _SafetyTips(),
                        _Fold(label: 'Who is told', child: _SosPanel()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guardian', style: AlongType.display(palette)),
          const SizedBox(height: 4),
          Text(
            'On Nyanya road · check-in 14:02',
            maxLines: 1,
            softWrap: false,
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 8),
          const _MapHero(height: 148, label: 'Live', live: true),
          const SizedBox(height: 8),
          const _ContactLine(
            name: 'Adaeze',
            detail: 'Sister · shares this trip',
            asset: AlongDriverPortrait.adaeze,
          ),
          const _ContactLine(name: 'Chidi', detail: 'Brother', initials: 'CH'),
          const _ContactLine(name: 'Ngozi', detail: 'Aunt', initials: 'NG'),
          const _Fold(label: 'Rules', child: _RuleStrip()),
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
    return Scaffold(
      backgroundColor: palette.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PlateFrame(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check the plate',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.heading(palette)
                        .copyWith(color: Colors.white),
                  ),
                  Text(
                    'Fit the plate in the frame.',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.meta(palette)
                        .copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PlateMatch(),
                          _Fold(
                            label: 'Driver',
                            child: _PersonCard(
                              name: 'Chinedu',
                              detail: 'Sedan · matches this plate',
                              trailing: '4.9',
                            ),
                          ),
                          SizedBox(height: 8),
                          AlongButton(label: 'Continue', onPressed: _noop),
                        ],
                      ),
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

class AlongFlowWallet extends StatelessWidget {
  const AlongFlowWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      bottom: const AlongButton(label: 'Pay ₦1,200', onPressed: _noop),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _PassStack(),
          const SizedBox(height: 16),
          const _TxnRow(
            icon: AlongIcons.receipt,
            title: 'Nyanya',
            detail: 'Today · seat hold',
            value: '−₦1,200',
          ),
          const _TxnRow(
            icon: AlongIcons.earnings,
            title: 'Top up',
            detail: 'Tuesday · transfer',
            value: '+₦5,000',
          ),
          const _Fold(
            label: 'Add money and earlier',
            child: Column(
              children: [
                _WalletTiles(),
                SizedBox(height: 8),
                _CreditNote(),
                _TxnRow(
                  icon: AlongIcons.wallet,
                  title: 'Wallet',
                  detail: 'Available',
                  value: '₦6,400',
                ),
                _TxnRow(
                  icon: AlongIcons.navigate,
                  title: 'Berger',
                  detail: 'Yesterday',
                  value: '−₦900',
                ),
                _TxnRow(
                  icon: AlongIcons.navigate,
                  title: 'Jabi',
                  detail: 'Monday',
                  value: '−₦1,600',
                ),
                _TxnRow(
                  icon: AlongIcons.earnings,
                  title: 'Cash out',
                  detail: 'Sunday · GTBank',
                  value: '−₦8,000',
                ),
              ],
            ),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thursday', style: AlongType.display(palette)),
          const SizedBox(height: 4),
          Text(
            'Nyanya',
            maxLines: 1,
            softWrap: false,
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 8),
          const Expanded(child: _DayTimeline()),
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
          const Positioned(top: 16, left: 16, child: _HeatTip()),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_TodayPill(), SizedBox(height: 16), _GoButton()],
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
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.routeHero),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AlongElevation.sheet(palette.ink),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '₦1,800',
                            maxLines: 1,
                            softWrap: false,
                            style: AlongType.numeric(palette)
                                .copyWith(fontSize: 36, height: 1.05),
                          ),
                        ),
                        const _CountdownRing(progress: 0.72, label: '12'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AlongButton(label: 'Accept', onPressed: _noop),
                    const _Fold(
                      label: 'Rider and stops',
                      child: Column(
                        children: [
                          Text(
                            'Wuse to Nyanya · 6 min',
                            maxLines: 1,
                            softWrap: false,
                          ),
                          SizedBox(height: 8),
                          _Stop(
                            time: '6 min',
                            title: 'Wuse Market',
                            detail: 'Pickup',
                          ),
                          _Stop(
                            time: '4.2 km',
                            title: 'Nyanya',
                            detail: 'Dropoff',
                          ),
                          _RiderRow(),
                          SizedBox(height: 8),
                          AlongButton(
                            label: 'Decline',
                            variant: AlongButtonVariant.secondary,
                            onPressed: _noop,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The first viewport is the total and the chart. Payout and the
          // trip list start on the next scroll.
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today', style: AlongType.caption(palette)),
                      Text(
                        '₦48,200',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.numeric(palette)
                            .copyWith(fontSize: 48),
                      ),
                      Text(
                        '11 trips · goal ₦60,000',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.bodyMuted(palette),
                      ),
                      const SizedBox(height: 8),
                      const _GoalMeter(progress: 0.8),
                      const SizedBox(height: 8),
                      const Expanded(child: _WeekBars()),
                    ],
                  ),
                ),
                const _PayoutCard(),
                const _EarningTrip(
                  place: 'Thu · Nyanya',
                  fare: '₦1,800',
                  tip: '₦200',
                ),
                const _EarningTrip(place: 'Wed · Wuse', fare: '₦1,200'),
                const _EarningTrip(
                  place: 'Tue · Garki',
                  fare: '₦900',
                  tip: '₦100',
                ),
                const _EarningTrip(place: 'Mon · Berger', fare: '₦1,400'),
                const _EarningTrip(
                  place: 'Sun · Jabi',
                  fare: '₦1,600',
                  tip: '₦300',
                ),
                const _EarningTrip(place: 'Sat · Nyanya', fare: '₦2,100'),
                const _EarningTrip(place: 'Fri · Airport', fare: '₦3,200'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AlongFlowRides extends StatelessWidget {
  const AlongFlowRides({super.key, this.rulesFor});

  /// When set, the ride-details sheet is open on this product.
  final int? rulesFor;

  static const _products = <(String, String, List<String>)>[
    ('Keke', '₦400-600', ['Window open', 'Women in back']),
    ('Okada', '₦300-500', ['Helmet on']),
    ('Car', '₦1,100-1,400', ['AC', 'Trust 86']),
    ('Danfo', '₦200-350', ['Along the corridor']),
    ('Bus', '₦500-800', ['Seats assigned']),
  ];

  @override
  Widget build(BuildContext context) {
    final detail = rulesFor;
    final product = detail == null ? null : _products[detail];
    return Scaffold(
      backgroundColor: AlongPalette.of(context).mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.trip, progress: 1),
          ),
          const Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.back, tooltip: 'Back'),
          ),
          const Positioned(
            top: 16,
            right: 16,
            child: _MapChip(label: '4.2 km · 18 min'),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Three large cards, then the rest of the fleet scrolls.
                // Uber's select screen is the list. Leave a strip of map.
                final height = constraints.maxHeight - 72;
                return AlongSpringSheet(
                  restingHeight: height,
                  child: const _RideSheet(),
                );
              },
            ),
          ),
          if (product != null)
            Positioned.fill(
              child: AlongSpringSheet(
                fraction: 0.42,
                child: _RideRules(
                  title: product.$1,
                  fare: product.$2,
                  rules: product.$3,
                ),
              ),
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
        Text('Choose a ride', style: AlongType.heading(palette)),
        const SizedBox(height: 2),
        Text(
          'Wuse to Nyanya · 4.2 km',
          maxLines: 1,
          softWrap: false,
          style: AlongType.meta(palette)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 8),
        const _RecommendedRide(),
        const SizedBox(height: 4),
        const Expanded(child: _RideList()),
        const SizedBox(height: 6),
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
        _RideLine(
          kind: AlongVehicleKind.okada,
          title: 'Okada',
          eta: '3 min',
          seats: '1 left',
          fare: '₦300-500',
          badge: 'Fastest',
        ),
        _RideLine(
          kind: AlongVehicleKind.car,
          title: 'Car',
          eta: '6 min',
          seats: '3 left',
          fare: '₦1,100-1,400',
        ),
        _RideLine(
          kind: AlongVehicleKind.danfo,
          title: 'Danfo',
          eta: '8 min',
          seats: '8 left',
          fare: '₦200-350',
          badge: 'Cheapest',
        ),
        _RideLine(
          kind: AlongVehicleKind.bus,
          title: 'Bus',
          eta: '12 min',
          seats: '14 left',
          fare: '₦500-800',
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
          const Positioned.fill(
            child: AlongCityMap(mode: AlongCityMapMode.search),
          ),
          const Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.back, tooltip: 'Back'),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fraction = constraints.maxHeight >= 760 ? 0.38 : 0.46;
                return AlongSpringSheet(
                  fraction: fraction,
                  snaps: [fraction, 0.72],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3 offers',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.heading(palette),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Wuse · keke',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.meta(palette),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: const [
                            _BidRow(
                              name: 'Ife',
                              rating: '4.7',
                              vehicle: 'Keke',
                              eta: '8 min',
                              fare: '₦380',
                              initials: 'IF',
                              best: true,
                            ),
                            _BidRow(
                              name: 'Chinedu',
                              rating: '4.9',
                              vehicle: 'Keke',
                              eta: '4 min',
                              fare: '₦400',
                            ),
                            _BidRow(
                              name: 'Adaeze',
                              rating: '4.8',
                              vehicle: 'Keke',
                              eta: '6 min',
                              fare: '₦450',
                              rider: true,
                            ),
                          ],
                        ),
                      ),
                      const AlongButton(
                        label: 'Cancel',
                        variant: AlongButtonVariant.secondary,
                        onPressed: _noop,
                      ),
                    ],
                  ),
                );
              },
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
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final short = constraints.maxHeight < 700;
            final portrait = short ? 72.0 : 88.0;
            final star = short ? 40.0 : 48.0;
            return Column(
              children: [
                const Expanded(
                  child: AlongCityMap(mode: AlongCityMapMode.completed),
                ),
                Transform.translate(
                  offset: Offset(0, -portrait / 2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: [
                        AlongDriverPortrait(size: portrait, verified: true),
                        SizedBox(height: short ? 8 : 10),
                        Text(
                          'Chinedu',
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: AlongType.heading(palette),
                        ),
                        Text(
                          'Wuse to Nyanya',
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: AlongType.meta(palette),
                        ),
                        SizedBox(height: short ? 8 : 12),
                        _Stars(filled: 4, size: star),
                        SizedBox(height: short ? 10 : 14),
                        const _ComplimentWrap(),
                        SizedBox(height: short ? 10 : 14),
                        const Row(
                          children: [
                            _TipChip('₦100'),
                            SizedBox(width: 6),
                            _TipChip('₦200', selected: true),
                            SizedBox(width: 6),
                            _TipChip('₦500'),
                            SizedBox(width: 6),
                            _TipChip('Custom'),
                          ],
                        ),
                        SizedBox(height: short ? 10 : 12),
                        const AlongButton(
                          label: 'Send thanks',
                          onPressed: _noop,
                        ),
                        const SizedBox(height: 4),
                        const _ViewReceipt(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Two rows, always. The long labels share the second row so a narrow
/// phone does not drop "On time" onto a third line.
class _ComplimentWrap extends StatelessWidget {
  const _ComplimentWrap();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ComplimentChip('Smooth ride', selected: true),
            SizedBox(width: 8),
            _ComplimentChip('Clean car'),
            SizedBox(width: 8),
            _ComplimentChip('On time'),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ComplimentChip('Great conversation'),
            SizedBox(width: 8),
            _ComplimentChip('Safe driving'),
          ],
        ),
      ],
    );
  }
}

class _ComplimentChip extends StatelessWidget {
  const _ComplimentChip(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? palette.ink : palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected ? palette.ink : palette.line.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AlongType.meta(palette).copyWith(
          color: selected ? palette.onInk : palette.ink,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _ViewReceipt extends StatelessWidget {
  const _ViewReceipt();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return GestureDetector(
      onTap: _noop,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'View receipt',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: AlongType.title(palette).copyWith(
            fontSize: 16,
            height: 1.2,
            decoration: TextDecoration.underline,
            decorationColor: palette.ink,
          ),
        ),
      ),
    );
  }
}

class _MapHero extends StatelessWidget {
  const _MapHero({
    required this.height,
    required this.label,
    this.live = false,
  });

  final double height;
  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AlongCityMap(
              mode: AlongCityMapMode.routeHero,
              liveMarker: live,
            ),
          ),
          Positioned(left: 10, bottom: 10, child: _MapChip(label: label)),
        ],
      ),
    );
    if (!height.isFinite) return map;
    return SizedBox(height: height, width: double.infinity, child: map);
  }
}

class _Poster extends StatelessWidget {
  const _Poster();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    const ink = Color(0xFFFFFFFF);
    return Scaffold(
      backgroundColor: const Color(0xFF8ECAE6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/photos/onboarding-fleet.jpg',
            package: 'along_design',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66101828),
                  Color(0x00000000),
                  Color(0x00000000),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move around.',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.display(palette).copyWith(color: ink),
                ),
                Text(
                  'Your way.',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.display(palette).copyWith(color: ink),
                ),
                const SizedBox(height: 16),
                const AlongButton(label: 'Continue', onPressed: _noop),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldRing extends StatefulWidget {
  const _HoldRing({this.size = 220});

  final double size;

  @override
  State<_HoldRing> createState() => _HoldRingState();
}

class _HoldRingState extends State<_HoldRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: 0.66,
    );
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) => _fill.forward(from: 0);

  void _up(PointerEvent _) {
    if (_fill.value < 1) _fill.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedBuilder(
        animation: _fill,
        builder: (context, _) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _HoldRingPainter(
                progress: _fill.value,
                color: palette.danger,
                track: palette.surface,
              ),
              child: Center(
                child: SizedBox(
                  width: widget.size * 0.70,
                  child: Text(
                    'Hold to alert',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: AlongType.caption(palette).copyWith(
                      color: const Color(0xFFF7F7F8),
                      fontSize: 13,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  _HoldRingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xCC1C1916));
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = track.withValues(alpha: 0.28),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HoldRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Text('Friday', style: AlongType.title(palette)),
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

class _Fold extends StatefulWidget {
  const _Fold({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<_Fold> createState() => _FoldState();
}

class _FoldState extends State<_Fold> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.title(palette)
                        .copyWith(fontSize: 16, height: 1.1),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: palette.muted,
                ),
              ],
            ),
          ),
        ),
        if (_open) widget.child,
      ],
    );
  }
}

class _GoButton extends StatelessWidget {
  const _GoButton();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: 168,
      height: 168,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.accent,
        shape: BoxShape.circle,
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: Text(
        'GO',
        maxLines: 1,
        softWrap: false,
        style: AlongType.display(
          palette,
        ).copyWith(fontSize: 44, letterSpacing: -1.6, color: palette.accentInk),
      ),
    );
  }
}

class _TrustedFaces extends StatelessWidget {
  const _TrustedFaces();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    Widget face(Widget child) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.surface, width: 2),
        ),
        child: ClipOval(child: child),
      );
    }

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 36,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: face(
                    Image.asset(
                      AlongDriverPortrait.adaeze,
                      package: 'along_design',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  child: face(const _Monogram(initials: 'CH', size: 32)),
                ),
                Positioned(
                  left: 44,
                  child: face(const _Monogram(initials: 'NG', size: 32)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Trusted contacts',
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette)
                  .copyWith(fontSize: 16, height: 1.1),
            ),
          ),
          Icon(Icons.chevron_right, size: 22, color: palette.muted),
        ],
      ),
    );
  }
}

class _SafetyTips extends StatelessWidget {
  const _SafetyTips();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'Safety tips',
          maxLines: 1,
          softWrap: false,
          style: AlongType.meta(palette),
        ),
        for (final tip in const [
          'Share the trip',
          'Sit in the back',
          'Check the plate',
        ])
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tip,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.title(palette)
                        .copyWith(fontSize: 16, height: 1.1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SafetyLine extends StatelessWidget {
  const _SafetyLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Icon(icon, size: 22, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette),
            ),
          ),
          Icon(Icons.chevron_right, size: 22, color: palette.muted),
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

class _VehicleChips extends StatelessWidget {
  const _VehicleChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: const [
          _VehicleChip(
            kind: AlongVehicleKind.keke,
            title: 'Keke',
            fare: '₦400',
          ),
          SizedBox(width: 8),
          _VehicleChip(
            kind: AlongVehicleKind.okada,
            title: 'Okada',
            fare: '₦300',
          ),
          SizedBox(width: 8),
          _VehicleChip(
            kind: AlongVehicleKind.car,
            title: 'Car',
            fare: '₦1,100',
          ),
          SizedBox(width: 8),
          _VehicleChip(
            kind: AlongVehicleKind.danfo,
            title: 'Danfo',
            fare: '₦200',
          ),
          SizedBox(width: 8),
          _VehicleChip(kind: AlongVehicleKind.bus, title: 'Bus', fare: '₦500'),
        ],
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.kind,
    required this.title,
    required this.fare,
  });

  final AlongVehicleKind kind;
  final String title;
  final String fare;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: 112,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Column(
        children: [
          AlongVehicleMark(kind: kind, width: 100, height: 58),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: AlongType.title(palette).copyWith(fontSize: 14, height: 1.1),
          ),
          Text(
            fare,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 13, height: 1.1, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _RideBadge extends StatelessWidget {
  const _RideBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AlongType.caption(palette).copyWith(
          fontSize: 10,
          height: 1.05,
          fontWeight: FontWeight.w700,
          color: palette.accentInk,
        ),
      ),
    );
  }
}

class _RecommendedRide extends StatelessWidget {
  const _RecommendedRide();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: _RideRow(
          kind: AlongVehicleKind.keke,
          title: 'Keke',
          eta: '4 min',
          seats: '2 left',
          fare: '₦400-600',
          rules: ['Window open', 'Women in back'],
          badge: 'For you',
          selected: true,
        ),
      ),
    );
  }
}

class _RideLine extends StatelessWidget {
  const _RideLine({
    required this.kind,
    required this.title,
    required this.eta,
    required this.seats,
    required this.fare,
    this.badge,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final String seats;
  final String fare;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          AlongVehicleMark(kind: kind, width: 72, height: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette).copyWith(
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  badge == null ? '$eta · $seats' : '$badge · $eta',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.meta(palette),
                ),
              ],
            ),
          ),
          Text(
            fare,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 15, height: 1.05, letterSpacing: 0),
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
    this.rules = const [],
    this.badge,
    this.selected = false,
  });

  final AlongVehicleKind kind;
  final String title;
  final String eta;
  final String seats;
  final String fare;
  final List<String> rules;
  final String? badge;
  final bool selected;

  static const height = 108.0;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? palette.ink.withValues(alpha: 0.04) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? palette.ink.withValues(alpha: 0.22)
                : const Color(0x00000000),
          ),
        ),
        child: Row(
          children: [
            AlongVehicleMark(kind: kind, width: 140, height: 78),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return _fittedTitle(
                        maxWidth: constraints.maxWidth,
                        nameStyle: AlongType.title(palette).copyWith(
                          fontSize: 20,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                        fareStyle: AlongType.numeric(palette).copyWith(
                          fontSize: 18,
                          height: 1.05,
                          letterSpacing: -0.4,
                        ),
                        badgeStyle: AlongType.caption(palette).copyWith(
                          fontSize: 10,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: palette.accentInk,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$seats · $eta',
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.meta(palette).copyWith(
                            fontSize: 15,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            color: palette.brightness == Brightness.dark
                                ? const Color(0xFFC8C8D0)
                                : const Color(0xFF3A3A42),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (rules.isNotEmpty)
                        Icon(AlongIcons.info, size: 16, color: palette.muted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Keeps the fare on the right at 18sp. Scales the whole line only when a
  /// 320 row cannot hold the name, badge, and fare without clipping.
  Widget _fittedTitle({
    required double maxWidth,
    required TextStyle nameStyle,
    required TextStyle fareStyle,
    required TextStyle badgeStyle,
  }) {
    final nameW = _lineWidth(title, nameStyle);
    final fareW = _lineWidth(fare, fareStyle);
    final badgeW = badge == null ? 0.0 : _lineWidth(badge!, badgeStyle) + 16;
    const gap = 8.0;
    final needed = nameW + badgeW + gap + fareW;
    final width = math.max(maxWidth, needed + 1);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            Text(title, maxLines: 1, softWrap: false, style: nameStyle),
            if (badge != null) ...[
              const SizedBox(width: 6),
              _RideBadge(badge!),
            ],
            const Spacer(),
            Text(fare, maxLines: 1, softWrap: false, style: fareStyle),
          ],
        ),
      ),
    );
  }

  double _lineWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

/// Rules live here, not as chips on the product row.
class _RideRules extends StatelessWidget {
  const _RideRules({
    required this.title,
    required this.rules,
    required this.fare,
  });

  final String title;
  final List<String> rules;
  final String fare;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AlongType.heading(palette)),
        const SizedBox(height: 4),
        Text(fare, style: AlongType.title(palette)),
        const SizedBox(height: 12),
        for (final rule in rules)
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Icon(AlongIcons.info, size: 16, color: palette.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.meta(palette).copyWith(color: palette.ink),
                  ),
                ),
              ],
            ),
          ),
      ],
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
      ('M', 28, false),
      ('Tu', 40, false),
      ('W', 32, false),
      ('Th', 52, true),
      ('F', 44, false),
      ('Sa', 22, false),
      ('Su', 16, false),
    ];
    final axis = AlongType.caption(palette).copyWith(
      fontSize: 10,
      height: 1,
      fontWeight: FontWeight.w600,
      color: palette.muted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 32,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₦9k', maxLines: 1, softWrap: false, style: axis),
                      const Spacer(),
                      Text('₦5k', maxLines: 1, softWrap: false, style: axis),
                      const Spacer(),
                      Text('₦0', maxLines: 1, softWrap: false, style: axis),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              for (final bar in bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(
                          bar.$3 ? 'Best' : '',
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.caption(palette).copyWith(
                            fontSize: 10,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: bar.$2 / 52,
                              widthFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: bar.$3
                                      ? palette.accent
                                      : palette.ink.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                  border: bar.$3
                                      ? Border.all(
                                          color: palette.ink,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bar.$1,
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.caption(palette).copyWith(
                            fontWeight: bar.$3
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: bar.$3 ? palette.ink : palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EarningTrip extends StatelessWidget {
  const _EarningTrip({required this.place, required this.fare, this.tip});

  final String place;
  final String fare;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.recessed,
              shape: BoxShape.circle,
            ),
            child: Icon(AlongIcons.navigate, size: 15, color: palette.ink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              place,
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette).copyWith(
                fontSize: 15,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (tip != null) ...[
            const SizedBox(width: 6),
            Text(
              tip!,
              maxLines: 1,
              softWrap: false,
              style: AlongType.meta(palette).copyWith(
                fontSize: 12,
                height: 1.1,
                color: palette.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Text(
            fare,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.05, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _MapThumb extends StatelessWidget {
  const _MapThumb({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final align = Alignment(-0.8 + (seed % 5) * 0.35, (seed % 3) * 0.3 - 0.3);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 36,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/map/tiles/light/16_34127_31111.png',
              package: 'along_design',
              fit: BoxFit.cover,
              alignment: align,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
            CustomPaint(painter: _ThumbRoute(seed)),
          ],
        ),
      ),
    );
  }
}

class _ThumbRoute extends CustomPainter {
  const _ThumbRoute(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(6, size.height - 8)
      ..quadraticBezierTo(
        size.width * (0.3 + (seed % 3) * 0.1),
        8 + (seed % 2) * 6,
        size.width - 8,
        10 + (seed % 4) * 3,
      );
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width - 8, 10 + (seed % 4) * 3),
      2.5,
      Paint()..color = const Color(0xFFF7D117),
    );
  }

  @override
  bool shouldRepaint(covariant _ThumbRoute oldDelegate) =>
      oldDelegate.seed != seed;
}

class _HeatTip extends StatefulWidget {
  const _HeatTip();

  @override
  State<_HeatTip> createState() => _HeatTipState();
}

class _HeatTipState extends State<_HeatTip> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlongMapButton(
          icon: AlongIcons.info,
          tooltip: 'Heat',
          onPressed: () => setState(() => _open = !_open),
        ),
        if (_open) ...[const SizedBox(height: 8), const _HeatLegend()],
      ],
    );
  }
}

class _TodayPill extends StatefulWidget {
  const _TodayPill();

  @override
  State<_TodayPill> createState() => _TodayPillState();
}

class _TodayPillState extends State<_TodayPill> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(99),
              boxShadow: AlongElevation.float(palette.ink),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                'Today · ₦18,400',
                maxLines: 1,
                softWrap: false,
                style: AlongType.title(palette)
                    .copyWith(fontSize: 15, height: 1.1),
              ),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          Text(
            'Wuse park · 3 seats open',
            maxLines: 1,
            softWrap: false,
            style: AlongType.meta(palette),
          ),
          const SizedBox(height: 8),
          const _GoalRow(),
          const SizedBox(height: 8),
          const AlongButton(
            label: 'Go offline',
            variant: AlongButtonVariant.secondary,
            onPressed: _noop,
          ),
        ],
      ],
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final label = AlongType.meta(palette).copyWith(
      fontSize: 12,
      height: 1.1,
      color: palette.ink,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(99),
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quiet', maxLines: 1, softWrap: false, style: label),
          const SizedBox(width: 8),
          Container(
            width: 108,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2F6F8F),
                  Color(0xFFE39B2B),
                  Color(0xFFB93815),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Busy', maxLines: 1, softWrap: false, style: label),
        ],
      ),
    );
  }
}

/// Puts the whole fictional plate inside the brackets. Cover-fit on a
/// portrait phone was cropping ABC-123-XY down to C-123-X.
class _PlateFrame extends StatelessWidget {
  const _PlateFrame();

  /// Source pixels of plate-abuja.jpg (1040×760) that contain the full plate.
  static const _photoW = 1040.0;
  static const _photoH = 760.0;
  static const _plate = Rect.fromLTRB(250, 400, 760, 540);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final frame = Rect.fromLTWH(
          16,
          size.height * 0.40,
          size.width - 32,
          size.height * 0.20,
        );
        final scale = math.min(
          frame.width / _plate.width,
          frame.height / _plate.height,
        );
        final imageLeft =
            frame.center.dx - (_plate.left + _plate.width / 2) * scale;
        final imageTop =
            frame.center.dy - (_plate.top + _plate.height / 2) * scale;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: imageLeft,
              top: imageTop,
              width: _photoW * scale,
              height: _photoH * scale,
              child: Image.asset(
                'assets/photos/plate-abuja.jpg',
                package: 'along_design',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
            Positioned.fromRect(
              rect: frame.inflate(22),
              child: const _ViewfinderCorners(),
            ),
          ],
        );
      },
    );
  }
}

class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  @override
  Widget build(BuildContext context) {
    const mark = Color(0xFFF7D117);
    Widget corner(Alignment align) {
      final top = align.y < 0;
      final left = align.x < 0;
      return Align(
        alignment: align,
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: top
                  ? const BorderSide(color: mark, width: 3)
                  : BorderSide.none,
              bottom: top
                  ? BorderSide.none
                  : const BorderSide(color: mark, width: 3),
              left: left
                  ? const BorderSide(color: mark, width: 3)
                  : BorderSide.none,
              right: left
                  ? BorderSide.none
                  : const BorderSide(color: mark, width: 3),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        corner(Alignment.topLeft),
        corner(Alignment.topRight),
        corner(Alignment.bottomLeft),
        corner(Alignment.bottomRight),
      ],
    );
  }
}

class _HoldAlert extends StatefulWidget {
  const _HoldAlert();

  @override
  State<_HoldAlert> createState() => _HoldAlertState();
}

class _HoldAlertState extends State<_HoldAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: 0.66,
    );
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    _fill.forward(from: 0);
  }

  void _up(PointerEvent _) {
    if (_fill.value < 1) _fill.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedBuilder(
        animation: _fill,
        builder: (context, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: palette.danger.withValues(alpha: 0.16)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _fill.value.clamp(0.0, 1.0),
                    child: ColoredBox(color: palette.danger),
                  ),
                  Center(
                    child: Text(
                      'Hold to alert',
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.button(palette)
                          .copyWith(color: palette.dangerOn),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlateMatch extends StatelessWidget {
  const _PlateMatch();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Text(
      'Plate matches',
      maxLines: 1,
      softWrap: false,
      style: AlongType.title(palette).copyWith(color: palette.success),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.name,
    required this.detail,
    this.asset,
    this.initials,
  });

  final String name;
  final String detail;
  final String? asset;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          if (asset != null)
            AlongDriverPortrait(size: 44, asset: asset!, verified: true)
          else
            _Monogram(initials: initials ?? '', size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette)
                      .copyWith(fontSize: 16, height: 1.1),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.meta(palette),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 22, color: palette.muted),
        ],
      ),
    );
  }
}

class _RuleStrip extends StatelessWidget {
  const _RuleStrip();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: const Row(
        children: [
          _RuleTile(icon: AlongIcons.navigate, value: '400 m', label: 'Route'),
          _RuleTile(icon: AlongIcons.schedule, value: '3 min', label: 'Stop'),
          _RuleTile(icon: AlongIcons.shield, value: '15 min', label: 'Ping'),
          _RuleTile(icon: AlongIcons.verified, value: 'Set', label: 'Word'),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: palette.ink),
          Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette)
                .copyWith(fontWeight: FontWeight.w700, color: palette.ink),
          ),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AlongType.meta(palette),
          ),
        ],
      ),
    );
  }
}

class _PassStack extends StatelessWidget {
  const _PassStack();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 18,
            right: 18,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 56),
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Change credit',
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.title(palette)
                          .copyWith(color: palette.accentInk, fontSize: 16),
                    ),
                  ),
                  Text(
                    '₦6,400',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.numeric(palette).copyWith(
                      fontSize: 18,
                      color: palette.accentInk,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(top: 48, left: 0, right: 0, child: _BalanceCard()),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: palette.ink,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 26,
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Text(
                'Along',
                maxLines: 1,
                softWrap: false,
                style: AlongType.caption(
                  palette,
                ).copyWith(color: palette.onInk, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Ride credit',
            maxLines: 1,
            softWrap: false,
            style: AlongType.meta(palette).copyWith(color: palette.onInk),
          ),
          Text(
            '₦1,200',
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 36, color: palette.onInk),
          ),
          Text(
            'Locked for Chinedu',
            maxLines: 1,
            softWrap: false,
            style: AlongType.meta(palette)
                .copyWith(color: palette.accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _WalletTiles extends StatelessWidget {
  const _WalletTiles();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _IconTile(icon: AlongIcons.earnings, label: 'Top up'),
        SizedBox(width: 8),
        _IconTile(icon: AlongIcons.share, label: 'Send'),
        SizedBox(width: 8),
        _IconTile(icon: AlongIcons.receipt, label: 'Card'),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Expanded(
      child: Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AlongElevation.card(palette.ink),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: palette.ink),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AlongType.caption(palette)
                  .copyWith(fontWeight: FontWeight.w700, color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosPanel extends StatelessWidget {
  const _SosPanel();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AlongElevation.float(palette.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goes to', style: AlongType.title(palette)),
          const SizedBox(height: 8),
          const Row(
            children: [
              _IconTile(icon: AlongIcons.shield, label: 'Mum'),
              SizedBox(width: 8),
              _IconTile(icon: AlongIcons.shield, label: 'Chidi'),
              SizedBox(width: 8),
              _IconTile(icon: AlongIcons.share, label: 'Share'),
              SizedBox(width: 8),
              _IconTile(icon: AlongIcons.call, label: 'Call'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreditNote extends StatelessWidget {
  const _CreditNote();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Row(
        children: [
          Icon(AlongIcons.wallet, color: palette.ink, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change stays as credit',
                  style: AlongType.title(palette)
                      .copyWith(fontSize: 16, height: 1.15),
                ),
                Text(
                  'We do not round the fare up.',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.meta(palette),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette)
                      .copyWith(fontSize: 16, height: 1.1),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.meta(palette),
                ),
              ],
            ),
          ),
          Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.1, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    const days = ['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'];
    const dots = [true, true, false, true, true, false, true];
    return Row(
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: days[i] == 'Th' ? palette.ink : palette.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    days[i],
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.caption(palette).copyWith(
                      fontWeight: FontWeight.w700,
                      color: days[i] == 'Th' ? palette.onInk : palette.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dots[i] ? palette.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayTimeline extends StatelessWidget {
  const _DayTimeline();

  @override
  Widget build(BuildContext context) {
    const stops = <(String, String)>[
      ('Wuse to Nyanya', '₦1,400'),
      ('Berger to Garki', '₦900'),
      ('Jabi to Wuse', '₦1,200'),
      ('Nyanya to Wuse', '₦1,600'),
      ('Garki to Jabi', '₦700'),
      ('Wuse to Berger', '₦1,100'),
      ('Airport to Wuse', '₦2,400'),
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (var i = 0; i < stops.length; i++)
          _DayStop(
            title: stops[i].$1,
            fare: stops[i].$2,
            last: i == stops.length - 1,
            seed: i,
          ),
        const _Fold(
          label: 'Week and seats',
          child: Column(
            children: [
              _WeekStrip(),
              SizedBox(height: 8),
              SizedBox(
                height: 108,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: AlongCityMap(mode: AlongCityMapMode.routeHero),
                ),
              ),
              _DayRuns(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayStop extends StatelessWidget {
  const _DayStop({
    required this.title,
    required this.fare,
    required this.last,
    required this.seed,
  });

  final String title;
  final String fare;
  final bool last;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: last ? palette.muted : palette.ink,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: palette.line)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _MapThumb(seed: seed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              style: AlongType.title(palette)
                  .copyWith(fontSize: 16, height: 1.1),
            ),
          ),
          Text(
            fare,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.1, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _DayRuns extends StatelessWidget {
  const _DayRuns();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _RunCard(route: 'Wuse to Nyanya', seats: '4 of 6', fare: '₦1,400'),
        _RunCard(route: 'Berger to Garki', seats: '6 of 6', fare: '₦900'),
        _RunCard(route: 'Jabi to Wuse', seats: '3 of 6', fare: '₦1,200'),
        _RunCard(route: 'Nyanya to Wuse', seats: '5 of 6', fare: '₦1,600'),
        _RunCard(route: 'Garki to Jabi', seats: '2 of 6', fare: '₦700'),
        _RunCard(route: 'Wuse to Berger', seats: '4 of 6', fare: '₦1,100'),
        _RunCard(route: 'Airport to Wuse', seats: '6 of 6', fare: '₦2,400'),
      ],
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.route,
    required this.seats,
    required this.fare,
  });

  final String route;
  final String seats;
  final String fare;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.title(palette)
                      .copyWith(fontSize: 16, height: 1.1),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  height: 16,
                  width: double.infinity,
                  child: _MiniRoute(),
                ),
                Text(
                  seats,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.meta(palette),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fare,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette)
                .copyWith(fontSize: 16, height: 1.1, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _MiniRoute extends StatelessWidget {
  const _MiniRoute();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return CustomPaint(
      painter: _MiniRoutePainter(ink: palette.ink, accent: palette.accent),
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  _MiniRoutePainter({required this.ink, required this.accent});

  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(2, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.1,
        size.width * 0.62,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.9,
        size.width - 2,
        size.height * 0.25,
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
    canvas.drawCircle(Offset(2, size.height * 0.7), 2.5, Paint()..color = ink);
    canvas.drawCircle(
      Offset(size.width - 2, size.height * 0.25),
      2.5,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter oldDelegate) => false;
}

class _CountdownRing extends StatefulWidget {
  const _CountdownRing({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  State<_CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<_CountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      value: widget.progress,
    );
    if (!AlongMotionPolicy.inWidgetTest) {
      _spin.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) {
          final t = AlongMotionPolicy.inWidgetTest
              ? widget.progress
              : _spin.value;
          return CustomPaint(
            painter: _RingPainter(
              progress: t,
              track: palette.line.withValues(alpha: 0.25),
              ink: palette.accent,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: AlongType.numeric(palette).copyWith(fontSize: 20),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BidRow extends StatelessWidget {
  const _BidRow({
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.eta,
    required this.fare,
    this.rider = false,
    this.initials,
    this.best = false,
  });

  final String name;
  final String rating;
  final String vehicle;
  final String eta;
  final String fare;
  final bool rider;
  final String? initials;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: best ? palette.accent.withValues(alpha: 0.28) : null,
          borderRadius: BorderRadius.circular(14),
          border: best
              ? Border.all(
                  color: palette.ink.withValues(alpha: 0.35),
                  width: 1.5,
                )
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: best ? 8 : 0,
            vertical: best ? 6 : 0,
          ),
          child: Row(
            children: [
              if (initials != null)
                _Monogram(initials: initials!, size: 40)
              else
                AlongDriverPortrait(
                  size: 40,
                  asset: rider
                      ? AlongDriverPortrait.adaeze
                      : AlongDriverPortrait.chinedu,
                  verified: true,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.title(palette)
                          .copyWith(fontSize: 16, height: 1.1),
                    ),
                    Text(
                      '$rating · $vehicle · $eta',
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.meta(palette).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fare,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.numeric(palette)
                        .copyWith(fontSize: 16, height: 1.1, letterSpacing: 0),
                  ),
                  const SizedBox(height: 4),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        best ? 'Best' : 'Accept',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.caption(palette).copyWith(
                          color: palette.accentInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: palette.ink, shape: BoxShape.circle),
      child: Text(
        initials,
        maxLines: 1,
        softWrap: false,
        style: AlongType.caption(palette)
            .copyWith(color: palette.onInk, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MapDriver extends StatelessWidget {
  const _MapDriver({required this.name, required this.eta, this.rider = false});

  final String name;
  final String eta;
  final bool rider;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      children: [
        AlongDriverPortrait(
          size: 36,
          asset: rider
              ? AlongDriverPortrait.adaeze
              : AlongDriverPortrait.chinedu,
          verified: true,
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AlongElevation.float(palette.ink),
          ),
          child: Text(
            '$name · $eta',
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
        ),
      ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              AlongIcons.star,
              size: i < filled ? size : size * 0.86,
              color: i < filled ? palette.accent : palette.line,
            ),
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
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.ink : palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? palette.ink
                : palette.line.withValues(alpha: 0.35),
          ),
          boxShadow: selected ? AlongElevation.card(palette.ink) : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AlongType.meta(palette).copyWith(
            color: selected ? palette.onInk : palette.ink,
            fontWeight: FontWeight.w700,
            height: 1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
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
      width: 220,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
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
          const AlongVehicleMark(kind: AlongVehicleKind.keke, width: 96),
          const Positioned(
            left: 4,
            top: 18,
            child: _MapDriver(name: 'Chinedu', eta: '4 min'),
          ),
          const Positioned(
            right: 4,
            bottom: 16,
            child: _MapDriver(name: 'Adaeze', eta: '6 min', rider: true),
          ),
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
