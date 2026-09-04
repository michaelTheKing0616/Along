#!/usr/bin/env node
/**
 * Style Dictionary build → Dart + CSS + Tailwind preset (P0-E-05).
 * Copies generated artifacts to along_design and admin-console.
 */
import { cpSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import StyleDictionary from 'style-dictionary';
import config from '../style-dictionary.config.mjs';
import { registerAlongFormats } from './formats.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const pkgRoot = join(__dirname, '..');
const repoRoot = join(pkgRoot, '../..');

registerAlongFormats(StyleDictionary);

const sd = new StyleDictionary(config);
await sd.buildAllPlatforms();

const copies = [
  {
    from: join(pkgRoot, 'build/dart/along_tokens.dart'),
    to: join(repoRoot, 'shared/flutter/along_design/lib/src/tokens.g.dart'),
  },
  {
    from: join(pkgRoot, 'build/css/tokens.css'),
    to: join(repoRoot, 'admin-console/src/styles/tokens.css'),
  },
  {
    from: join(pkgRoot, 'build/tailwind/preset.cjs'),
    to: join(repoRoot, 'admin-console/tailwind.preset.cjs'),
  },
];

for (const { from, to } of copies) {
  mkdirSync(dirname(to), { recursive: true });
  cpSync(from, to);
}

console.log('Design tokens built and copied to along_design + admin-console.');
