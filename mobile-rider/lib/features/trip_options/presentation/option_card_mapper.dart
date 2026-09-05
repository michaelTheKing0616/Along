import 'package:along_core/along_core.dart' as core;
import 'package:along_design/along_design.dart' as design;
import 'package:along_design/along_design.dart' show FareTier;
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';

/// Maps [PlanCandidate] fields to [OptionCard] presentation props.
class OptionCardMapper {
  const OptionCardMapper._();

  static design.TransportMode mapMode(core.TransportMode mode) =>
      switch (mode) {
        core.TransportMode.car => design.TransportMode.car,
        core.TransportMode.keke => design.TransportMode.keke,
        core.TransportMode.okada => design.TransportMode.okada,
        core.TransportMode.minibus => design.TransportMode.minibus,
      };

  static FareTier mapFareTier(core.FareTier tier, {required bool unconfirmed}) {
    if (unconfirmed || tier == core.FareTier.unconfirmed) {
      return FareTier.estimate;
    }
    return switch (tier) {
      core.FareTier.driverProfile || core.FareTier.throughFare =>
        FareTier.verified,
      core.FareTier.summedLegs => FareTier.crowd,
      core.FareTier.unconfirmed => FareTier.estimate,
    };
  }

  static String metaForCandidate(core.PlanCandidate candidate) {
    final leg = candidate.legs.first;
    final walkMin = (leg.walkSeconds / 60).ceil();
    final waitMin = (leg.waitSeconds / 60).ceil();
    if (candidate.isDirect) {
      return '$walkMin min walk · ~$waitMin min wait · direct';
    }
    if (candidate.transferCount > 0) {
      return '$walkMin min walk · ${candidate.transferCount} transfer'
          '${candidate.transferCount == 1 ? '' : 's'}';
    }
    return '$walkMin min walk · ~$waitMin min wait';
  }

  static bool hasLoadCapacityWarning(
    core.PlanCandidate candidate,
    LoadFlagState load,
  ) {
    if (!load.flagged || load.size == null) return false;
    return candidate.legs.any((leg) => leg.loadWarning != null);
  }
}
