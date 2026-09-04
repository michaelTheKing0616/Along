#!/usr/bin/env node
/**
 * Minimal JSON Schema → Dart emitter for shared contract $defs (ADR-0016).
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const pkgRoot = join(__dirname, '..');
const repoRoot = join(pkgRoot, '../..');
const outPath = join(
  repoRoot,
  'shared/flutter/along_data/lib/src/contracts/api_contracts.g.dart',
);

const PRIMITIVE_ALIASES = new Set([
  'Uuid',
  'IsoDateTime',
  'GeoAccuracyM',
  'CursorLimit',
  'CountBucket',
  'ErrorCode',
  'FareTier',
  'FareComponentKind',
]);

const sources = [
  join(pkgRoot, 'schemas/common.json'),
  ...[
    'auth',
    'ambient',
    'trips',
    'presence',
    'ledger',
    'safety',
    'itinerary',
    'graph',
    'admin',
  ].map((n) => join(pkgRoot, `schemas/rpc/${n}.json`)),
];

/** @type {Map<string, object>} */
const defs = new Map();

for (const path of sources) {
  const schema = JSON.parse(readFileSync(path, 'utf8'));
  for (const [name, def] of Object.entries(schema.$defs ?? {})) {
    defs.set(name, def);
  }
}

/** @param {string} name */
function dartClassName(name) {
  return name.replace(/[^A-Za-z0-9]/g, '');
}

/** @param {unknown} schema @param {string} hint @param {boolean} inline */
function resolveSchema(schema, hint = 'Value', inline = false) {
  if (!schema || typeof schema !== 'object') return { dart: 'Object?', kind: 'object' };
  if (Object.keys(schema).length === 0) {
    return { dart: 'Object?', kind: 'object' };
  }
  if ('$ref' in schema) {
    const refName = String(schema.$ref).split('/').pop() ?? 'Object';
    if (PRIMITIVE_ALIASES.has(refName)) return primitiveAlias(refName);
    return { dart: dartClassName(refName), kind: 'class', refName };
  }
  if ('oneOf' in schema) {
    const nonNull = schema.oneOf.filter((s) => s.type !== 'null');
    if (nonNull.length === 1) return resolveSchema(nonNull[0], hint);
    return { dart: 'Object?', kind: 'object' };
  }
  if ('allOf' in schema) {
    for (const part of schema.allOf) {
      const resolved = resolveSchema(part, hint);
      if (resolved.kind !== 'unknown') return resolved;
    }
  }
  if ('enum' in schema) {
    if (schema.type === 'integer') return { dart: 'int', kind: 'primitive' };
    return { dart: 'String', kind: 'primitive' };
  }
  switch (schema.type) {
    case 'string':
      return { dart: 'String', kind: 'primitive' };
    case 'integer':
      return { dart: 'int', kind: 'primitive' };
    case 'number':
      return { dart: 'double', kind: 'primitive' };
    case 'boolean':
      return { dart: 'bool', kind: 'primitive' };
    case 'array': {
      const itemSchema = schema.items ?? {};
      if (
        itemSchema.type === 'object' &&
        itemSchema.properties &&
        !itemSchema.$ref
      ) {
        return { dart: 'List<Map<String, dynamic>>', kind: 'list' };
      }
      const inner = resolveSchema(itemSchema, hint + 'Item', true);
      return { dart: `List<${inner.dart}>`, kind: 'list', inner };
    }
    case 'object':
      if (schema.additionalProperties && typeof schema.additionalProperties === 'object') {
        return { dart: 'Map<String, dynamic>', kind: 'map' };
      }
      if (inline && schema.properties && Object.keys(schema.properties).length > 0) {
        return { dart: 'Map<String, dynamic>', kind: 'map' };
      }
      if (!schema.properties || Object.keys(schema.properties).length === 0) {
        return { dart: 'Map<String, dynamic>', kind: 'map' };
      }
      return { dart: dartClassName(hint), kind: 'class' };
    default:
      return { dart: 'Object?', kind: 'object' };
  }
}

