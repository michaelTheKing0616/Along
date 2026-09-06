import 'package:along_core/along_core.dart' as core;
import 'package:along_design/along_design.dart' as design;
import 'package:along_design/along_design.dart' show FareTier;

FareTier designFareTier(core.FareTier tier, {required bool unconfirmed}) {
  if (unconfirmed || tier == core.FareTier.unconfirmed) {
    return FareTier.estimate;
  }
  return switch (tier) {
    core.FareTier.driverProfile || core.FareTier.throughFare => FareTier.verified,
    core.FareTier.summedLegs => FareTier.crowd,
    core.FareTier.unconfirmed => FareTier.estimate,
  };
}

design.TransportMode designMode(String code) => switch (code) {
      'keke' => design.TransportMode.keke,
      'okada' => design.TransportMode.okada,
      'minibus' => design.TransportMode.minibus,
      _ => design.TransportMode.car,
    };

List<int> fareConfirmChipAmounts(int centerNaira) {
  final step = centerNaira >= 1000 ? 100 : 50;
  final lower = (centerNaira - step).clamp(0, centerNaira);
  final upper = centerNaira + step;
  return [lower, centerNaira, upper];
}
