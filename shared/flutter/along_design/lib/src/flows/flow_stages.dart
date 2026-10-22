import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../components/seat_map.dart';
import '../icons.dart';
import '../palette.dart';
import '../type.dart';
import 'map_sketch.dart';
import 'spring_sheet.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Along', style: AlongType.heading(palette)),
          const SizedBox(height: 28),
          Text('Move around. Your way.', style: AlongType.display(palette)),
          const SizedBox(height: 12),
          Text(
            legacyCopy
                ? 'Enter your number to continue'
                : 'We text a code to this number so the ride stays yours.',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 24),
          _Field(
            child: Row(
              children: [
                Text('+234', style: AlongType.title(palette)),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: palette.line,
                ),
                Expanded(
                  child: Text(
                    '801 234 5678',
                    style: AlongType.bodyMuted(palette),
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

class AlongFlowHome extends StatelessWidget {
  const AlongFlowHome({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(child: AlongMapSketch()),
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
            child: AlongSpringSheet(fraction: 0.40, child: _HomeSheetBody()),
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
              Icon(AlongIcons.search, color: palette.muted, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Where to?', style: AlongType.body(palette)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _ModeChip(label: 'Keke', selected: true),
              SizedBox(width: 8),
              _ModeChip(label: 'Okada'),
              SizedBox(width: 8),
              _ModeChip(label: 'Car'),
              SizedBox(width: 8),
              _ModeChip(label: 'Bus'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Wuse to Nyanya', style: AlongType.bodyMuted(palette)),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Text(
                '₦1,200',
                style: AlongType.numeric(palette).copyWith(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(
              width: 128,
              child: AlongButton(
                label: 'See rides',
                onPressed: _noop,
                fullWidth: true,
              ),
            ),
          ],
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
          const SizedBox(height: 8),
          Text('Hiace · ABC-123-XY', style: AlongType.bodyMuted(palette)),
          const SizedBox(height: 20),
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
                    status: 'free',
                    statusWord: 'Open',
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
            ],
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
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          Positioned.fill(child: AlongRouteMotion(progress: progress)),
          const Positioned(
            top: 16,
            left: 16,
            child: AlongMapButton(icon: AlongIcons.shield, tooltip: 'Safety'),
          ),
          Positioned.fill(
            child: AlongSpringSheet(
              fraction: 0.36,
              child: _LiveSheet(palette: palette),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSheet extends StatelessWidget {
  const _LiveSheet({required this.palette});

  final AlongPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('On the way', style: AlongType.heading(palette)),
        const SizedBox(height: 4),
        Text('Chinedu · ABC-123-XY', style: AlongType.bodyMuted(palette)),
        const SizedBox(height: 8),
        Text('6 min', style: AlongType.numeric(palette).copyWith(fontSize: 28)),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: AlongButton(
                label: 'Share trip',
                variant: AlongButtonVariant.secondary,
                onPressed: _noop,
              ),
            ),
            const SizedBox(width: 8),
            _AlertMark(color: palette.danger, iconColor: palette.dangerOn),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AlongIcons.sos, color: palette.danger, size: 36),
          const SizedBox(height: 16),
          Text('We stay with you', style: AlongType.display(palette)),
          const SizedBox(height: 12),
          Text(
            'Hold the button to alert the people you chose. Your location goes with the alert.',
            style: AlongType.body(palette),
          ),
          const SizedBox(height: 20),
          Text('Adaeze · Mum', style: AlongType.title(palette)),
          Text('Chidi · Brother', style: AlongType.bodyMuted(palette)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guardian', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text(
            'A check-in on this ride, only when you ask for it.',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check the plate', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text(
            'Fit the plate in the frame. You can still ride if the camera stays off.',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1916),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Container(
                  width: 220,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.accent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ABC-123-XY',
                    style: AlongType.title(palette)
                        .copyWith(color: palette.accent),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pay Chinedu', style: AlongType.display(palette)),
          const SizedBox(height: 8),
          Text('₦1,200', style: AlongType.numeric(palette)),
          const SizedBox(height: 4),
          Text(
            'Amount locked to this trip',
            style: AlongType.bodyMuted(palette),
          ),
          const SizedBox(height: 20),
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
    return _Page(
      bottom: const AlongButton(label: 'Save the day', onPressed: _noop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build my day',
            style: AlongType.display(AlongPalette.of(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Abuja, morning run',
            style: AlongType.bodyMuted(AlongPalette.of(context)),
          ),
          const SizedBox(height: 20),
          const _RuleRow(label: 'Vehicle', value: 'Hiace'),
          const _RuleRow(label: 'Corridor', value: 'Nyanya'),
          const _RuleRow(label: 'Seats', value: '14'),
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
          const Positioned.fill(child: AlongMapSketch()),
          Positioned.fill(
            child: AlongSpringSheet(
              fraction: 0.38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: palette.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('You are online', style: AlongType.heading(palette)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Wuse park · 3 seats open',
                    style: AlongType.bodyMuted(palette),
                  ),
                  const Spacer(),
                  Text(
                    '₦12,400',
                    style: AlongType.numeric(palette).copyWith(fontSize: 28),
                  ),
                  Text('Today', style: AlongType.bodyMuted(palette)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('New ride', style: AlongType.display(palette)),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.ink, width: 2),
                  ),
                  child: Center(
                    child: Text('12', style: AlongType.title(palette)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Wuse Market to Nyanya', style: AlongType.title(palette)),
          const SizedBox(height: 8),
          Text('₦1,800', style: AlongType.numeric(palette)),
          const SizedBox(height: 4),
          Text('2 seats · 6 min away', style: AlongType.bodyMuted(palette)),
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
      bottom: const AlongButton(label: 'Settle', onPressed: _noop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today', style: AlongType.bodyMuted(palette)),
          const SizedBox(height: 4),
          Text('₦48,200', style: AlongType.numeric(palette)),
          const SizedBox(height: 4),
          Text('11 trips', style: AlongType.bodyMuted(palette)),
          const SizedBox(height: 20),
          const _RuleRow(label: 'Nyanya', value: '₦1,800'),
          const _RuleRow(label: 'Wuse', value: '₦1,200'),
          const _RuleRow(label: 'Garki', value: '₦900'),
        ],
      ),
    );
  }
}

class _AlertMark extends StatelessWidget {
  const _AlertMark({required this.color, required this.iconColor});

  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _noop,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(AlongIcons.sos, color: iconColor),
        ),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: child),
              const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: fill ?? palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: child,
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? palette.accent : palette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? palette.accentInk : palette.line),
      ),
      child: Text(
        label,
        style: AlongType.title(palette).copyWith(
          color: selected ? palette.accentInk : palette.ink,
          fontSize: 16,
        ),
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
          Text(value, style: AlongType.title(palette)),
        ],
      ),
    );
  }
}

void _noop() {}
