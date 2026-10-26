import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

/// The driver's home sheet: online state, today's money and one big GO.
/// Pure: everything comes in through [state] and callbacks, so goldens can
/// render the real thing without the native map.
class DriverHomePanel extends StatelessWidget {
  const DriverHomePanel({
    super.key,
    required this.state,
    required this.onGo,
    required this.onGoOffline,
    required this.onMode,
    required this.onPark,
    required this.onSeats,
    required this.onDirection,
    required this.onBuildDay,
    required this.onConductor,
    required this.onRest,
    required this.onMarketplace,
    this.todayEarned,
    this.todayTrips,
    this.errorText,
  });

  final DriverHomeState state;
  final String? todayEarned;
  final int? todayTrips;
  final String? errorText;
  final VoidCallback onGo;
  final VoidCallback onGoOffline;
  final ValueChanged<DriverStatus> onMode;
  final VoidCallback onPark;
  final VoidCallback onSeats;
  final VoidCallback? onDirection;
  final VoidCallback onBuildDay;
  final VoidCallback onConductor;
  final VoidCallback onRest;
  final VoidCallback onMarketplace;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final online = state.isOnline;
    final enabled = state.toggleEnabled;
    final demand = state.demandLabels.isEmpty ? null : state.demandLabels.first;

    return DriveSheet(
      key: const Key('driver_home_panel'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: AlongMoves.select.of(context),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: online ? p.success : p.muted,
                        ),
                      ),
                      const SizedBox(width: AlongSpace.s8),
                      Expanded(
                        child: Text(
                          online ? l10n.homeOnlineTitle : l10n.homeOfflineTitle,
                          key: const Key('home_status_title'),
                          style: AlongType.title(p),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AlongSpace.s4),
                  if (online && demand != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DriveTag(
                        key: const Key('home_demand'),
                        icon: AlongIcons.online,
                        label: demand,
                      ),
                    )
                  else
                    Text(
                      online ? l10n.homeOnlineHint : l10n.homeOfflineHint,
                      style: AlongType.bodyMuted(p),
                    ),
                  const SizedBox(height: AlongSpace.s12),
                  DrivePanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AlongSpace.s16,
                      vertical: AlongSpace.s12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.homeTodayEarned(todayEarned ?? '—'),
                                key: const Key('home_today_earned'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AlongType.label(p).copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              if (todayTrips != null)
                                Text(
                                  l10n.homeTodayTrips(todayTrips!),
                                  style: AlongType.caption(p),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (online) ...[
                    const SizedBox(height: AlongSpace.s12),
                    _ModeSegment(
                      key: const Key('driver_status_toggle'),
                      selected: state.status,
                      enabled: enabled,
                      labels: {
                        DriverStatus.atPark: l10n.homeModeAtPark,
                        DriverStatus.roamingAvailable: l10n.homeModeRoaming,
                        DriverStatus.roamingFull: l10n.homeModeFull,
                      },
                      onChanged: onMode,
                    ),
                    if (state.status == DriverStatus.atPark) ...[
                      const SizedBox(height: AlongSpace.s8),
                      _RowButton(
                        key: const Key('home_park'),
                        icon: AlongIcons.mapPin,
                        label: state.selectedPark == null
                            ? l10n.homeSelectPark
                            : l10n.homeAtPark(state.selectedPark!.name),
                        onTap: onPark,
                      ),
                    ],
                    if (state.isRoaming) ...[
                      const SizedBox(height: AlongSpace.s8),
                      Row(
                        children: [
                          Expanded(
                            child: _RowButton(
                              key: const Key('driver_seat_map_chip'),
                              icon: AlongIcons.seat,
                              label:
                                  '${l10n.activeTripSeatsShort} · ${state.seatsAvailable}',
                              onTap: onSeats,
                            ),
                          ),
                          const SizedBox(width: AlongSpace.s8),
                          Expanded(
                            child: _RowButton(
                              key: const Key('home_direction'),
                              icon: AlongIcons.signpost,
                              label:
                                  state.roamingDirection ==
                                      RoamingDirection.onRoute
                                  ? l10n.homeDirectionShortOnRoute
                                  : l10n.homeDirectionShortNone,
                              onTap: onDirection,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: AlongSpace.s12),
                  Text(l10n.homeShortcutsTitle, style: AlongType.caption(p)),
                  const SizedBox(height: AlongSpace.s8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        for (final (i, (key, icon, label, onTap))
                            in <(String, IconData, String, VoidCallback)>[
                              (
                                'build_my_day_button',
                                AlongIcons.schedule,
                                l10n.buildMyDayTitle,
                                onBuildDay,
                              ),
                              (
                                'conductor_entry_button',
                                AlongIcons.user,
                                l10n.conductorTitle,
                                onConductor,
                              ),
                              (
                                'rest_entry_button',
                                AlongIcons.history,
                                l10n.restTitle,
                                onRest,
                              ),
                              (
                                'marketplace_entry_button',
                                AlongIcons.storefront,
                                l10n.homeTileDemand,
                                onMarketplace,
                              ),
                            ].indexed) ...[
                          if (i > 0) const SizedBox(width: AlongSpace.s8),
                          _Shortcut(
                            key: Key(key),
                            icon: icon,
                            label: label,
                            onTap: onTap,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AlongSpace.s8),
                    Text(
                      errorText!,
                      style: AlongType.caption(p).copyWith(color: p.danger),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AlongSpace.s16),
          if (!online)
            AlongButton(
              key: const Key('home_go'),
              label: l10n.homeGoOnline,
              onPressed: enabled
                  ? () {
                      AlongHaptics.confirm(context);
                      onGo();
                    }
                  : null,
            )
          else
            AlongButton(
              key: const Key('home_go_offline'),
              label: l10n.homeGoOffline,
              variant: AlongButtonVariant.secondary,
              onPressed: enabled ? onGoOffline : null,
            ),
        ],
      ),
    );
  }
}

/// Three-way mode switch for an online driver; squircle, 52 px targets.
class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    super.key,
    required this.selected,
    required this.enabled,
    required this.labels,
    required this.onChanged,
  });

  final DriverStatus selected;
  final bool enabled;
  final Map<DriverStatus, String> labels;
  final ValueChanged<DriverStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: AlongCraft.compactFill(p.recessed, 60, corner: 18),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final MapEntry(key: status, value: label) in labels.entries)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: status == selected,
                    label: label,
                    child: GestureDetector(
                      key: Key('home_mode_${status.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: enabled && status != selected
                          ? () {
                              AlongHaptics.selection(context);
                              onChanged(status);
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: AlongMoves.select.of(context),
                        curve: AlongMoves.select.curve,
                        constraints: const BoxConstraints(minHeight: 52),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: AlongCraft.compactFill(
                          status == selected ? p.ink : p.recessed,
                          52,
                          corner: 14,
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AlongType.label(p).copyWith(
                            color: status == selected ? p.onInk : p.ink,
                          ),
                        ),
                      ),
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

class _RowButton extends StatelessWidget {
  const _RowButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Material(
      color: Colors.transparent,
      shape: AlongCraft.border(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                AlongHaptics.tick(context);
                onTap!();
              },
        child: Ink(
          decoration: AlongCraft.compactFill(p.recessed, 52, corner: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              AlongIcon(icon, size: 20, color: onTap == null ? p.muted : p.ink),
              const SizedBox(width: AlongSpace.s8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AlongType.label(p),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline notice for the top of the home map; dark-safe.
class DriverHomeNotice extends StatelessWidget {
  const DriverHomeNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(
        p,
        radius: 16,
        color: p.ink,
        shadow: AlongElevation.sheet(p.ink),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s12),
        child: Row(
          children: [
            AlongIcon(AlongIcons.info, size: 18, color: p.onInk),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: Text(
                message,
                style: AlongType.body(p).copyWith(color: p.onInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          shape: AlongCraft.border(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              AlongHaptics.tick(context);
              onTap();
            },
            child: Ink(
              decoration: AlongCraft.compactFill(p.recessed, 48, corner: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlongIcon(icon, size: 18, color: p.ink),
                  const SizedBox(width: AlongSpace.s8),
                  Text(label, style: AlongType.label(p)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
