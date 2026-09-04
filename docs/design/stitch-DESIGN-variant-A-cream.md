---
name: Kinetic Utility
colors:
  surface: '#fff9ee'
  surface-dim: '#e1d9c8'
  surface-bright: '#fff9ee'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fbf3e1'
  surface-container: '#f5eddb'
  surface-container-high: '#f0e7d6'
  surface-container-highest: '#eae2d0'
  on-surface: '#1f1b11'
  on-surface-variant: '#4d4732'
  inverse-surface: '#343024'
  inverse-on-surface: '#f8f0de'
  outline: '#7e7760'
  outline-variant: '#d0c6ab'
  surface-tint: '#705d00'
  primary: '#705d00'
  on-primary: '#ffffff'
  primary-container: '#f7d117'
  on-primary-container: '#6c5a00'
  inverse-primary: '#e9c400'
  secondary: '#5e5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e2e2e2'
  on-secondary-container: '#646464'
  tertiary: '#0053db'
  on-tertiary: '#ffffff'
  tertiary-container: '#c6d2ff'
  on-tertiary-container: '#0050d3'
  error: '#EF4444'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffe16d'
  primary-fixed-dim: '#e9c400'
  on-primary-fixed: '#221b00'
  on-primary-fixed-variant: '#544600'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c6'
  on-secondary-fixed: '#1b1b1b'
  on-secondary-fixed-variant: '#474747'
  tertiary-fixed: '#dbe1ff'
  tertiary-fixed-dim: '#b4c5ff'
  on-tertiary-fixed: '#00174b'
  on-tertiary-fixed-variant: '#003ea8'
  background: '#fff9ee'
  on-background: '#1f1b11'
  surface-variant: '#eae2d0'
  success: '#10B981'
  warning: '#F59E0B'
  mode-car: '#000000'
  mode-keke: '#F7D117'
  mode-okada: '#2563EB'
  mode-minibus: '#7C3AED'
  surface-card: '#FFFFFF'
  surface-neutral: '#F3F4F6'
typography:
  display-lg:
    fontFamily: Public Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-fare:
    fontFamily: JetBrains Mono
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.04em
  headline-md:
    fontFamily: Public Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-sm:
    fontFamily: Public Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-lg:
    fontFamily: Public Sans
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-md:
    fontFamily: Public Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Public Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-caps:
    fontFamily: Public Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  touch-target: 48px
---

## Brand & Style

The design system is engineered for the high-velocity, high-utility environment of Nigerian multi-modal transport. The brand personality is **Technical, Utilitarian, and Dependable**. It prioritizes "in-the-moment" decision-making, where legibility and speed of interaction are the primary success metrics.

The visual style follows a **Corporate / Modern** approach with **High-Contrast** accents. It rejects decorative elements in favor of a "Low-data, low-end-device first" philosophy. Every pixel must serve a functional purpose, utilizing heavy-weight strokes and high-contrast color pairings to ensure visibility in bright outdoor conditions and on low-resolution displays. The interface mimics a high-performance tool, emphasizing "One-Tap Efficiency" to minimize cognitive load during transit.

## Colors

The palette is deliberately tight to maintain rendering performance and visual consistency.
- **Primary (Taxi Yellow):** Reserved for primary CTAs, active transport indicators (Keke), and critical path highlights.
- **Secondary (Black):** Used for high-contrast typography, structural elements, and the "Car" transport mode.
- **Semantic Modes:** Each transport mode is assigned a unique, high-chroma color to allow for instant identification in list views and on the map.
- **Visual Signal (Na Me):** A trip-specific `id_signal_color` is generated at match-time for the identification handshake.
- **Status Colors:** Use standard semantic greens, ambers, and reds for system feedback, ensuring they meet AA contrast ratios against both white and light-gray surfaces.

## Typography

Typography focuses on "modular scaling" for small screens. 
- **Public Sans** provides the structural legibility required for names, places, and instructions.
- **JetBrains Mono** (or similar tabular numerals) is **mandatory** for all live-updating data, including fares, ETAs, and distance markers. This prevents layout jitter during real-time coordinate updates.
- **Hierarchy:** Display styles are aggressive and bold to ensure they are readable at arm's length in vibrating environments (e.g., inside a moving Keke).
- **Mobile Scale:** On mobile devices, `display-lg` should scale down to `headline-md` if the character count exceeds 10 to prevent word-wrap issues in bottom sheets.

## Layout & Spacing

This design system employs a **4pt baseline grid**. Every spatial dimension—padding, margins, heights, and icon sizes—must be a multiple of 4.

- **Layout Model:** A fluid grid system that prioritizes a persistent Map base layer. Functional UI is delivered via **Bottom Sheets** that occupy the lower 40% to 90% of the screen.
- **Touch Targets:** All interactive elements (buttons, toggles, chips) must maintain a minimum height of `48px` to accommodate high-stress, one-handed usage.
- **Reflow Logic:** On desktop/tablet, bottom sheets transition into side panels (360px - 400px width) anchored to the left or right, preserving the map's centrality.

## Elevation & Depth

Hierarchy is established through **Tonal Layering** and **Structural Stacking** rather than complex shadows.

- **The Map Base:** The lowest layer (Level 0). All other elements are perceived as physical overlays.
- **Bottom Sheets:** Use a subtle, high-spread shadow (`0px 4px 20px rgba(0,0,0,0.1)`) and a distinct top-border or "grabber" to indicate interactivity.
- **Surface Contrast:** Background surfaces use `surface-neutral` (#F3F4F6) to make white `surface-card` elements and buttons pop. 
- **Low-Data Depth:** Avoid backdrop blurs or heavy transparency which tax GPU performance on low-end devices. Use solid fills and `1px` borders for separation.

## Shapes

The shape language is **Soft (Level 1)**, using a `4px` base radius (`0.25rem`). This provides a professional, geometric look that aligns with the 4pt grid while remaining approachable.

- **Buttons & Inputs:** `4px` radius.
- **Cards & Bottom Sheets:** `12px` (rounded-xl) on top corners only to create a "drawer" effect.
- **Fare Chips:** Fully rounded (pill) to distinguish them as discrete, status-based data points.
- **Stop Pins:** Custom geometric pins (teardrop) with a `2px` stroke weight for maximum visibility against map tiles.

## Components

- **Bottom Sheets:** The primary container for all trip logic. Must include a persistent header with a "grabber" and a high-contrast primary CTA at the bottom.
- **Fare Chips:** High-contrast containers using `data-mono` typography. Background color matches the transport mode (e.g., Yellow for Keke).
- **Mode Icons:** Flat, 24px glyphs with thick `2pt` strokes. Avoid fine details that may disappear on low-dpi screens.
- **Status Toggles:** Large-format switches (`48px` height) with immediate visual feedback (Optimistic UI) to mask network latency.
- **Stop Pins:** Use a specific radius/tolerance to "snap" to canonical stages on the map. The "Destination" pin must always be Secondary Black.
- **Skeleton States:** Mandatory for all data-fetching states. Use a static light-gray pulsing effect (#E5E7EB) instead of rotating spinners.
- **Buttons:** Primary buttons use `primary-color` with Black text; Secondary buttons use Black with White text. Outlined buttons are reserved for "Cancel" or "Back" actions only.