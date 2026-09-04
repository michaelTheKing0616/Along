# 05 — Design System ("Kinetic Utility", resolved)

Spec references: §5.2 (design tokens, low-end devices, one-tap, multi-leg legibility, vector tiles), §4.6, §4.8, FM19/FM20/FM34. Decision: ADR-0005.

Source of truth: `shared/design-tokens/tokens.json` (W3C DTCG format). `pnpm tokens:build` generates `shared/flutter/along_design/lib/src/tokens.g.dart` and `admin-console/src/styles/tokens.css` (+ Tailwind preset). **No hex, px, or font size is ever typed in app code** — the Reviewer greps for `Color(0x`, `#[0-9a-f]{6}`, `fontSize:` outside `along_design` and fails the task if found (FM20).

---

## 1. Reconciling the two Stitch variants (the decision)

Stitch produced two conflicting `DESIGN.md` files (copied to `docs/design/stitch-DESIGN-variant-A-cream.md` and `-variant-B-neutral.md`).

| Aspect | Variant A (cream) | Variant B (neutral) | **Resolved** | Why |
|---|---|---|---|---|
| Surface | warm cream `#fff9ee` | `#F7F7F7` | **Pure white `#FFFFFF` + `#F5F5F5` surfaces** | Cream lowers contrast against desaturated map tiles and dulls the yellow; white maximises legibility in direct sunlight on low-brightness panels |
| Primary action | olive-gold `#705d00` (Material tonal derivative of yellow) | black `#1c1b1b` | **Ink black `#0A0A0A`, white text** | Olive is the single biggest quality defect in the Stitch set: muddy, dated, and low-affordance. Yellow can't carry text (fails AA on white), so M3 tone-mapping drove it to olive. We don't need yellow *as text*; we need it as a *surface* |
| Brand yellow | `#f7d117` container | `#fed721` secondary container | **`#F7D117` fills with black text** | Real taxi yellow; 13.6:1 against black. Used for selection, live/online states, the "Recommended" badge, keke identity, the location puck |
| Typography | Public Sans + JetBrains Mono for numbers | Inter | **Inter (variable) only, tabular numerals via `tnum`** | One family = smaller bundle (low-data principle), and `tnum` already removes numeric jitter. A monospaced coding face beside Inter reads "developer tool", not "premium transit" |
| Radii | 4 px, "sharp" | 8–16 px | **4 / 8 / 12 / 16 / 20 (sheet) / pill** | Sharp corners on chips and inputs read utilitarian; 16–20 on sheets/cards reads modern. Mixed scale by role, not one global value |
| Mode colours | car black, keke yellow, okada blue, minibus purple | same | **car deep-teal, keke yellow, okada blue, minibus purple** | Car = black collides with the primary button; a black chip *looks tappable*. Teal nods to Abuja's green cabs without pretending vehicle paint is universal |
| Decorative elements | rocket icons, AI illustration banner, gradients | fewer | **None** (spec §5.2 "no decorative elements") | |

Brand mark: the *real* logo is `docs/design/logos/main_logo_along_black.png` / `_yellow.png` (italic wordmark, speed slashes, car). It is raster today; task P0-D-01 vectorises it (SVG + adaptive Android icon + iOS asset catalog). The Stitch "geometric sharp" logo is rejected (generic); "path-through" rejected (strikethrough reads as deletion).

---

## 2. Colour tokens

