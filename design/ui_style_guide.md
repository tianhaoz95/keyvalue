# KeyValue UI Style Guide (Modern Monochrome)

This document outlines the design principles and technical specifications for the KeyValue application to ensure visual consistency and a premium, modern professional aesthetic.

## 1. Color Palette
The theme is strictly high-contrast monochrome.

- **Primary Black:** `#000000` (Used for text, primary buttons, and active icons)
- **Primary White:** `#FFFFFF` (Used for backgrounds, cards, and text on black surfaces)
- **Accent Grey:** `#757575` (Used for secondary text and disabled states)
- **Surface Grey:** `#F9F9F9` / `#EEEEEE` (Used for subtle section backgrounds and borders)
- **Error:** `Colors.redAccent` (Reserved strictly for destructive actions or critical errors)

## 2. Typography
A bold, minimalist typographic hierarchy is central to the "engine-like" feel.

- **Headings (Large):** `FontWeight.w900`, `letterSpacing: -1.0` to `-2.5`. Used for primary titles (e.g., Login, Client Name).
- **Section Headers:** `FontWeight.w900`, `fontSize: 10-12`, `letterSpacing: 1.5`, **ALL CAPS**. Used for grouping information (e.g., "CONTACT DETAILS").
- **Body Text:** `fontSize: 14-16`, `height: 1.5-1.6` for readability.
- **Secondary Info:** `fontSize: 12`, `color: Colors.grey`.

## 3. Component Styling

### Containers & Cards
- **Elevation:** Always `0`. Avoid shadows to maintain a flat, modern look.
- **Borders:** Use a thin `1.0` width border with `Color(0xFFEEEEEE)` or `Colors.black12`.
- **Corner Radius:** Standardized at `12dp` for cards and `8dp` for smaller elements like inputs.

### Buttons
- **Primary (`ElevatedButton`):** Solid black background, white text, bold, all-caps.
- **Secondary (`OutlinedButton`):** Black border (`width: 1.5`), black text, no fill.
- **Minor (`TextButton`):** Black text, often with `TextDecoration.underline` for navigation.

### Input Fields
- **Border:** Outlined by default with light grey.
- **Focus:** Changes to black border with `width: 1.5` or `2.0`.
- **Labels:** Use small, bold, all-caps labels above or inside the field.

## 4. Iconography & Branding
- **Logo Tinting:** All logos must be tinted pure black using `color: Colors.black`.
- **Alignment:** In headers, the logo height should match the text `fontSize` exactly for a unified "lockup."
- **Icons:** Use outlined variants (e.g., `Icons.auto_awesome_outlined`) to keep the UI feeling light and airy.

## 5. Layout & UX Patterns
- **Whitespace:** Prioritize generous padding (standard `24dp` or `32dp` for screen edges).
- **Proactive Insights:** AI-generated content (Insights, Diffs) should be integrated inline (e.g., into the Profile tab) rather than hidden in sub-menus.
- **Timeline:** Vertical dot-and-line style. Use black for current/important events and grey for historical ones.
- **Search:** Collapsible in the `AppBar` to maximize screen real estate.

## 6. Theme Implementation (Flutter)
Always reference `AppTheme.lightTheme` from `lib/theme.dart`. Avoid hardcoding colors directly in widgets unless necessary for specialized contrast (like black cards with white text).
