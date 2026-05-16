---
name: Kinetic Command
colors:
  surface: '#fff8f2'
  surface-dim: '#dfd9d3'
  surface-bright: '#fff8f2'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f9f2ed'
  surface-container: '#f3ede7'
  surface-container-high: '#eee7e1'
  surface-container-highest: '#e8e1dc'
  on-surface: '#1d1b18'
  on-surface-variant: '#5c4037'
  inverse-surface: '#33302c'
  inverse-on-surface: '#f6f0ea'
  outline: '#916f65'
  outline-variant: '#e6beb2'
  surface-tint: '#ad3300'
  primary: '#a93100'
  on-primary: '#ffffff'
  primary-container: '#d34000'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb59e'
  secondary: '#5f5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e2dfde'
  on-secondary-container: '#636262'
  tertiary: '#5d5c5a'
  on-tertiary: '#ffffff'
  tertiary-container: '#757472'
  on-tertiary-container: '#f9ffeb'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd0'
  primary-fixed-dim: '#ffb59e'
  on-primary-fixed: '#3a0b00'
  on-primary-fixed-variant: '#842500'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#e5e2df'
  tertiary-fixed-dim: '#c8c6c3'
  on-tertiary-fixed: '#1c1c1a'
  on-tertiary-fixed-variant: '#474745'
  background: '#fff8f2'
  on-background: '#1d1b18'
  surface-variant: '#e8e1dc'
typography:
  display:
    fontFamily: Space Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
    letterSpacing: 0em
  body-lg:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: 0.01em
  body-md:
    fontFamily: Space Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1'
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  container-padding: 32px
  gutter: 16px
---

## Brand & Style

This design system is engineered for high-performance productivity, blending the utilitarian efficiency of a "Professional Command Center" with a tactile, editorial aesthetic. It draws inspiration from the precise craftsmanship of tool-first interfaces like Linear and the spatial organization of lifeOS.

The visual style is a hybrid of **Minimalism** and **Glassmorphism**. It prioritizes extreme clarity and focus through generous whitespace and a "calm" color palette, while using translucent layers and subtle gradients to imply depth and technical sophistication. The personality is focused, premium, and authoritative—designed to feel like a high-end physical object translated into a digital workspace.

## Colors

The palette is anchored by "Soft Stone" (#F4F1EE), a warm, off-white neutral that reduces eye strain and provides a sophisticated, paper-like canvas. 

- **Primary Action:** Vibrant Orange (#FF4F00) is used sparingly for critical calls-to-action and active state highlights.
- **Surface & Text:** Nero (#1A1A1A) provides high-contrast grounding for primary text and dark UI modules (like sidebars or notification badges).
- **Secondary Accents:** Concrete and Sand tones are used for borders and secondary labels to maintain a soft hierarchy without cluttering the visual field.
- **Gradients:** Subtle mesh gradients should transition from the "Soft Stone" background to a slightly lighter "Paper" white to create naturalistic lighting.

## Typography

This design system utilizes **Space Grotesk** to achieve a technical yet humanistic feel. The typography relies on strong weight contrasts and intentional tracking.

Headings should be set with tight letter-spacing to feel "locked-in" and architectural. Conversely, small labels and metadata utilize uppercase styling with generous tracking (0.08em) to create an airy, modern feel. The hierarchy is steep; the difference between a header and a label should be unmistakable, ensuring users can scan the "Command Center" at a glance.

## Layout & Spacing

The layout philosophy follows a **Modular Card** system. Components do not float freely; they are housed in distinct containers that create a sense of organized "slots." 

A fluid grid is used for the main canvas, but internal card content adheres to a strict 4px/8px baseline grid. High whitespace (XL padding) is encouraged between major sections to prevent information density from becoming overwhelming. Content modules should span logical column groups (e.g., a 12-column grid where cards span 3, 4, or 6 columns) to maintain a rhythmic, balanced interface.

## Elevation & Depth

Hierarchy is established through **Tonal Layering** and **Glassmorphism** rather than traditional heavy shadows.

- **Level 0 (Base):** The "Soft Stone" (#F4F1EE) background.
- **Level 1 (Cards):** Slightly elevated white (#FFFFFF) surfaces with a 1px border (#E5E0DA) and a very soft, diffused shadow (15% opacity Nero, 20px blur, 4px Y-offset).
- **Level 2 (Overlays):** Glassmorphic panels with `backdrop-filter: blur(12px)` and 80% opacity backgrounds for menus and modals.
- **Level 3 (Interaction):** Intense, small shadows for active buttons to make them feel "pressed" or "raised" physically.

## Shapes

The shape language is consistently rounded to soften the technical nature of the tool.

- **Primary Containers:** 12px to 16px corner radii to create the "card" feel.
- **Interactive Elements:** Buttons and input fields use an 8px radius (rounded-lg) for a precise, modern look.
- **Icon Enclosures:** Small status badges or icon backgrounds may use 100% circular (pill) rounding to distinguish them from structural elements.

## Components

- **Buttons:** Primary buttons use the Vibrant Orange background with White text. Secondary buttons are Nero with White text. "Ghost" buttons use a thin 1px border and no fill until hover.
- **Cards:** The workhorse of the system. Every card must have a 1px soft border. Use card headers with the uppercase `label-sm` typography for categorization.
- **Inputs:** Clean fields with the "Soft Stone" background slightly darkened. On focus, the border transitions to a 1px Nero outline or Orange for error states.
- **Navigation (The "Dock"):** A bottom-centered floating navigation bar using glassmorphism. Icons are minimalist, monochrome strokes, with the active state indicated by an Orange dot or subtle background glow.
- **Chips:** Small, rounded-pill tags used for status ("Active", "Pending"). Use low-saturation background tints of the primary colors to keep them secondary to the main content.
- **Lists:** High-density text lists should use 1px horizontal separators in "Sand" (#E5E0DA) to maintain order without adding bulk.