# QR Sticker Print Specification

**Owner:** Ops lead / finance · **Last reviewed:** 2026-09-07 · **Status:** Preview-only until production gate (see below)

## Production gate — do not print for vehicles until all are true

1. `cfg('public.origin')` is a real `https://` origin (intended: `https://along.ng`) — not empty, not a Vercel preview URL alone.
2. **P4-E-02** (digital payments sign-off) is **PASS**.
3. **P1-G-01** (manual OS-camera gate on 3 low-end devices) is **PASS**.

Until then, A-13 sticker-batch PDF export is **staging preview only** (red banner). Do not affix labels to production vehicles.

---

## Physical label

| Property | Requirement |
| --- | --- |
| **Minimum QR size** | ≥ **70 mm** square (quiet zone included per ISO/IEC 18004) |
| **Error correction** | **Level H** (≈30% recovery) — mandatory for outdoor/wear |
| **QR payload** | `https://<public.origin>/p/<driver_code>` — built from `cfg('public.origin')`, never hardcoded |
| **Plate text** | Vehicle plate in **≥ 14 pt** bold, `#0A0A0A` on `#F7D117` band below QR |
| **Driver code** | 8-char Crockford base32 under plate, `#0A0A0A`, ≥ 10 pt |
| **Frame** | 2 mm border `#0A0A0A`; background `#F7D117` (Along yellow) behind plate band |
| **QR modules** | Dark `#0A0A0A`, light `#FFFFFF` (inside yellow frame) |
| **Material** | **Outdoor vinyl**, UV-resistant, laminated; adhesive rated ≥ 2 years outdoor (3M 180mc class or equivalent) |
| **Finish** | Matte lamination (reduces glare for camera scan) |

## Placement guidance (ops + driver briefing)

| Location | Guidance |
| --- | --- |
| **Primary** | Inside rear passenger area at eye level — seat back or dashboard passenger side |
| **Secondary** | Near door handle inside (keke/okada where seat back unavailable) |
| **Avoid** | External body panels (weather/theft), windshield (obstruction), over existing regulatory stickers |
| **Orientation** | QR upright; plate text readable without rotating head |
| **Verification** | Driver completes D-25 "Verify my sticker" after install; ops spot-check plate matches batch export |

## Batch export (A-13)

Finance exports sticker batch PDF from **A-13 → Sticker batch**. Each label must show: QR (EC-H), plate, `driver_code`. Cross-check batch CSV/driver list before sending to print vendor.

## Vendor handoff checklist

- [ ] Origin confirmed `https://…` and well-known files live (see `qr_sticker_lifecycle.md` § Verify)
- [ ] P4-E-02 + P1-G-01 PASS recorded in build ledger
- [ ] QR EC-H, ≥ 70 mm, colours `#0A0A0A` / `#F7D117`
- [ ] One label per `driver_code`; plate on label matches `driver_vehicles` active plate
- [ ] Preview PDF banner absent on production order (not the staging export)

## Related

- `docs/blueprint/14_qr_payments.md` §2
- `docs/runbooks/qr_sticker_lifecycle.md`
