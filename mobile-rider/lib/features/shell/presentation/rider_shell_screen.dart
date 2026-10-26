import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Bottom nav shell — Home / Trips / Account (doc 06 R-05).
class RiderShellScreen extends StatelessWidget {
  const RiderShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AlongPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: navigationShell,
      bottomNavigationBar: ColoredBox(
        color: palette.surface,
        child: SafeArea(
          top: false,
          child: AlongTabBar(
            key: const Key('rider_tab_bar'),
            index: navigationShell.currentIndex,
            tabs: [
              (AlongIcons.home, l10n.navHome),
              (AlongIcons.path, l10n.navTrips),
              (AlongIcons.user, l10n.navAccount),
            ],
            onSelect: navigationShell.goBranch,
          ),
        ),
      ),
    );
  }
}
