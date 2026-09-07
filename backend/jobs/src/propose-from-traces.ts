import type {
  MatchedTraceRecord,
  TraceActorType,
  TraceProposal,
  TraceSample,
} from './types.js';

export type RawTraceInput = {
  tripId: string;
  actorType: TraceActorType;
  samples: TraceSample[];
};

export type ProposeFromTracesInput = {
  traces: RawTraceInput[];
  matchedByTripActor: ReadonlyMap<string, MatchedTraceRecord>;
  minConfidence: number;
};

function traceKey(tripId: string, actorType: TraceActorType): string {
  return `${tripId}:${actorType}`;
}

/**
 * FM27 guard — raw trip_location_samples must never produce geometry/route proposals.
 * Downstream inference jobs (P7-A-03/A-04) call this entrypoint with matched_traces only.
 */
export function proposeFromTraces(input: ProposeFromTracesInput): TraceProposal[] {
  for (const trace of input.traces) {
    if (trace.samples.length === 0) {
      continue;
    }

    const matched = input.matchedByTripActor.get(
      traceKey(trace.tripId, trace.actorType),
    );
    if (!matched || matched.confidence < input.minConfidence) {
      return [];
    }
  }

  // Inference not implemented in P7-A-02 — matched traces pass the FM27 gate only.
  return [];
}
