---
name: Kinetic Utility
colors:
  surface: '#F7F7F7'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f4'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#444748'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#747878'
  outline-variant: '#c4c7c7'
  surface-tint: '#5f5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1c1b1b'
  on-primary-container: '#858383'
  inverse-primary: '#c8c6c5'
  secondary: '#705d00'
  on-secondary: '#ffffff'
  secondary-container: '#fed721'
  on-secondary-container: '#705e00'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#1b1c1c'
  on-tertiary-container: '#848484'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1c1b1b'
  on-primary-fixed-variant: '#474646'
  secondary-fixed: '#ffe16d'
  secondary-fixed-dim: '#e9c400'
  on-secondary-fixed: '#221b00'
  on-secondary-fixed-variant: '#544600'
  tertiary-fixed: '#e4e2e2'
  tertiary-fixed-dim: '#c7c6c6'
  on-tertiary-fixed: '#1b1c1c'
  on-tertiary-fixed-variant: '#464747'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
  border: '#E5E5E5'
  mode-okada: '#2563EB'
  mode-minibus: '#7C3AED'
typography:
  display:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  heading:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  section-heading:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-strong:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  small:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  small-strong:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  caption:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  button:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin: 16px
  target-min: 48px
  button-height: 52px
---

## Brand & Style
The design system is engineered for the high-velocity, high-utility environment of urban multi-modal transport. The brand personality is **Technical, Utilitarian, and Dependable**. It prioritizes "in-the-moment" decision-making, where legibility and speed of interaction are the primary success metrics.

The visual style follows a **Minimalist / High-Contrast** approach. It rejects decorative elements in favor of a "Low-data, high-performance" philosophy. Every pixel serves a functional purpose, utilizing heavy-weight strokes and high-contrast color pairings to ensure visibility in bright outdoor conditions and on low-resolution displays. The interface mimics a high-performance tool, emphasizing "One-Tap Efficiency" to minimize cognitive load during transit. Branding is intentionally stripped back to focus entirely on utility and map-driven navigation.

## Colors
The palette is hyper-functional, prioritizing contrast ratios for outdoor readability.

- **Primary (Black):** Used for primary typography, structural elements, and high-impact UI components.
- **Brand Accent (Taxi Yellow):** Reserved for active transport indicators (Keke), highlighting critical paths, and specific status indicators.
- **Secondary Text:** A low-saturation gray used for metadata and labels to maintain a clear visual hierarchy.
- **Surface & Background:** Pure white is used for the main background to maximize contrast, while the light gray Surface color differentiates cards and container layers from the base.
- **Maps:** Map tiles should be styled with low saturation to ensure that UI overlays and pins remain the focal point.

## Typography
The system uses **Inter** exclusively to ensure a clean, neutral, and highly legible interface across all devices. 

- **Numerical Data:** High-contrast numerals are essential. While Inter is the primary face, ensure `font-variant-numeric: tabular-nums` is applied to all ETAs, fares, and distances to prevent layout jitter during real-time updates.
- **Hierarchy:** Weight is used aggressively to distinguish between information types. Display and Heading levels use a Bold (700) weight for immediate recognition.
- **Mobile scaling:** On small screens, the `display` style should be capped at 28px if text length exceeds 12 characters to ensure layout integrity within bottom sheets.

## Layout & Spacing
This design system employs a **4pt baseline grid**. Every spatial dimension—padding, margins, heights, and icon sizes—must be a multiple of 4.

- **Layout Model:** A dominant Map view acts as the base layer. Functional UI is delivered via **Bottom Sheets** that slide over the map. These sheets should occupy 40% to 90% of the viewport.
- **Touch Targets:** All interactive elements must maintain a minimum height of `48px`. Primary action buttons are standardized at a height of `52-56px` for ease of use while in motion.
- **Breakpoints:** On desktop and tablet, bottom sheets transition into fixed-width side panels (380px) anchored to the side, ensuring the map remains the central point of truth.

## Elevation & Depth
Depth is conveyed through **Structural Stacking** and high-contrast borders rather than realistic shadows.

- **The Map Base:** The lowest layer. Map tiles should be desaturated to recede visually.
- **Bottom Sheets:** These sit on the highest elevation plane. Use a subtle, high-spread shadow or a 1px border (#E5E5E5) to separate the sheet from the map.
- **Cards:** Components within sheets use the `Surface` color (#F7F7F7) or white backgrounds with 1px borders to define their boundaries.
- **Visual Performance:** Avoid backdrop blurs or transparency. Use solid color fills to ensure the UI remains performant on mid-range and budget mobile devices.

## Shapes
The shape language is **Rounded (Level 2)**, utilizing a base radius of `8px` (0.5rem) for standard elements, but scaling up for primary containers.

- **Cards & Buttons:** Use a consistent `12px` to `16px` radius to create a modern, approachable feel that contrasts with the technical typography.
- **Bottom Sheets:** Top corners only should use a `16px` radius to emphasize the "drawer" metaphor.
- **Pills:** Status indicators and specific "Mode" chips should use a fully rounded (pill) shape to distinguish them from interactive buttons.

## Components
- **Buttons:** Primary buttons must be `52-56px` in height, using a Black background with White text or Taxi Yellow background with Black text for high-priority actions.
- **Bottom Sheets:** The core container for trip logic. It must include a persistent header "grabber" and a fixed primary CTA at the bottom.
- **Input Fields:** Use the `Surface` background with a `1px` border. Active states should be highlighted with a `2px` black border.
- **Chips:** Small, pill-shaped containers used for transport modes (e.g., Keke, Bus). Background colors match the specific mode's semantic color.
- **Lists:** High-density lists with `16px` padding. Each item should be separated by a `1px` border (#E5E5E5) to ensure clarity in sunlight.
- **Checkboxes & Radios:** Large-scale (`24px`) to ensure they are easy to toggle during transit. Use high-contrast black fills for the selected state.
- **Map Pins:** Custom geometric teardrops. The "Destination" pin must always be solid Black to contrast against the map and the Yellow "Current Location" indicator.