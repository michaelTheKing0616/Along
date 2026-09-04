/**
 * ODK XLSForm definitions (doc 13 §2).
 */

import type { SheetRow } from './xlsx.ts';

export interface ChoiceRow {
  list_name: string;
  name: string;
  label: string;
}

export function parkFormChoices(extra: ChoiceRow[] = []): ChoiceRow[] {
  return [
    { list_name: 'modes', name: 'car', label: 'Along taxi' },
    { list_name: 'modes', name: 'keke', label: 'Keke' },
    { list_name: 'modes', name: 'okada', label: 'Okada' },
    { list_name: 'modes', name: 'minibus', label: 'Minibus' },
    ...extra,
  ];
}

export function routeFormChoices(extra: ChoiceRow[] = []): ChoiceRow[] {
  return [
    { list_name: 'modes', name: 'car', label: 'Along taxi' },
    { list_name: 'modes', name: 'keke', label: 'Keke' },
    { list_name: 'modes', name: 'okada', label: 'Okada' },
    { list_name: 'modes', name: 'minibus', label: 'Minibus' },
    { list_name: 'yes_no', name: 'yes', label: 'Yes' },
    { list_name: 'yes_no', name: 'no', label: 'No' },
    ...extra,
  ];
}

export function buildParkForm(corridorChoices: ChoiceRow[] = []): {
  survey: SheetRow[];
  choices: SheetRow[];
  settings: SheetRow[];
} {
  const choices = parkFormChoices(corridorChoices);
  return {
    settings: [
      {
        form_title: 'Along Park Survey',
        form_id: 'along_park_v1',
        version: '1',
        default_language: 'English',
        style: 'field-list',
      },
    ],
    choices: choices.map((c) => ({ list_name: c.list_name, name: c.name, label: c.label })),
    survey: [
      { type: 'start', name: 'start' },
      { type: 'note', name: 'intro', label: 'Record a park as locals name it. GPS ≥30s average, accuracy ≤10m.' },
      { type: 'hidden', name: 'form_version', default: '1' },
      { type: 'text', name: 'park_name', label: 'Park name (local)', required: 'yes' },
      {
        type: 'begin repeat',
        name: 'aliases',
        label: 'Aliases',
      },
      { type: 'text', name: 'alias', label: 'Alias name' },
      { type: 'end repeat', name: 'aliases' },
      { type: 'geopoint', name: 'location', label: 'GPS location', required: 'yes', appearance: 'maps' },
      { type: 'select_multiple modes', name: 'modes', label: 'Modes present', required: 'yes' },
      { type: 'time', name: 'hours_from', label: 'Opens at' },
      { type: 'time', name: 'hours_to', label: 'Closes at' },
      { type: 'image', name: 'photo', label: 'Signage / landmark photo' },
      { type: 'text', name: 'notes', label: 'Notes' },
      { type: 'select_one corridors', name: 'corridor_id', label: 'Corridor', required: 'yes' },
      { type: 'text', name: 'scout_id', label: 'Scout profile UUID', required: 'yes' },
      { type: 'end', name: 'end' },
    ],
  };
}

export function buildRouteForm(parkChoices: ChoiceRow[] = [], corridorChoices: ChoiceRow[] = []): {
  survey: SheetRow[];
  choices: SheetRow[];
  settings: SheetRow[];
} {
  const choices = routeFormChoices([...parkChoices, ...corridorChoices]);
  return {
    settings: [
      {
        form_title: 'Along Route Survey',
        form_id: 'along_route_v1',
        version: '1',
        default_language: 'English',
        style: 'field-list',
      },
    ],
    choices: choices.map((c) => ({ list_name: c.list_name, name: c.name, label: c.label })),
    survey: [
      { type: 'start', name: 'start' },
      { type: 'note', name: 'intro', label: 'Record one mode on one corridor end-to-end. Quote standard fares, not haggled prices.' },
      { type: 'hidden', name: 'form_version', default: '1' },
      { type: 'select_one corridors', name: 'corridor_id', label: 'Corridor', required: 'yes' },
      { type: 'select_one modes', name: 'mode', label: 'Mode', required: 'yes' },
      { type: 'select_one parks', name: 'origin_park', label: 'Origin park', required: 'yes' },
      { type: 'select_one parks', name: 'destination_park', label: 'Destination park', required: 'yes' },
      { type: 'begin repeat', name: 'stage', label: 'Stages (in order)' },
      { type: 'text', name: 'stage_name', label: 'Stage name (local)', required: 'yes' },
      { type: 'geopoint', name: 'location', label: 'Stage GPS', required: 'yes' },
      { type: 'select_one yes_no', name: 'is_official_park', label: 'Official park?', required: 'yes' },
      { type: 'decimal', name: 'price_to_end', label: 'Fare from here to route end (quoted standard)', required: 'yes' },
      { type: 'text', name: 'price_currency', label: 'Currency', default: 'NGN' },
      { type: 'end repeat', name: 'stage' },
      { type: 'begin repeat', name: 'through_fares', label: 'Known through-fares (optional)' },
      { type: 'integer', name: 'from_stage_seq', label: 'From stage #' },
      { type: 'integer', name: 'to_stage_seq', label: 'To stage #' },
      { type: 'decimal', name: 'fare', label: 'Through fare' },
      { type: 'end repeat', name: 'through_fares' },
      { type: 'integer', name: 'frequency_peak_per_hour', label: 'Vehicles/hour (peak)' },
      { type: 'integer', name: 'frequency_offpeak_per_hour', label: 'Vehicles/hour (off-peak)' },
      { type: 'integer', name: 'typical_wait_min', label: 'Typical wait (minutes)' },
      { type: 'file', name: 'gpx', label: 'GPX trace (one full ride)', appearance: 'nosubmit' },
      { type: 'text', name: 'notes', label: 'Notes' },
      { type: 'text', name: 'scout_id', label: 'Scout profile UUID', required: 'yes' },
      { type: 'end', name: 'end' },
    ],
  };
}
