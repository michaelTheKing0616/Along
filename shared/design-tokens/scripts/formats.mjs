/** Custom Style Dictionary formats for Along (doc 05 §10–11). */

/** @param {string} path */
function camelCase(path) {
  return path
    .split(/[./_-]/)
    .filter(Boolean)
    .map((part, i) =>
      i === 0
        ? part.replace(/[^a-zA-Z0-9]/g, '')
        : part.charAt(0).toUpperCase() + part.slice(1).replace(/[^a-zA-Z0-9]/g, ''),
    )
    .join('');
}

/** @param {string} hex */
function hexToFlutterColor(hex) {
  const clean = hex.replace('#', '').toUpperCase();
  if (clean.length === 6) {
    return `0xFF${clean}`;
  }
  if (clean.length === 8) {
    return `0x${clean}`;
  }
  return null;
}

/** @param {string} value */
function parseRgba(value) {
  const m = value.match(
    /rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+))?\s*\)/,
  );
  if (!m) return null;
  const r = Number(m[1]);
  const g = Number(m[2]);
  const b = Number(m[3]);
  const a = m[4] !== undefined ? Math.round(Number(m[4]) * 255) : 255;
  const argb = ((a << 24) | (r << 16) | (g << 8) | b) >>> 0;
  return `0x${argb.toString(16).toUpperCase().padStart(8, '0')}`;
}

/** @param {import('style-dictionary/types').TransformedToken} token */
function flutterColorValue(token) {
  const v = String(token.$value ?? token.value);
  if (v.startsWith('#')) {
    return hexToFlutterColor(v);
  }
  if (v.startsWith('rgba') || v.startsWith('rgb')) {
    return parseRgba(v);
  }
  return null;
}

/** @param {number} weight */
function fontWeightDart(weight) {
  const map = {
    400: 'FontWeight.w400',
    500: 'FontWeight.w500',
    600: 'FontWeight.w600',
    700: 'FontWeight.w700',
    800: 'FontWeight.w800',
  };
  return map[weight] ?? `FontWeight.w${weight}`;
}

/** @param {import('style-dictionary/types').TransformedToken} token */
function typographyDart(token) {
  const t = token.$value ?? token.value;
  const parts = [];
  parts.push(`fontFamily: 'Inter'`);
  let fontSizePx = 16;
  if (t.fontSize) {
    fontSizePx = parseFloat(String(t.fontSize));
    parts.push(`fontSize: ${fontSizePx}`);
  }
  if (t.lineHeight && t.fontSize) {
    const lh = parseFloat(String(t.lineHeight));
    parts.push(`height: ${lh / fontSizePx}`);
  }
  if (t.fontWeight) {
    parts.push(`fontWeight: ${fontWeightDart(Number(t.fontWeight))}`);
  }
  if (t.letterSpacing) {
    const ls = String(t.letterSpacing);
    if (ls.endsWith('em')) {
      const absolute = parseFloat(ls) * fontSizePx;
      parts.push(`letterSpacing: ${absolute}`);
    } else {
      parts.push(`letterSpacing: ${parseFloat(ls)}`);
    }
  }
  if (Array.isArray(t.fontFeatures) && t.fontFeatures.includes('tnum')) {
    parts.push(`fontFeatures: const [FontFeature.tabularFigures()]`);
  }
  return parts.join(', ');
}

/** @param {import('style-dictionary/types').Dictionary} dictionary */
function groupTokens(dictionary, prefix) {
  return dictionary.allTokens.filter((t) => t.path[0] === prefix);
}

