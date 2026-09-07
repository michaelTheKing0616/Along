# P9-A-01 Hardcode Audit Report

**Task:** P9-A-01 — grep-and-verify no city/currency hardcodes outside seeds/config  
**Branch:** `task/p9-a-01`  
**Date:** 2026-09-07  
**Patterns:** `abuja`, `Abuja`, `NGN`, `₦`, `+234`, `234`, `kaduna`, `lagos`

## Summary

| Classification | Count (approx.) | Notes |
|---|---|---|
| **FIXED** | 28 locations | Production paths now read city/country/config |
| **ALLOWED** | ~900+ | Seeds, pgTAP, e2e, fakes, l10n, docs, example JSON |
| **DEFERRED** | 12 | API-parse fallbacks, l10n strings, P9-B/C follow-ups |

## FIXED (this task)

| Path | Was | Fix |
|---|---|---|
| `mobile-rider/lib/features/home/*` | `AbujaMapConstants` map/search fallback | `city_centroid` RPC + `HomeState.mapCenter` |
| `mobile-driver/lib/features/home/*`, trip, draw-route screens | `MapCamera.abujaDefault()` | Driver `mapCenter` from `city_centroid` |
| `shared/flutter/along_map/lib/src/widget/along_map.dart` | Abuja fallback when no camera | Neutral `0,0` zoom 2 (caller must pass city centroid) |
| `mobile-rider/driver onboarding` | Static `+234` in `PhoneNumberFormatter` | `countries.phone_prefix` via `CatalogRepository.defaultActiveCountry()` |
| `shared/flutter/along_design/.../search_field.dart` callers | Default `+234` only | `PhoneField(countryCode:)` from provider |
| `mobile-rider/driver pricing controllers` | Hardcoded `NGN` in negotiation round | Uses `view.amount.currency` |
| `shared/flutter/along_data/negotiation_repository.dart` | Chip steps always `NGN` | Currency param from negotiation row |
| `mobile-driver/draw_route_controller.dart` | Publish surcharge `NGN` | `currencyCodeForCity(cityId)` |
| `shared/flutter/along_design/format_money.dart` | Always `₦` | `currency` + optional `currencySymbol` params |
| `admin-console/src/app/page.tsx` | Redirect `/abuja/dashboard` | First live city slug from `cities` table |
| `admin-console sign-in/mfa` | Default next `/abuja/dashboard` | Default next `/` (city-resolving home) |
| `admin-console/.../web-pay-api.ts` | `formatNaira` only | `formatMoneyAmount(amount, currency, symbol?)` |
| `backend/functions/payments/initiate/handler.ts` | Unattributed pay stayed `NGN` | Join `cities→countries.currency_code` |
| `backend/db/migrations/00000000000073_*` | `city_admin` deployment-wide leak | `admin_can_access_city` requires `city_scope` for `city_admin` |
| `backend/db/policies/vehicles.sql` | `is_admin()` without city scope | Scoped via `driver_vehicles→drivers.city_id` |
| `backend/db/policies/journeys.sql` | `city_admin` excluded | Added to `journeys_select_admin` |
| `backend/db/policies/countries.sql` | No anon read | `countries_select_anon_active` for onboarding |

## ALLOWED (remaining matches — do not change)

### Seeds & fixtures
- `backend/db/seed/seed_abuja_pilot/**` — Abuja pilot city name/slug, NGN fares, +234 scout phones
- `backend/db/seed/seed_core.sql` — NG country row (currency_symbol ₦, phone_prefix +234)
- `seed_testcity_fixture/` (Zaria-Test) — fictional city for TS-CFG-01
- `admin-console/e2e/**`, `data-collection/fixtures/**` — test city names

### Tests & fakes
- `**/test/**`, `**/*_test.*`, `**/testing/fakes/**` — fixture currency/city names (e.g. `city_abuja_min` pattern per task rules)
- `backend/db/tests/**` — +234 test phones, NGN amounts in pgTAP
- `mobile-rider/test/pricing_sheet_test.dart` — UI golden strings with ₦

