---
name: Radiant Dew
colors:
  surface: '#fff8f6'
  surface-dim: '#edd5cf'
  surface-bright: '#fff8f6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff1ed'
  surface-container: '#ffe9e4'
  surface-container-high: '#fce3dd'
  surface-container-highest: '#f6ddd8'
  on-surface: '#251815'
  on-surface-variant: '#56423e'
  inverse-surface: '#3c2d29'
  inverse-on-surface: '#ffede9'
  outline: '#89726d'
  outline-variant: '#dcc0ba'
  surface-tint: '#9e412c'
  primary: '#9e412c'
  on-primary: '#ffffff'
  primary-container: '#ff8b71'
  on-primary-container: '#752311'
  inverse-primary: '#ffb4a4'
  secondary: '#67600a'
  on-secondary: '#ffffff'
  secondary-container: '#ede282'
  on-secondary-container: '#6c6410'
  tertiary: '#874e58'
  on-tertiary: '#ffffff'
  tertiary-container: '#de99a4'
  on-tertiary-container: '#63303a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad3'
  primary-fixed-dim: '#ffb4a4'
  on-primary-fixed: '#3d0600'
  on-primary-fixed-variant: '#7f2a18'
  secondary-fixed: '#f0e585'
  secondary-fixed-dim: '#d3c96c'
  on-secondary-fixed: '#1f1c00'
  on-secondary-fixed-variant: '#4e4800'
  tertiary-fixed: '#ffd9de'
  tertiary-fixed-dim: '#fcb3be'
  on-tertiary-fixed: '#360c17'
  on-tertiary-fixed-variant: '#6b3741'
  background: '#fff8f6'
  on-background: '#251815'
  surface-variant: '#f6ddd8'
typography:
  display-lg:
    fontFamily: Quicksand
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Quicksand
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Quicksand
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Quicksand
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Quicksand
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 28px
  body-md:
    fontFamily: Quicksand
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.04em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: auto
---

## Brand & Style

The design system focuses on an energetic, youthful, and "glowy" aesthetic for a skincare tracking experience. It rejects the cold, sterile, and clinical "sage green" tropes of traditional dermatology apps in favor of a warm, sun-kissed, and vibrant personality.

The design style is a hybrid of **Soft Minimalism** and **Glassmorphism**. It utilizes high-key lighting, soft diffused shadows, and translucent layers to evoke the feeling of healthy, hydrated skin. The emotional response should be one of optimism and self-care—moving the daily routine from a chore to a moment of "glow."

- **Vibrancy:** High-saturation accents against soft, creamy surfaces.
- **Approachability:** Overwhelmingly soft edges and rounded forms.
- **Clarity:** Despite the fun aesthetic, the tracking interface maintains a strict grid to ensure data entry is effortless.

## Colors

The palette is inspired by a "golden hour" glow. 

- **Primary (Vibrant Peach):** Used for call-to-action buttons, active states, and primary brand moments. It conveys energy and health.
- **Secondary (Soft Lemon):** Used for highlights, streaks of joy, and secondary tracking categories (e.g., morning routines).
- **Tertiary (Rosy Pink):** Used for soft accents, progress indicators, and night-time routine markers.
- **Surface (Cream):** A warm off-white (#FFF9F5) replaces harsh pure white to keep the interface feeling soft and organic.
- **Neutral (Warm Charcoal):** A soft, brown-tinted dark grey for maximum readability without the harshness of pure black.

## Typography

This design system uses **Quicksand** as the primary typeface for its unique rounded terminals that mirror the soft shapes of the UI. It feels friendly and approachable.

**Plus Jakarta Sans** is introduced for labels and small utility text. Its slightly more structured geometric forms ensure that dense information (like ingredient lists or timestamps) remains highly legible.

- **Headlines:** Use Bold or SemiBold weights to create a strong visual hierarchy.
- **Body:** Stays at a Medium weight (500) to ensure the rounded terminals don't blur at small sizes.
- **Letter Spacing:** Headlines use a slight negative tracking to feel "tight" and punchy, while labels use positive tracking for better scanability.

## Layout & Spacing

The design system employs a **Fluid-Responsive Grid** centered around an 8px base unit. 

- **Mobile:** A 4-column layout with 20px side margins. Elements typically span the full width or 2 columns.
- **Desktop:** A 12-column centered layout with a max-width of 1200px.
- **Rhythm:** Generous vertical spacing (40px+) between major sections to prevent the "clutter" often found in health trackers.
- **Alignment:** Content is primarily left-aligned for readability, with center-alignment reserved for high-impact "glow" hero moments.

## Elevation & Depth

To achieve the "Glow" effect, this design system avoids heavy, dark shadows. Instead, it uses **Colored Ambient Glows** and **Tonal Layering**.

- **Level 1 (Base):** The Cream surface (#FFF9F5).
- **Level 2 (Cards):** Pure white (#FFFFFF) with a very soft, high-spread shadow tinted with the Primary color (e.g., `rgba(255, 139, 113, 0.1)`).
- **Level 3 (Interactive):** Elements that "hover" use a double shadow—one tight white highlight and one wide, soft peach or pink glow to look like light is passing through them.
- **Glassmorphism:** Use a `backdrop-filter: blur(12px)` with a 60% opacity white fill for sticky headers and navigation bars to maintain the "dewy" look.

## Shapes

The shape language is defined by **Extreme Roundness**. There are no sharp corners in this design system.

- **Components:** Buttons, inputs, and tags use "Pill" shapes (Full radius).
- **Containers:** Cards and modals use a 2rem (32px) radius on mobile and 3rem on desktop to feel soft and pebble-like.
- **Icons:** Should use a "Rounded" or "Soft" icon set (e.g., Phosphor Soft) with a stroke weight of 2px to match the typography's friendliness.

## Components

- **Buttons:** Primary buttons are pill-shaped, Vibrant Peach, with white text. Use a subtle gradient (Peach to Rosy Pink) for a "glowing" effect.
- **Inputs:** Soft cream backgrounds with a 1px border that turns Peach on focus. The cursor should be the Primary color.
- **Cards:** White surfaces with a 32px corner radius. Include a subtle inner glow or a top-weighted Soft Lemon border for "sunlight" highlights.
- **Progress Trackers:** Use thick, rounded lines. Completed steps should glow with a Soft Lemon outer shadow.
- **Chips/Tags:** Used for skin concerns (e.g., "Oily", "Dry"). These should have high-contrast backgrounds (Lemon or Pink) with dark neutral text.
- **Daily Glow Tracker:** A custom circular component that fills with a gradient from Rosy Pink to Vibrant Peach as the user completes their routine tasks.