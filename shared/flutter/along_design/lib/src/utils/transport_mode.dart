import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Along transport modes (doc 05 §2).
enum TransportMode { car, keke, okada, minibus }

extension TransportModeTokens on TransportMode {
  Color get fillColor => switch (this) {
        TransportMode.car => AlongColors.modeCar,
        TransportMode.keke => AlongColors.modeKeke,
        TransportMode.okada => AlongColors.modeOkada,
        TransportMode.minibus => AlongColors.modeMinibus,
      };

  Color get onColor => switch (this) {
        TransportMode.car => AlongColors.modeCarOn,
        TransportMode.keke => AlongColors.modeKekeOn,
        TransportMode.okada => AlongColors.modeOkadaOn,
        TransportMode.minibus => AlongColors.modeMinibusOn,
      };

  Color get tintColor => switch (this) {
        TransportMode.car => AlongColors.modeCarTint,
        TransportMode.keke => AlongColors.modeKekeTint,
        TransportMode.okada => AlongColors.modeOkadaTint,
        TransportMode.minibus => AlongColors.modeMinibusTint,
      };

  String get label => switch (this) {
        TransportMode.car => 'Car',
        TransportMode.keke => 'Keke',
        TransportMode.okada => 'Okada',
        TransportMode.minibus => 'Minibus',
      };

  IconData get icon => switch (this) {
        TransportMode.car => Icons.directions_car_rounded,
        TransportMode.keke => Icons.electric_rickshaw_rounded,
        TransportMode.okada => Icons.two_wheeler_rounded,
        TransportMode.minibus => Icons.directions_bus_rounded,
      };
}
