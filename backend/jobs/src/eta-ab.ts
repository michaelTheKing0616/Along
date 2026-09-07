export type EtaAbFixtureLeg = {
  segmentKeys: string[];
  baseInVehicleS: number;
  actualDurationS: number;
  profileMedianSpeedMps: number;
};

export type EtaAbResult = {
  maeBaselineS: number;
  maeProfileS: number;
  improvementPct: number;
  legs: Array<{
    actualDurationS: number;
    baselineEstimateS: number;
    profileEstimateS: number;
  }>;
};

export function meanAbsoluteError(estimates: number[], actuals: number[]): number {
  if (estimates.length !== actuals.length || estimates.length === 0) {
    return Number.POSITIVE_INFINITY;
  }
  const total = estimates.reduce(
    (sum, est, i) => sum + Math.abs(est - actuals[i]!),
    0,
  );
  return total / estimates.length;
}

/** Mirrors planner calibrateInVehicleS (doc 04 §4.4). */
function calibrateInVehicleS(
  baseInVehicleS: number,
  medianSpeedMps: number,
  sampleCount: number,
  cfg: { baselineSpeedMps: number; speedProfileMinSamples: number },
): number {
  if (
    baseInVehicleS <= 0 ||
    sampleCount < cfg.speedProfileMinSamples ||
    medianSpeedMps <= 0 ||
    cfg.baselineSpeedMps <= 0
  ) {
    return baseInVehicleS;
  }
  return Math.max(
    1,
    Math.round(baseInVehicleS * (cfg.baselineSpeedMps / medianSpeedMps)),
  );
}

export function estimateLegWithProfiles(
  baseInVehicleS: number,
  segmentKeys: string[],
  profileMedianSpeedMps: number,
  sampleCount: number,
  cfg: { baselineSpeedMps: number; speedProfileMinSamples: number },
): number {
  void segmentKeys;
  return calibrateInVehicleS(
    baseInVehicleS,
    profileMedianSpeedMps,
    sampleCount,
    cfg,
  );
}

export function runEtaAbReport(
  legs: EtaAbFixtureLeg[],
  cfg: { baselineSpeedMps: number; speedProfileMinSamples: number },
): EtaAbResult {
  const actuals = legs.map((leg) => leg.actualDurationS);
  const baselineEstimates = legs.map((leg) => leg.baseInVehicleS);
  const profileEstimates = legs.map((leg) =>
    estimateLegWithProfiles(
      leg.baseInVehicleS,
      leg.segmentKeys,
      leg.profileMedianSpeedMps,
      cfg.speedProfileMinSamples,
      cfg,
    ),
  );

  const maeBaselineS = meanAbsoluteError(baselineEstimates, actuals);
  const maeProfileS = meanAbsoluteError(profileEstimates, actuals);
  const improvementPct = maeBaselineS > 0
    ? Math.round(((maeBaselineS - maeProfileS) / maeBaselineS) * 1000) / 10
    : 0;

  return {
    maeBaselineS: Math.round(maeBaselineS * 10) / 10,
    maeProfileS: Math.round(maeProfileS * 10) / 10,
    improvementPct,
    legs: legs.map((leg, i) => ({
      actualDurationS: leg.actualDurationS,
      baselineEstimateS: baselineEstimates[i]!,
      profileEstimateS: profileEstimates[i]!,
    })),
  };
}
