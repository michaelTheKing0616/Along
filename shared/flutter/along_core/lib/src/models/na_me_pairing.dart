import 'dart:math';

import 'package:collection/collection.dart';

/// Na Me identification pairing (§4.8) — cached locally for offline trigger.
class NaMePairing {
  const NaMePairing({
    required this.colorToken,
    required this.shape,
    required this.label,
    this.tripId,
  });

  final String colorToken;
  final String shape;
  final String label;
  final String? tripId;

  factory NaMePairing.fromJson(Map<String, dynamic> json) => NaMePairing(
        colorToken: json['color_token'] as String,
        shape: json['shape'] as String,
        label: json['label'] as String,
        tripId: json['trip_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'color_token': colorToken,
        'shape': shape,
        'label': label,
        if (tripId != null) 'trip_id': tripId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NaMePairing &&
          colorToken == other.colorToken &&
          shape == other.shape &&
          label == other.label &&
          tripId == other.tripId;

  @override
  int get hashCode => Object.hash(colorToken, shape, label, tripId);
}

/// A color/shape pair already assigned to an active trip.
typedef NaMePairInUse = ({String colorToken, String shape});

/// Picks a Na Me pairing from server-provided palette config (not hardcoded).
NaMePairing pickNaMePairing({
  required List<String> colorPalette,
  required List<String> shapePalette,
  required Set<NaMePairInUse> inUse,
  required String Function(String colorToken, String shape) labelBuilder,
  Random? random,
}) {
  if (colorPalette.isEmpty || shapePalette.isEmpty) {
    throw ArgumentError('Na Me palette must be non-empty');
  }

  final rng = random ?? Random();
  final usedColors = inUse.map((p) => p.colorToken).toSet();
  final availableColors =
      colorPalette.where((c) => !usedColors.contains(c)).toList();
  final colors = availableColors.isNotEmpty ? availableColors : colorPalette;

  final candidates = <NaMePairing>[];
  for (final color in colors) {
    for (final shape in shapePalette) {
      final taken = inUse.any(
        (p) => p.colorToken == color && p.shape == shape,
      );
      if (!taken) {
        candidates.add(
          NaMePairing(
            colorToken: color,
            shape: shape,
            label: labelBuilder(color, shape),
          ),
        );
      }
    }
  }

  if (candidates.isEmpty) {
    throw StateError('No Na Me pairings available in palette');
  }

  return candidates[rng.nextInt(candidates.length)];
}

/// Parses in-use pairs from TripView `na_me` maps on active trips.
Set<NaMePairInUse> parseInUsePairs(Iterable<Map<String, dynamic>> activeNaMeMaps) {
  return activeNaMeMaps
      .map(
        (m) => (
          colorToken: m['color_token'] as String,
          shape: m['shape'] as String,
        ),
      )
      .toSet();
}

/// Orders pairings by label for stable display.
List<NaMePairing> sortPairingsByLabel(List<NaMePairing> pairings) =>
    pairings.sortedBy((p) => p.label.toLowerCase());
