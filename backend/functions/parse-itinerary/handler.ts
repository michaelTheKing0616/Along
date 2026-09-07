import { z } from 'zod';
import type { SupabaseClient } from '@supabase/supabase-js';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createUserClient } from '../_shared/supabase.ts';

export const parseItineraryRequestSchema = z.object({
  text: z.string().min(3),
  city_id: z.string().uuid(),
  voice_transcript_id: z.string().uuid().optional(),
});

export type ParseItineraryRequest = z.infer<typeof parseItineraryRequestSchema>;

export type ParsedStop = {
  sequence: number;
  destination_description: string;
  location?: { lat: number; lng: number };
};

export type ParseItineraryProposalItem = {
  sequence: number;
  destination_description: string;
  resolved: {
    label: string;
    location: { lat: number; lng: number };
    confidence: number;
  } | null;
};

export type ParseItineraryDeps = {
  user?: ReturnType<typeof createUserClient>;
  /** Optional spy client — parse-itinerary must never write via service client. */
  service?: SupabaseClient;
};

const JSON_STOPS_RE = /^\s*\[/;

function splitNaturalLanguage(text: string): string[] {
  const normalized = text.trim();
  if (JSON_STOPS_RE.test(normalized)) {
    try {
      const parsed = JSON.parse(normalized) as unknown;
      if (Array.isArray(parsed)) {
        return parsed.map((item) => {
          if (typeof item === 'string') return item.trim();
          if (item && typeof item === 'object' && 'destination_description' in item) {
            return String((item as { destination_description: string }).destination_description).trim();
          }
          return String(item).trim();
        }).filter(Boolean);
      }
    } catch {
      // fall through to NL split
    }
  }

  return normalized
    .split(/\s+then\s+|\s*,\s*|\s*;\s*|\s+and then\s+/i)
    .map((part) => part.trim())
    .filter((part) => part.length > 0);
}

/** Bounded deterministic parser — no external LLM/STT (doc 03 §3, P5-A-03). */
export function parseItineraryText(text: string): ParsedStop[] {
  const parts = splitNaturalLanguage(text);
  return parts.map((description, index) => ({
    sequence: index + 1,
    destination_description: description,
  }));
}

function toProposal(stops: ParsedStop[]): ParseItineraryProposalItem[] {
  return stops.map((stop) => ({
    sequence: stop.sequence,
    destination_description: stop.destination_description,
    resolved: stop.location
      ? {
        label: stop.destination_description,
        location: stop.location,
        confidence: 0.5,
      }
      : null,
  }));
}

export async function handleParseItinerary(
  req: ParseItineraryRequest,
  authHeader: string,
  deps?: ParseItineraryDeps,
): Promise<Response> {
  const rid = requestId();

  const userClient = deps?.user ?? createUserClient(authHeader);
  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, {
      request_id: rid,
    });
  }

  // STT is a documented no-op unless voice_transcript_id resolves elsewhere (no speech SDK).
  if (req.voice_transcript_id) {
    // Bounded stub: voice path not wired; client must send text.
  }

  const stops = parseItineraryText(req.text);
  if (stops.length === 0) {
    return errorResponse('VALIDATION', 'Could not parse any stops from text', 400, {
      request_id: rid,
    });
  }

  const proposal = toProposal(stops);

  return jsonResponse(
    {
      data: {
        proposal,
        needs_confirmation: true,
      },
      meta: { request_id: rid },
    },
    200,
    { 'Access-Control-Allow-Origin': '*' },
  );
}
