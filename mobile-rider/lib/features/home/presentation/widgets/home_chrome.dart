import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/home/presentation/widgets/home_bottom_sheet.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Everything on home above the map: map buttons, the greeting, and the
/// Where-to sheet. Kept apart from the native map so goldens render it.
class HomeChrome extends StatelessWidget {
  const HomeChrome({
    super.key,
    required this.state,
    required this.now,
    required this.onMenu,
    required this.onVehicles,
    required this.onRecenter,
    required this.onSearch,
    required this.onRecent,
    required this.onNearby,
    this.banner,
  });

  final HomeState state;
  final DateTime now;
  final VoidCallback onMenu;
  final VoidCallback onVehicles;
  final VoidCallback? onRecenter;
  final VoidCallback onSearch;
  final ValueChanged<RecentPlace> onRecent;
  final ValueChanged<NearbyAmbientRow> onNearby;

  /// Location banner, pinned under the status bar.
  final Widget? banner;

  static AlongDayPhase phaseAt(DateTime t) => switch (t.hour) {
    >= 5 && < 12 => AlongDayPhase.morning,
    >= 12 && < 17 => AlongDayPhase.afternoon,
    >= 17 && < 22 => AlongDayPhase.evening,
    _ => AlongDayPhase.night,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = phaseAt(now);
    final greeting = switch (phase) {
      AlongDayPhase.morning => l10n.homeGreetingMorning,
      AlongDayPhase.afternoon => l10n.homeGreetingAfternoon,
      AlongDayPhase.evening => l10n.homeGreetingEvening,
      AlongDayPhase.night => l10n.homeGreetingNight,
    };
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?banner,
              Padding(
                padding: const EdgeInsets.all(AlongSpace.s16),
                child: Row(
                  children: [
                    AlongMapButton(
                      key: const Key('home_menu_button'),
                      tooltip: l10n.homeMenu,
                      onPressed: onMenu,
                      icon: AlongIcons.menu,
                    ),
                    const SizedBox(width: AlongSpace.s8),
                    AlongMapButton(
                      key: const Key('home_vehicles_button'),
                      tooltip: l10n.homeVehicles,
                      onPressed: onVehicles,
                      icon: AlongIcons.seat,
                    ),
                    const Spacer(),
                    AlongMapButton(
                      key: const Key('home_recenter_button'),
                      tooltip: l10n.homeRecenter,
                      onPressed: onRecenter,
                      icon: AlongIcons.locate,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: AlongSpace.s16, right: 72),
                child: AlongGreeting(
                  key: const Key('home_greeting'),
                  phase: phase,
                  title: greeting,
                  detail: state.cityName,
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          top: null,
          child: AlongSpringSheet(
            shrinkWrap: true,
            child: HomePeekSheet(
              state: state,
              onSearchTap: onSearch,
              onRecentTap: onRecent,
              onNearbyTap: onNearby,
            ),
          ),
        ),
      ],
    );
  }
}
