/**
 * OpenAPI ↔ Edge Function manifest drift check (doc 09 §2, P1-A-02).
 * Handlers may be stubs; this gate ensures openapi.yaml paths match the manifest.
 */
const ROOT = new URL('../../../', import.meta.url);
const OPENAPI_PATH = new URL('shared/contracts/openapi.yaml', ROOT);
const MANIFEST_PATH = new URL('shared/contracts/edge-functions.manifest.json', ROOT);

/** Expected Edge Function slugs from doc 03 §3–§7 (path after /functions/v1/). */
const DOC03_EDGE_FUNCTIONS = [
  'plan-trip',
  'places-search',
  'walking-directions',
  'parse-itinerary',
  'settlement/initiate',
  'webhooks/paystack',
  'payments/initiate',
  'qr/resolve/{driver_code}',
  'payments/methods',
  'payments/receipt/{payment_id}',
  'cache-metrics',
  'graph-bundle',
  'verification-ocr',
];

function normalizeOpenApiPath(path: string): string {
  return path.replace(/^\//, '');
}

async function loadYamlPaths(): Promise<string[]> {
  const text = await Deno.readTextFile(OPENAPI_PATH);
  const paths: string[] = [];
  const pathBlock = text.match(/^paths:\s*\n([\s\S]*?)^components:/m);
  if (!pathBlock) {
    throw new Error('Could not parse paths section from openapi.yaml');
  }
  for (const line of pathBlock[1].split('\n')) {
    const m = line.match(/^ {2}\/([^:]+):/);
    if (m) paths.push(normalizeOpenApiPath('/' + m[1]));
  }
  return paths.sort();
}

async function main(): Promise<void> {
  const openapiPaths = await loadYamlPaths();
  const manifestText = await Deno.readTextFile(MANIFEST_PATH);
  const manifest = JSON.parse(manifestText) as { functions: { slug: string }[] };
  const manifestSlugs = manifest.functions.map((f) => f.slug).sort();

  const expected = [...DOC03_EDGE_FUNCTIONS].sort();
  const missingFromOpenapi = expected.filter((p) => !openapiPaths.includes(p));
  const extraInOpenapi = openapiPaths.filter((p) => !expected.includes(p));
  const manifestMismatch = expected.filter((p) => !manifestSlugs.includes(p));
  const extraManifest = manifestSlugs.filter((p) => !expected.includes(p));

  let failed = false;
  if (missingFromOpenapi.length) {
    console.error('FAIL: doc 03 Edge Functions missing from openapi.yaml:', missingFromOpenapi);
    failed = true;
  }
  if (extraInOpenapi.length) {
    console.error('FAIL: openapi.yaml paths not in doc 03:', extraInOpenapi);
    failed = true;
  }
  if (manifestMismatch.length) {
    console.error('FAIL: doc 03 functions missing from edge-functions.manifest.json:', manifestMismatch);
    failed = true;
  }
  if (extraManifest.length) {
    console.error('FAIL: manifest slugs not in doc 03:', extraManifest);
    failed = true;
  }

  if (failed) Deno.exit(1);
  console.log(`PASS: OpenAPI paths (${openapiPaths.length}) match doc 03 and manifest.`);
}

if (import.meta.main) {
  await main();
}