/** @param {string} name */
function primitiveAlias(name) {
  switch (name) {
    case 'Uuid':
    case 'IsoDateTime':
    case 'CountBucket':
    case 'ErrorCode':
    case 'FareComponentKind':
      return { dart: 'String', kind: 'primitive' };
    case 'FareTier':
    case 'CursorLimit':
      return { dart: 'int', kind: 'primitive' };
    case 'GeoAccuracyM':
      return { dart: 'double', kind: 'primitive' };
    default:
      return { dart: 'Object?', kind: 'object' };
  }
}

/** @param {object} schema */
function collectProperties(schema) {
  /** @type {Record<string, unknown>} */
  const props = {};
  /** @type {Set<string>} */
  const required = new Set(schema.required ?? []);
  if (schema.properties) Object.assign(props, schema.properties);
  if (schema.allOf) {
    for (const part of schema.allOf) {
      if (part.$ref) {
        const refName = String(part.$ref).split('/').pop();
        const refDef = defs.get(refName);
        if (refDef) {
          Object.assign(props, collectProperties(refDef).props);
          collectProperties(refDef).required.forEach((r) => required.add(r));
        }
      }
      if (part.properties) Object.assign(props, part.properties);
      if (part.required) part.required.forEach((r) => required.add(r));
    }
  }
  return { props, required };
}

/** @param {string} name @param {object} schema */
function shouldEmitClass(name, schema) {
  if (PRIMITIVE_ALIASES.has(name)) return false;
  if (schema.type === 'array') return false;
  if ('oneOf' in schema) return false;
  const { props } = collectProperties(schema);
  if (Object.keys(props).length === 0) return false;
  return schema.type === 'object' || schema.properties || schema.allOf;
}

/** @param {string} dartType @param {string} jsonKey @param {boolean} nullable */
function fromJsonExpr(dartType, jsonKey, nullable) {
  const key = JSON.stringify(jsonKey);
  const access = `json[${key}]`;
  if (dartType === 'String') {
    return nullable ? `${access} as String?` : `${access} as String`;
  }
  if (dartType === 'int') {
    return nullable ? `(${access} as num?)?.toInt()` : `(${access} as num).toInt()`;
  }
  if (dartType === 'double') {
    return nullable ? `(${access} as num?)?.toDouble()` : `(${access} as num).toDouble()`;
  }
  if (dartType === 'bool') {
    return nullable ? `${access} as bool?` : `${access} as bool`;
  }
  if (dartType === 'List<Map<String, dynamic>>') {
    return nullable
      ? `${access} == null ? null : (${access} as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList()`
      : `(${access} as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList()`;
  }
  if (dartType.startsWith('List<String>')) {
    const cast = nullable ? '?.cast<String>()' : '.cast<String>()';
    return nullable
      ? `${access} == null ? null : (${access} as List<dynamic>)${cast}`
      : `(${access} as List<dynamic>)${cast}`;
  }
  if (dartType.startsWith('List<int>')) {
    return nullable
      ? `${access} == null ? null : (${access} as List<dynamic>).map((e) => (e as num).toInt()).toList()`
      : `(${access} as List<dynamic>).map((e) => (e as num).toInt()).toList()`;
  }
  if (dartType.startsWith('List<double>')) {
    return nullable
      ? `${access} == null ? null : (${access} as List<dynamic>).map((e) => (e as num).toDouble()).toList()`
      : `(${access} as List<dynamic>).map((e) => (e as num).toDouble()).toList()`;
  }
  if (dartType.startsWith('List<')) {
    const inner = dartType.slice(5, -1);
    return nullable
      ? `${access} == null ? null : (${access} as List<dynamic>).map((e) => ${inner}.fromJson(e as Map<String, dynamic>)).toList()`
      : `(${access} as List<dynamic>).map((e) => ${inner}.fromJson(e as Map<String, dynamic>)).toList()`;
  }
  if (dartType.startsWith('Map<String,')) {
    return nullable
      ? `${access} == null ? null : Map<String, dynamic>.from(${access} as Map)`
      : `Map<String, dynamic>.from(${access} as Map)`;
  }
  if (dartType === 'Object?') {
    return access;
  }
  return nullable
    ? `${access} == null ? null : ${dartType}.fromJson(${access} as Map<String, dynamic>)`
    : `${dartType}.fromJson(${access} as Map<String, dynamic>)`;
}

