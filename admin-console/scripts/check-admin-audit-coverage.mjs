#!/usr/bin/env node
/**
 * P6-D-04 AC grep: Phase ≤6 admin WRITE RPCs vs audit coverage.
 * Covered = trigger on table OR explicit audit_log insert in RPC body.
 * Known gaps are listed explicitly for P6-A-01 (exit 0 with GAP lines).
 */
import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '../..');
const migrationsDir = path.join(repoRoot, 'backend/db/migrations');
const catalogPath = path.join(__dirname, 'admin-audit-coverage.json');

const catalog = JSON.parse(readFileSync(catalogPath, 'utf8'));
const migrationSql = readdirSync(migrationsDir)
  .filter((f) => f.endsWith('.sql'))
  .sort()
  .map((f) => readFileSync(path.join(migrationsDir, f), 'utf8'))
  .join('\n');

function hasTrigger(table) {
  const re = new RegExp(`create trigger audit_[\\w\\s]+ on ${table}\\b`, 'i');
  return re.test(migrationSql);
}

function rpcBody(rpcName) {
  const re = new RegExp(
    `create or replace function ${rpcName}\\([\\s\\S]*?\\$\\$;`,
    'i'
  );
  const match = migrationSql.match(re);
  return match?.[0] ?? '';
}

const covered = [];
const gaps = [];
const missing = [];

for (const entry of catalog.write_rpcs) {
  const { name, audit } = entry;
  if (audit.kind === 'gap') {
    gaps.push({ name, reason: audit.reason });
    continue;
  }

  if (audit.kind === 'trigger') {
    if (hasTrigger(audit.table)) {
      covered.push({ name, via: `trigger:${audit.table}` });
    } else {
      missing.push({ name, expected: `trigger:${audit.table}` });
    }
    continue;
  }

  if (audit.kind === 'explicit') {
    const body = rpcBody(name);
    const pattern = new RegExp(audit.pattern, 'i');
    if (body && pattern.test(body)) {
      covered.push({ name, via: 'explicit audit_log' });
    } else if (pattern.test(migrationSql)) {
      covered.push({ name, via: 'explicit audit_log (migration)' });
    } else {
      missing.push({ name, expected: audit.pattern });
    }
  }
}

console.log('Admin write RPC audit coverage (Phase ≤6)');
console.log(`Covered: ${covered.length}`);
for (const row of covered) {
  console.log(`  OK  ${row.name} — ${row.via}`);
}

console.log(`Explicit gaps (P6-A-01 / deferred): ${gaps.length}`);
for (const row of gaps) {
  console.log(`  GAP ${row.name} — ${row.reason}`);
}

if (missing.length > 0) {
  console.error(`Unexpected missing coverage: ${missing.length}`);
  for (const row of missing) {
    console.error(`  FAIL ${row.name} — expected ${row.expected}`);
  }
  process.exit(1);
}

console.log('PASS: all non-gap admin write RPCs have audit coverage evidence');
