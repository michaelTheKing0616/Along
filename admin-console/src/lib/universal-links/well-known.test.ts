import { describe, expect, it } from 'vitest';
import { GET as getAasa } from '@/app/.well-known/apple-app-site-association/route';
import { GET as getAssetLinks } from '@/app/.well-known/assetlinks.json/route';
import {
  buildAppleAppSiteAssociation,
  buildAssetLinks,
  readUniversalLinkEnv,
  WELL_KNOWN_CONTENT_TYPE,
} from '@/lib/universal-links/build';

describe('universal link payloads', () => {
  it('builds AASA with /p/* path and placeholder team id when unset', () => {
    const aasa = buildAppleAppSiteAssociation({ iosBundleId: 'ng.along.rider' });
    expect(aasa.applinks.apps).toEqual([]);
    expect(aasa.applinks.details).toHaveLength(1);
    expect(aasa.applinks.details[0]?.appID).toBe('TEAMID_PLACEHOLDER.ng.along.rider');
    expect(aasa.applinks.details[0]?.paths).toEqual(['/p/*']);
  });

  it('builds assetlinks with placeholder sha256 when unset', () => {
    const links = buildAssetLinks({ androidPackage: 'ng.along.rider' });
    expect(links).toHaveLength(1);
    expect(links[0]?.target.package_name).toBe('ng.along.rider');
    expect(links[0]?.target.sha256_cert_fingerprints).toEqual(['REPLACE_WITH_RELEASE_SHA256']);
  });

  it('reads env overrides for team id and sha256', () => {
    const env = readUniversalLinkEnv({
      APPLE_TEAM_ID: 'ABCD1234',
      RIDER_IOS_BUNDLE_ID: 'ng.along.rider.staging',
      RIDER_ANDROID_PACKAGE: 'ng.along.rider.staging',
      ANDROID_APP_LINK_SHA256: 'AA:BB:CC, DD:EE:FF',
    });
    expect(env.appleTeamId).toBe('ABCD1234');
    expect(env.iosBundleId).toBe('ng.along.rider.staging');
    expect(env.androidSha256Fingerprints).toEqual(['AA:BB:CC', 'DD:EE:FF']);
  });
});

describe('well-known route handlers', () => {
  it('AASA returns 200 application/json without redirect', async () => {
    const response = getAasa();
    expect(response.status).toBe(200);
    expect(response.headers.get('Content-Type')).toBe(WELL_KNOWN_CONTENT_TYPE);
    expect(response.headers.get('Location')).toBeNull();

    const body = await response.json();
    expect(body.applinks.details[0].paths).toContain('/p/*');
  });

  it('assetlinks.json returns 200 application/json without redirect', async () => {
    const response = getAssetLinks();
    expect(response.status).toBe(200);
    expect(response.headers.get('Content-Type')).toBe(WELL_KNOWN_CONTENT_TYPE);
    expect(response.headers.get('Location')).toBeNull();

    const body = await response.json();
    expect(Array.isArray(body)).toBe(true);
    expect(body[0].target.namespace).toBe('android_app');
  });
});
