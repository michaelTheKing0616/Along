/** Universal / App Link association payloads (doc 14 §2, doc 09 §7). */

const PLACEHOLDER_APPLE_TEAM_ID = 'TEAMID_PLACEHOLDER';
const PLACEHOLDER_ANDROID_SHA256 = 'REPLACE_WITH_RELEASE_SHA256';

export interface UniversalLinkEnv {
  appleTeamId?: string;
  iosBundleId?: string;
  androidPackage?: string;
  androidSha256Fingerprints?: string[];
}

export function readUniversalLinkEnv(
  env: Record<string, string | undefined> = process.env
): UniversalLinkEnv {
  const appleTeamId = env.APPLE_TEAM_ID?.trim() || undefined;
  const iosBundleId = env.RIDER_IOS_BUNDLE_ID?.trim() || 'ng.along.rider';
  const androidPackage = env.RIDER_ANDROID_PACKAGE?.trim() || 'ng.along.rider';
  const rawSha = env.ANDROID_APP_LINK_SHA256?.trim();
  const androidSha256Fingerprints = rawSha
    ? rawSha.split(',').map((s) => s.trim()).filter(Boolean)
    : undefined;

  return { appleTeamId, iosBundleId, androidPackage, androidSha256Fingerprints };
}

export function buildAppleAppSiteAssociation(env: UniversalLinkEnv = readUniversalLinkEnv()) {
  const teamId = env.appleTeamId || PLACEHOLDER_APPLE_TEAM_ID;
  const bundleId = env.iosBundleId || 'ng.along.rider';

  return {
    applinks: {
      apps: [] as string[],
      details: [
        {
          appID: `${teamId}.${bundleId}`,
          paths: ['/p/*'],
        },
      ],
    },
  };
}

export function buildAssetLinks(env: UniversalLinkEnv = readUniversalLinkEnv()) {
  const fingerprints =
    env.androidSha256Fingerprints && env.androidSha256Fingerprints.length > 0
      ? env.androidSha256Fingerprints
      : [PLACEHOLDER_ANDROID_SHA256];

  return [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: env.androidPackage || 'ng.along.rider',
        sha256_cert_fingerprints: fingerprints,
      },
    },
  ];
}

export const WELL_KNOWN_CONTENT_TYPE = 'application/json';
