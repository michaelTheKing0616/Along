# P10-B-01 — White-Label + Locale Dry Run Report

**Task:** P10-B-01 / P10-C-01 — tenant branding, locale packs, currency-agnostic formatting  
**Branch:** `task/p10-b-01`  
**Date:** 2026-09-07

## Summary

Dry-ran tenant **branding token overrides** from `deployments.branding_config` and **locale packs** (`ha`, `yo`, `ig`, `pcm`) in both Flutter apps without forking the design system. Default ink `#0A0A0A` / yellow `#F7D117` remain when config is empty.

## Branding (token overrides only)

| Check | Evidence |
|---|---|
| Reads `deployments.branding_config` | `CatalogRepository.brandingConfigForCountry()` → `BrandingOverrides.fromConfig()` |
| Theme override, not second design system | `alongTheme(branding:)` + `AlongBranding` `ThemeExtension`; `AlongButton` yellow reads extension |
| Default palette preserved | Empty `{}` → `#F7D117`; unit test `BrandingOverrides.empty keeps default yellow` |
| Tenant B dry-run colour | Golden `branding_yellow_tenant_b_1_0.png` with `#FFB800` override vs default golden |

### Fixture (tenant B accent)

```json
{
  "brand.yellow": "#FFB800",
  "brand.yellow-pressed": "#E6A600"
}
```

## Locale packs

| Locale | Rider ARB | Driver ARB | Widget test | Golden |
|---|---|---|---|---|
| `ha` | `app_ha.arb` | `app_ha.arb` | navHome → `Gida` | `locale_ha_city_switcher_1_0.png` |
| `yo` | `app_yo.arb` | `app_yo.arb` | navHome → `Ilé` | `locale_yo_settle_cta_1_0.png` (driver) |
| `ig` | `app_ig.arb` | `app_ig.arb` | navHome → `Ụlọ` | — |
| `pcm` | `app_pcm.arb` | `app_pcm.arb` | navHome → `Home` | — |

Representative strings: bottom nav, city switcher, Sponsored, common CTAs (`continueButton`, `settleCta`).

## Currency-agnostic formatting

| Check | Evidence |
|---|---|
| Symbol from `countries` | `MoneyFormatter` + `cityCurrencyMetaProvider` |
| Not hardcoded ₦ in touched screens | Rider: active trip, trip complete, trips history, pricing; Driver: earnings |
| GHS dry-run | `money_formatter_test.dart`: `₵450` not `₦` |

## Golden / screenshot paths

```
shared/flutter/along_design/test/golden/goldens/branding_yellow_default_1_0.png
shared/flutter/along_design/test/golden/goldens/branding_yellow_tenant_b_1_0.png
mobile-rider/test/goldens/locale_ha_city_switcher_1_0.png
mobile-driver/test/goldens/locale_yo_settle_cta_1_0.png
```

## Explicitly not done

- Locale picker UI in Account (strings scaffolded only)
- Rewiring every `formatMoney` call site across all screens
- Live deployment fetch at runtime against staging (provider + repository wired; tests use fakes)
- `digital_enabled` not flipped

## Tests

Run locally:

```bash
/Users/temitopeolaitanmichael/flutter/bin/flutter gen-l10n -v
# rider + driver (from app dirs with generate: true)
cd shared/flutter/along_design && flutter test test/branding_overrides_test.dart test/golden/branding_golden_test.dart --update-goldens
cd mobile-rider && flutter test test/locale_pack_test.dart --update-goldens
cd mobile-driver && flutter test test/locale_pack_test.dart --update-goldens
```