```json
"color": {
  "ink":     { "900":"#0A0A0A", "700":"#3D3D3D", "500":"#6B6B6B", "300":"#B8B8B8", "100":"#E5E5E5" },
  "surface": { "0":"#FFFFFF", "50":"#FAFAFA", "100":"#F5F5F5", "200":"#EEEEEE", "inverse":"#141414" },
  "brand":   { "yellow":"#F7D117", "yellow-pressed":"#E3BF0F", "yellow-tint":"#FFF6CC", "yellow-on":"#0A0A0A" },
  "semantic":{ "success":"#15803D", "success-fill":"#16A34A", "success-tint":"#DCFCE7",
               "warning":"#B45309", "warning-fill":"#F59E0B", "warning-tint":"#FEF3C7",
               "danger":"#B91C1C",  "danger-fill":"#DC2626",  "danger-tint":"#FEE2E2",
               "info":"#1D4ED8",    "info-fill":"#2563EB",    "info-tint":"#DBEAFE" },
  "mode":    { "car":"#0F766E", "keke":"#F7D117", "okada":"#2563EB", "minibus":"#7C3AED",
               "car-on":"#FFFFFF", "keke-on":"#0A0A0A", "okada-on":"#FFFFFF", "minibus-on":"#FFFFFF",
               "car-tint":"#CCFBF1", "keke-tint":"#FFF6CC", "okada-tint":"#DBEAFE", "minibus-tint":"#EDE9FE" },
  "tier":    { "verified":"#15803D", "crowd":"#1D4ED8", "candidate":"#B45309", "estimate":"#6B6B6B" },
  "map":     { "puck":"#F7D117", "puck-ring":"rgba(247,209,23,0.25)", "route-active":"#0A0A0A", "route-walk":"#6B6B6B",
               "cluster-fill":"rgba(247,209,23,0.18)", "cluster-stroke":"#F7D117" },
  "overlay": { "scrim":"rgba(10,10,10,0.48)", "sheet-shadow":"rgba(0,0,0,0.10)" },
  "naMe":    { "red":"#FF1744", "orange":"#FF9100", "yellow":"#FFEA00", "green":"#00E676",
               "cyan":"#00E5FF", "blue":"#2979FF", "purple":"#D500F9", "white":"#FFFFFF" }
}
```
Contrast rules (AA): body text ≥ 4.5:1 → `ink.900`/`ink.700` on `surface.*`; `ink.500` is the *minimum* for secondary text on white (5.7:1); `ink.300` is disabled only. Semantic `*-fill` colours are for icons/fills; the base `semantic.*` colours are the *text* variants (all ≥ 4.5:1 on white). Mode colours never carry text on white; they fill chips with the paired `-on` colour.

Dark mode: **not in scope** through Phase 9 (spec §5.2 prioritises daylight legibility; a dark map style costs battery on OLED only marginally and doubles QA). Tokens are structured so a `dark` set can be added without code changes.

---

## 3. Typography (Inter, bundled subset: Latin + Latin-Ext + currency; verify ₦ U+20A6 glyph — TS-DS-02)

| Token | Size/Line | Weight | Tracking | Features | Use |
|---|---|---|---|---|---|
| `display.xl` | 40/44 | 800 | −0.02em | `tnum` | Fare hero on request/confirm, Na Me label |
| `display.l` | 32/36 | 800 | −0.02em | `tnum` | Ledger balance, big ETA |
| `heading.1` | 24/30 | 700 | −0.01em | | Screen titles ("Where to?") |
| `heading.2` | 20/26 | 700 | −0.01em | | Sheet titles, card titles |
| `title` | 18/24 | 600 | 0 | | Option card primary line |
| `body` | 16/24 | 400 | 0 | | Default |
| `body.strong` | 16/24 | 600 | 0 | | Emphasis, list primary |
| `label` | 14/20 | 600 | 0 | | Buttons (secondary), chips, form labels |
| `caption` | 12/16 | 500 | 0 | | Meta, timestamps |
| `overline` | 12/16 | 700 | +0.06em | uppercase | Section labels ("RECENT", "PICKUP") |
| `numeric.l` | 24/28 | 700 | −0.01em | `tnum` | Fares on option cards |
| `numeric.m` | 18/22 | 700 | 0 | `tnum` | Ledger rows, ETAs |
| `button.primary` | 17/24 | 700 | 0 | | Primary CTA |

Minimum text size anywhere: 12. Body scales with OS font scale up to 1.3×; layouts must not truncate fares at 1.3× (TS-DS-03).

---

## 4. Spacing, shape, elevation, sizing

- Spacing scale (4-pt): `0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64`. Screen gutter 16; sheet inner padding 16/20; card padding 16; list row min height 56.
- Radii: `xs 4` (badges, tier pills), `sm 8` (inputs, chips), `md 12` (cards), `lg 16` (option cards, dialogs), `sheet 20` (bottom sheets top corners), `pill 999`.
- Borders: 1 px `ink.100` for cards on white; no borders on `surface.100` cards.
- Elevation: flat by default. Exactly two shadows: `sheet` (`0 −4 24 overlay.sheet-shadow`) and `floating` (`0 2 8 rgba(0,0,0,0.12)` for the map FABs). Nothing else casts a shadow.
- Touch targets: min 48×48; primary CTA height 56; secondary 48; chips 36 (with 48 hit-slop); map controls 44.
- Focus/pressed: pressed = 8% `ink.900` overlay (or `brand.yellow-pressed` for yellow fills); 120 ms.

---

## 5. Motion

| Token | Duration | Curve | Use |
|---|---|---|---|
| `motion.tap` | 120 ms | ease-out | pressed states, chip select |
| `motion.sheet` | 220 ms | cubic(0.2,0,0,1) | bottom sheet expand/collapse |
| `motion.route` | 200 ms | same | screen push (Android/iOS default overridden for consistency) |
| `motion.camera` | 350 ms | ease-in-out | map camera moves |
| `motion.pulse` | 1.6 s loop | ease-in-out | location puck ring, "requesting…" indicator |
| `motion.naMe` | 250 ms on/off (4 Hz), 8 s | linear | Na Me strobe |

