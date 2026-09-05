import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-05 banner when location permission is denied (doc 06).
class LocationDeniedBanner extends StatelessWidget {
  const LocationDeniedBanner({
    super.key,
    this.onChooseOnMap,
  });

  final VoidCallback? onChooseOnMap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: AlongColors.brandYellowTint,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlongSpace.s16,
            vertical: AlongSpace.s12,
          ),
          child: Row(
            children: [
              Icon(Icons.location_off_outlined, color: AlongColors.ink900),
              const SizedBox(width: AlongSpace.s8),
              Expanded(
                child: Text(
                  l10n.homeLocationDeniedBanner,
                  style: AlongText.bodyStrong.copyWith(color: AlongColors.ink900),
                ),
              ),
              if (onChooseOnMap != null)
                TextButton(
                  key: const Key('location_denied_choose_map'),
                  onPressed: onChooseOnMap,
                  child: Text(l10n.homeChooseOnMap),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
