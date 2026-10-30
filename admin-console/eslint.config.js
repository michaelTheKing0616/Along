import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import globals from 'globals';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['scripts/**/*.{js,mjs,cjs}', '**/*.cjs'],
    languageOptions: { globals: { ...globals.node } },
  },
  {
    files: ['**/*.cjs'],
    rules: { '@typescript-eslint/no-require-imports': 'off' },
  },
  {
    ignores: ['dist/**', 'node_modules/**', '.next/**', 'e2e/**', 'playwright-report/**', 'test-results/**', 'playwright.config.mjs', 'next-env.d.ts', 'public/maplibre-gl-worker.mjs'],
  },
);