No bounces, no spring physics, no parallax. Reduced-motion OS setting disables pulse/strobe *visual* animation (Na Me falls back to a static colour fill + haptics).

---

## 6. Na Me signal system (§4.8)

Colours: the eight `color.naMe.*` (chosen for saturation on cheap LCDs and mutual distinguishability). Shapes: `circle, square, triangle, diamond, star, hexagon` as filled glyphs (bundled SVG, 240 dp). Text label always shown beneath in `display.l` (`"GREEN DIAMOND"`) — colour-blind users and verbal confirmation ("I'm green diamond") rely on it. Never show a number as the identifier (the Stitch "#42" is rejected: numbers aren't glanceable across a street).

Strobe: alternate full-screen fill between the colour and `ink.900` at 4 Hz for 8 s (`motion.naMe`), haptic `heavy` pulse in sync, torch strobe at 4 Hz where `torch_light` reports availability, optional TTS "Along — green diamond" once at start. Brightness forced to max for the duration then restored.

---

## 7. Iconography

Material Symbols Rounded (variable), weight 500, fill 0 default / fill 1 for selected. Mode icons are custom (6 SVGs: car, keke, okada, minibus, walk, transfer) because Material's `two_wheeler`/`electric_rickshaw` don't read as Nigerian vehicles. Size scale 20/24/32. Icons never appear without a label except in the bottom nav (which has labels) and map controls (which have tooltips/semantics labels).

---

## 8. Map style ("along-light")

MapLibre style JSON generated in `backend/routing/style/` from OpenMapTiles schema over our PMTiles:
- Land `#F4F4F2`, water `#CFE3EA` (desaturated), parks/green `#E6EEE3`, buildings `#EBEBE9` (zoom ≥ 15 only), roads: motorway `#D8D8D6` 6 px, primary `#DEDEDC`, minor `#E8E8E6`; road labels `ink.500` Inter 12; POI labels hidden below zoom 15; **no** POI icons except transit.
- Along layers above basemap: `parks` (yellow square pin with black border, label at zoom ≥ 13), `stages` (small black dots, zoom ≥ 14), `route-active` (`map.route-active` 5 px + white 7 px casing), `route-walk` (dashed `map.route-walk` 3 px), `ambient-cells` (translucent yellow discs sized by bucket, count label, heading tick marks), `vehicle` (Tier B only: black rounded rect with mode glyph, rotates by heading), `puck` (yellow disc with pulsing ring).
- Glyphs: Inter via our own glyph PBFs (no Google Fonts at runtime — low data).
- Tile budget: PMTiles for Nigeria ≈ 1.2 GB on CDN; device cache 150 MB LRU; corridor pre-cache on first search.

---

## 9. Component library (`along_design` for Flutter; `admin-console/src/components/ui` for web)

Each component: name · variants · states · anatomy · one-tap notes. Every component has a golden test (Flutter) / Storybook story (web).

| Component | Variants | States | Notes |
|---|---|---|---|
| `AlongButton` | primary (ink fill), secondary (outline ink), tertiary (text), danger (danger fill), yellow (brand fill, reserved for *go-live* actions: "Go online", "Publish route") | default, pressed, loading (spinner replaces label, width fixed), disabled | Height 56/48; full-width by default in sheets; label `button.primary` |
| `HoldButton` | SOS (danger), Na Me (ink) | idle, holding (radial progress 600 ms), fired | Hold-to-fire prevents accidental SOS; Na Me fires on tap *and* hold (tap = one strobe cycle) |
| `OptionCard` | direct, multi_leg; recommended highlight (yellow 2 px border + badge) | default, pressed, unavailable (greyed with reason), warning (load) | Anatomy: left mode chip column (stacked for multi-leg), title (board→alight), meta row (walk · wait · transfers), right fare `numeric.l` + `TierPill`, footer `RequestButton` full-width 48 |
| `TierPill` | verified (green dot "Standard fare"), crowd (blue "Community fare"), candidate (amber "Unconfirmed"), estimate (grey "Estimate — agree price") | | Always next to any fare (FM8) |
| `ModeChip` | 4 modes × sizes s/m | selected/unselected | Colour fill + custom icon + label; never colour alone |
| `SortChips` | recommended · cheapest · fastest · least strenuous | | Single-select, persists via `saved_sort` |
| `LegTimeline` | compact (active-trip chip row), full (itinerary) | leg states: done / current / next / pending | Vertical rail with mode-coloured segments, walk segments dashed; each leg row: mode chip, board → alight, fare, ETA at transfer |
| `NaMeChip` / `NaMeScreen` | | | Chip: 24 dp shape in colour + label; Screen: full-bleed |
| `FareHero` | with/without delta (extension) | | `display.xl` + `TierPill` + itemised expand |
| `AmbientCluster` (map) | buckets 1-2 / 3-5 / 6+ | fresh / stale (≤60 s greyed) | Disc + count + up to 3 heading ticks |
| `BottomSheet` | collapsed (peek 96), half, full | | Grabber 32×4 `ink.300`; snap points fixed; content scroll only at full |
| `StatusToggle` (driver) | offline / at park / roaming available / roaming full | | Segmented control, 56 high; yellow fill on active state; one tap changes state (no confirm) |
| `LedgerRow` | debit / credit / settlement / adjustment | | Human label from `entry_type` map; amount `numeric.m` signed and coloured (`danger` for debit, `success` for credit); balance_after on the right in `caption` |
| `BalanceCard` | good / warned / paused | | Balance `display.l`, threshold line, "Settle" `AlongButton yellow` when < 0 |
| `RequestSheet` (driver) | with/without load, women-only badge | countdown ring | Anatomy: header "New request" + countdown; pickup/dropoff rows; fare (rider pays) and "Along fee" line separately (FM3); load row; Accept (yellow 56) / Decline (secondary 56) side by side, Accept ≥ 60% width |
| `NegotiationSheet` | park / roaming(none, single, full) / extension | round n of cap; countdown | Anchor `display.l`; chips `−100 −50 +50 +100` from `chip_steps`; Accept full-width; split-the-difference appears at cap |
| `StepList` (wayfinding) | text / audio playing | | Per-step row: maneuver icon, instruction, distance |
| `SearchField` | home (peek), full | | 56 high, leading search icon, trailing clock (recents) |
| `PhoneField`, `OtpField` | | error | E.164 formatting, country selector limited to active countries |
| `Skeleton` | line, card, map-overlay | | Shimmer 1.2 s; used for every network wait > 300 ms |
| `Toast/Snackbar` | info, success, undo (with 3 s countdown) | | Undo used after one-tap request to reverse accidental taps without adding a confirm step |
| `EmptyState` | coverage gap, no history, offline | | Illustration-free; icon + heading + body + one action |
| `AdminDataTable`, `AdminMap`, `EvidencePanel`, `QueueList`, `AuditDrawer` | web | | doc 08 |

---

## 10. Flutter mapping

```dart
// along_design/lib/along_design.dart exports:
class AlongColors { static const ink900 = Color(0xFF0A0A0A); ... }          // generated
class AlongText  { static final displayXl = TextStyle(fontFamily: 'Inter', fontSize: 40, height: 44/40, fontWeight: FontWeight.w800, letterSpacing: -0.8, fontFeatures: [FontFeature.tabularFigures()]); ... }
class AlongSpace { static const s4 = 4.0; ... }
class AlongRadius { static const sm = Radius.circular(8); ... }
class AlongMotion { static const tap = Duration(milliseconds: 120); ... }
ThemeData alongTheme() // Material 3 ThemeData wired to the tokens: ColorScheme.fromSeed is NOT used (it would regenerate olive); explicit ColorScheme
```
Rules: `ThemeData.useMaterial3 = true`; `visualDensity = standard`; `splashFactory = InkSparkle.splashFactory` disabled → `NoSplash` + custom pressed overlay; page transitions `FadeUpwardsPageTransitionsBuilder` replaced by a 200 ms shared-axis builder.

## 11. Web (admin) mapping
Tailwind preset generated from tokens: `colors.ink.*`, `colors.brand.*`, `fontFamily.sans = Inter`, `borderRadius.*`, `boxShadow.sheet/floating`. shadcn/ui components re-themed via CSS variables emitted by the token build. Data tables use `numeric.m` with `font-variant-numeric: tabular-nums`.

## 12. Accessibility & low-end device rules
- All interactive elements have semantics labels; fares announced as "450 naira" (TTS-friendly formatting `formatMoneySpoken`).
- Colour never sole carrier (tier pills have text; modes have icons; Na Me has label).
- Contrast AA everywhere; AAA for fares and CTAs (ink on white/yellow).
- Text scale to 1.3× without truncating money.
- Images: none at runtime except avatars (optional) and verification captures. No Lottie; no video.
- Frame budget: option list of 12 cards renders < 16 ms per frame on the reference device (doc 10 device matrix).