/** @param {string} dartType @param {string} prop */
function toJsonExpr(dartType, prop) {
  if (dartType === 'List<Map<String, dynamic>>') return prop;
  if (['String', 'int', 'double', 'bool', 'Object?'].includes(dartType) || dartType.startsWith('Map<')) {
    return prop;
  }
  if (dartType.startsWith('List<String>') || dartType.startsWith('List<int>') || dartType.startsWith('List<double>')) {
    return prop;
  }
  if (dartType.startsWith('List<')) {
    return `${prop}?.map((e) => e.toJson()).toList()`;
  }
  return `${prop}?.toJson()`;
}

/** @param {string} dart @param {boolean} nullable */
function fieldType(dart, nullable) {
  if (!nullable) return dart;
  if (dart.endsWith('?')) return dart;
  return `${dart}?`;
}

/** @param {string} name @param {object} schema */
function emitClass(name, schema) {
  if (!shouldEmitClass(name, schema)) return '';
  const className = dartClassName(name);
  const { props, required } = collectProperties(schema);
  const lines = [`class ${className} {`];

  for (const [prop, propSchema] of Object.entries(props)) {
    const hint = className + prop[0].toUpperCase() + prop.slice(1);
    const resolved = resolveSchema(propSchema, hint, true);
    const nullable = !required.has(prop);
    lines.push(`  final ${fieldType(resolved.dart, nullable)} ${prop};`);
  }

  lines.push('');
  lines.push(`  const ${className}({`);
  for (const prop of Object.keys(props)) {
    const nullable = !required.has(prop);
    lines.push(`    ${nullable ? 'this.' : 'required this.'}${prop},`);
  }
  lines.push('  });');
  lines.push('');
  lines.push(`  factory ${className}.fromJson(Map<String, dynamic> json) {`);
  lines.push(`    return ${className}(`);
  for (const [prop, propSchema] of Object.entries(props)) {
    const hint = className + prop[0].toUpperCase() + prop.slice(1);
    const resolved = resolveSchema(propSchema, hint, true);
    const nullable = !required.has(prop);
    lines.push(`      ${prop}: ${fromJsonExpr(resolved.dart, prop, nullable)},`);
  }
  lines.push('    );');
  lines.push('  }');
  lines.push('');
  lines.push('  Map<String, dynamic> toJson() => {');
  for (const [prop, propSchema] of Object.entries(props)) {
    const hint = className + prop[0].toUpperCase() + prop.slice(1);
    const resolved = resolveSchema(propSchema, hint, true);
    lines.push(`    ${JSON.stringify(prop)}: ${toJsonExpr(resolved.dart, prop)},`);
  }
  lines.push('  };');
  lines.push('}');
  return lines.join('\n');
}

const header = `// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated by shared/contracts/scripts/generate_dart.mjs (P1-A-02)
// ignore_for_file: non_constant_identifier_names, prefer_single_quotes, prefer_typing_uninitialized_variables

`;

const body = [...defs.keys()]
  .sort()
  .map((name) => emitClass(name, defs.get(name)))
  .filter(Boolean)
  .join('\n\n');

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, `${header}${body}\n`);
console.log(`Wrote ${outPath} (${body ? body.split('\nclass ').length - 1 : 0} Dart classes).`);
