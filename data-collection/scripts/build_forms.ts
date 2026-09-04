#!/usr/bin/env node
/**
 * Build ODK/Kobo XLSForms from definitions + exported choice lists (doc 13 §2).
 */

import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildParkForm, buildRouteForm, type ChoiceRow } from './lib/form_defs.ts';
import { writeXlsxForm } from './lib/xlsx.ts';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CHOICES_DIR = join(ROOT, 'forms', 'choices');
const FORMS_DIR = join(ROOT, 'forms');

function loadChoices(filename: string): ChoiceRow[] {
  const path = join(CHOICES_DIR, filename);
  if (!existsSync(path)) return [];
  const lines = readFileSync(path, 'utf8').trim().split('\n');
  if (lines.length <= 1) return [];
  return lines.slice(1).map((line) => {
    const [list_name, name, label] = line.split(',');
    return { list_name: list_name!, name: name!, label: label ?? name! };
  });
}

const corridorChoices = loadChoices('corridors.csv');
const parkChoices = loadChoices('parks.csv');

writeXlsxForm(join(FORMS_DIR, 'along_park_v1.xlsx'), buildParkForm(corridorChoices));
writeXlsxForm(join(FORMS_DIR, 'along_route_v1.xlsx'), buildRouteForm(parkChoices, corridorChoices));

console.log('Built forms/along_park_v1.xlsx and forms/along_route_v1.xlsx');
