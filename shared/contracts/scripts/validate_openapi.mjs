#!/usr/bin/env node
/** Validate openapi.yaml (OpenAPI 3.1) before CI handler check. */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { bundle, createConfig } from '@redocly/openapi-core';

const __dirname = dirname(fileURLToPath(import.meta.url));
const openapiPath = join(__dirname, '..', 'openapi.yaml');

try {
  const config = await createConfig({});
  const { bundle: docWrap } = await bundle({ ref: openapiPath, config });
  const doc = docWrap.parsed;
  if (!doc.openapi?.startsWith('3.1')) {
    console.error('FAIL: openapi.yaml must declare OpenAPI 3.1.x');
    process.exit(1);
  }
  const paths = Object.keys(doc.paths ?? {});
  if (paths.length === 0) {
    console.error('FAIL: openapi.yaml has no paths');
    process.exit(1);
  }
  console.log(`PASS: OpenAPI 3.1 valid (${paths.length} paths).`);
} catch (err) {
  console.error('FAIL: OpenAPI validation error:', err.message ?? err);
  process.exit(1);
}