export function registerAlongFormats(StyleDictionary) {
  StyleDictionary.registerFormat({
    name: 'along/flutter-dart',
    format({ dictionary }) {
      const colors = groupTokens(dictionary, 'color');
      const spaces = groupTokens(dictionary, 'space');
      const radii = groupTokens(dictionary, 'radius');
      const sizes = groupTokens(dictionary, 'size');
      const motions = groupTokens(dictionary, 'motion');
      const typography = groupTokens(dictionary, 'typography');

      const colorLines = colors
        .map((t) => {
          const name = camelCase(t.path.slice(1).join('-'));
          const val = flutterColorValue(t);
          if (!val) return null;
          return `  static const ${name} = Color(${val});`;
        })
        .filter(Boolean);

      const spaceLines = [...spaces, ...sizes].map((t) => {
        const name =
          t.path[0] === 'size'
            ? camelCase(['size', ...t.path.slice(1)].join('-'))
            : `s${t.path[1]}`;
        const px = parseFloat(String(t.$value ?? t.value));
        return `  static const ${name} = ${px}.0;`;
      });

      const radiusLines = radii.map((t) => {
        const name = t.path[1];
        const px = parseFloat(String(t.$value ?? t.value));
        if (name === 'pill') {
          return `  static const ${name} = Radius.circular(${px});`;
        }
        return `  static const ${name} = Radius.circular(${px});`;
      });

      const motionLines = motions.map((t) => {
        const name = camelCase(t.path.slice(1).join('-'));
        const ms = parseFloat(String(t.$value ?? t.value));
        return `  static const ${name} = Duration(milliseconds: ${ms});`;
      });

      const typoLines = typography.map((t) => {
        const name = camelCase(t.path.slice(1).join('-'));
        return `  static TextStyle get ${name} => TextStyle(${typographyDart(t)});`;
      });

      return `// GENERATED — do not edit. Run: pnpm --filter @along/design-tokens build

import 'package:flutter/material.dart';

/// Generated colour tokens (doc 05 §2).
class AlongColors {
  AlongColors._();
${colorLines.join('\n')}
}

/// Generated spacing and sizing tokens (doc 05 §4).
class AlongSpace {
  AlongSpace._();
${spaceLines.join('\n')}
}

/// Generated corner radii (doc 05 §4).
class AlongRadius {
  AlongRadius._();
${radiusLines.join('\n')}
}

/// Generated motion durations (doc 05 §5).
class AlongMotion {
  AlongMotion._();
${motionLines.join('\n')}
}

/// Generated typography styles (doc 05 §3).
class AlongText {
  AlongText._();
${typoLines.join('\n')}
}
`;
    },
  });

  StyleDictionary.registerFormat({
    name: 'along/css-variables',
    format({ dictionary }) {
      const lines = [':root {'];
      for (const token of dictionary.allTokens) {
        const cssVar = `--${token.path.join('-')}`;
        const val = token.$value ?? token.value;
        if (typeof val === 'object' && val !== null) {
          continue;
        }
        lines.push(`  ${cssVar}: ${val};`);
      }

      lines.push('');
      lines.push('  /* shadcn/ui semantic aliases */');
      lines.push('  --background: var(--color-surface-0);');
      lines.push('  --foreground: var(--color-ink-900);');
      lines.push('  --card: var(--color-surface-0);');
      lines.push('  --card-foreground: var(--color-ink-900);');
      lines.push('  --primary: var(--color-ink-900);');
      lines.push('  --primary-foreground: var(--color-surface-0);');
      lines.push('  --secondary: var(--color-surface-100);');
      lines.push('  --secondary-foreground: var(--color-ink-900);');
      lines.push('  --muted: var(--color-surface-50);');
      lines.push('  --muted-foreground: var(--color-ink-500);');
      lines.push('  --accent: var(--color-brand-yellow-tint);');
      lines.push('  --accent-foreground: var(--color-brand-yellow-on);');
      lines.push('  --destructive: var(--color-semantic-danger-fill);');
      lines.push('  --destructive-foreground: var(--color-surface-0);');
      lines.push('  --border: var(--color-ink-100);');
      lines.push('  --input: var(--color-ink-100);');
      lines.push('  --ring: var(--color-ink-900);');
      lines.push('  --radius: var(--radius-sm);');
      lines.push('');
      lines.push('  /* Legacy admin-console aliases (P0-E-05 migration) */');
      lines.push('  --color-bg: var(--color-surface-50);');
      lines.push('  --color-surface: var(--color-surface-0);');
      lines.push('  --color-border: var(--color-ink-100);');
      lines.push('  --color-text: var(--color-ink-900);');
      lines.push('  --color-text-muted: var(--color-ink-500);');
      lines.push('  --color-primary: var(--color-mode-car);');
      lines.push('  --color-primary-hover: var(--color-ink-700);');
      lines.push('  --color-danger: var(--color-semantic-danger-fill);');
      lines.push('  --color-danger-bg: var(--color-semantic-danger-tint);');
      lines.push('  --font-sans: Inter, system-ui, -apple-system, sans-serif;');
      lines.push('  --space-1: calc(var(--space-4) / 4);');
      lines.push('  --space-2: calc(var(--space-8) / 4);');
      lines.push('  --space-3: calc(var(--space-12) / 4);');
      lines.push('  --space-4: calc(var(--space-16) / 4);');
      lines.push('  --space-6: calc(var(--space-24) / 4);');
      lines.push('  --space-8: calc(var(--space-32) / 4);');
      lines.push('  --radius-sm: var(--radius-xs);');
      lines.push('  --radius-md: var(--radius-sm);');
      lines.push('  --shadow-sm: 0 1px 2px var(--color-overlay-sheet-shadow);');
      lines.push('}');
      lines.push('');
      return lines.join('\n');
    },
  });

  StyleDictionary.registerFormat({
    name: 'along/tailwind-preset',
    format({ dictionary }) {
      const colors = {};
      for (const token of groupTokens(dictionary, 'color')) {
        let node = colors;
        for (let i = 1; i < token.path.length; i++) {
          const key = token.path[i];
          if (i === token.path.length - 1) {
            node[key] = token.$value ?? token.value;
          } else {
            node[key] = node[key] ?? {};
            node = node[key];
          }
        }
      }

      const borderRadius = {};
      for (const token of groupTokens(dictionary, 'radius')) {
        borderRadius[token.path[1]] = token.$value ?? token.value;
      }

      const spacing = {};
      for (const token of groupTokens(dictionary, 'space')) {
        spacing[token.path[1]] = token.$value ?? token.value;
      }

      const boxShadow = {
        sheet: '0 -4px 24px var(--color-overlay-sheet-shadow)',
        floating: '0 2px 8px rgba(0, 0, 0, 0.12)',
      };

      const preset = {
        theme: {
          extend: {
            colors,
            borderRadius,
            spacing,
            boxShadow,
            fontFamily: {
              sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
            },
            fontVariantNumeric: {
              tabular: ['tabular-nums'],
            },
          },
        },
      };

      return `/** GENERATED — do not edit. Run: pnpm --filter @along/design-tokens build */
module.exports = ${JSON.stringify(preset, null, 2)};
`;
    },
  });
}