### Docs & blueprint
- `docs/**`, `docs/blueprint/**` — example cities (Abuja, Kaduna, Lagos) as documentation

### Currency symbol lookup (ISO-driven, not locality assumption)
- `shared/flutter/along_core/.../money_format.dart` — maps `Money.currency` code → symbol (`NGN`→₦)
- `admin-console/src/lib/drivers/format.ts` — symbol from currency code when caller passes row currency
- `shared/flutter/along_design/format_money.dart` — default param `currency='NGN'` for call-site compat; callers pass API currency

### Map fixture-only constants
- `shared/flutter/along_map/.../abuja.dart`, `seedAbujaFixture()`, `abujaDefault()` — offline tile fixture bbox only (P0-E-04)

### API JSON parse fallbacks (server always sends currency in prod)
- `shared/flutter/along_data/.../domain_mappers.dart`, `payment_models.dart`, `driver_qr_repository.dart` — `?? 'NGN'` when field absent
- `backend/functions/_shared/planner/build.ts`, `rehydrate.ts` — init `currency='NGN'` overwritten by `resolve_fare` on first leg

### l10n / copy
- `mobile-*/lib/l10n/**` — "Last stop must be ₦0", wrongNumber strings
- `mobile-driver/.../route_price_validator.dart` — doc comment referencing ₦0 convention

### Admin console row-driven (currency from DB row)
- `admin-console/.../corporate-console.tsx`, `driver-detail.tsx` — uses `row.currency` / `overview.currency`
- `admin-console/e2e/global-setup.ts` — `E2E_CITY = 'abuja'` (e2e seed city)

### SQL migrations (historical; currency from country at runtime)
- `00000000000047_domain_qr_payments.sql`, `00000000000071_admin_b2b_portal_rpcs.sql` — RPC defaults; runtime resolves via city→country

### Other
- `backend/jobs/src/db.ts` — `Africa/Lagos` timezone env default (IANA zone, not city slug)
- `admin-console/src/app/(console)/unauthorized/page.tsx` — link `/abuja/dashboard` (DEFERRED: should use dynamic city)

## DEFERRED (with reason)

| Path | Reason |
|---|---|
| `mobile-driver/.../fast_route_setup_controller.dart` | Same pattern as draw_route; fix in P9-B-01 city switching pass |
| `mobile-driver/.../settle_screen.dart`, `ledger_controller.dart`, `standing_screen.dart` | Initial placeholder until ledger API returns; uses loaded `Money.currency` after refresh |
| `mobile-rider/.../pay_driver_sheet.dart` | Chip tiers from QR payload — wire `resolve.currency` in P9-B-01 |
| `admin-console/.../p/[code]/page.tsx` inline `formatNaira` JS | Use `formatMoneyAmount` with resolve payload currency (small follow-up) |
| `admin-console/.../finance-console.tsx` hardcoded `'NGN'` totals | Needs RPC to return currency_symbol; finance report scope |
| `PhoneField` default `countryCode = '+234'` | Constructor default only; all onboarding call sites now pass prefix from DB |
| `Money.zero({currency = 'NGN'})` | Type default; callers pass API currency on real paths |
| `profiles/riders` admin RLS without city filter | Profiles not city-scoped; city_admin dashboard uses city-filtered queries |

## city_admin RLS verification

- **Migration:** `00000000000073_city_admin_scope_and_public_geo.sql`
- **Test:** `backend/db/tests/TS-CITY-ADMIN-01-scope.sql`
- **Proves:** `city_admin` with `city_scope=[Alpha]` reads Alpha drivers/journeys only; Beta rows return 0

## TS-CFG-01

Not modified. Zaria-Test fixture unchanged; city config override test remains valid.

## Grep command (reproduce)

```bash
rg -n -i 'abuja|ngn|₦|\+234|234|kaduna|lagos' \
  backend admin-console mobile-rider mobile-driver shared backend/functions \
  --glob '!**/node_modules/**' --glob '!**/.git/**'
```

Post-fix production `lib/` matches are classified above as ALLOWED or DEFERRED.
