SafeRoute UI/UX design system (Android-first)

Visual direction
- Modern, minimal, “non-Material” feel while still using Flutter Material widgets.
- Large typography, generous whitespace, soft surfaces, crisp outlines, minimal elevation.
- Use a deep night background + electric mint accent in dark mode; warm off-white + indigo accent in light mode.

Core screens
1) Mode Selection (Home)
- Full-bleed gradient backdrop (subtle), centered title “SafeRoute”.
- Two large pill cards/buttons: Run and Cycle.
- Each option shows icon, short subtitle (“Walking directions” / “Bicycle directions”), and an arrow.
- Primary action style: high-contrast surface with subtle stroke; press state slightly scales down (0.98) and changes tint.

2) Map Screen
- Google Map fills background.
- Top overlay: compact header pill with current mode + quick hint “Tap to set destination”.
- Bottom overlay: floating info card (rounded, blurred/tinted surface) with:
  - Distance remaining
  - ETA remaining
  - Safety score badge
  - Traffic delay row shown only when delay > 0
- Floating action button cluster (right side):
  - Recenter (my location)
  - Clear route (x)

Tokens
Spacing (dp)
- 4, 8, 12, 16, 20, 24, 32
Radii (dp)
- 12 (chips), 16 (cards), 28 (pills)

Typography mapping
- titleLarge: Screen title (SafeRoute, Map mode)
- titleMedium: Card headers
- bodyMedium: Supporting copy
- labelLarge: Button labels
- labelSmall: Captions, badges
Line height
- Body: 1.45–1.6

Accessibility checklist
- Tap targets >= 48x48
- Ensure text contrast >= 4.5:1 on surfaces
- Add semantics labels for icon-only buttons
- Respect safe areas

Components
- ModeOptionButton(label, subtitle, icon, onTap)
  Usage: ModeOptionButton(label: 'Run', subtitle: 'Walking directions', icon: Icons.directions_run, onTap: ...)
- FloatingInfoCard(distanceText, etaText, safetyScore, trafficDelayText?)
  Usage: FloatingInfoCard(distanceText: '3.2 km', etaText: '18 min', safetyScore: 84, trafficDelayText: '+4 min')
- MapActionPill(icon, tooltip, onTap)
  Usage: MapActionPill(icon: Icons.my_location, tooltip: 'Recenter', onTap: ...)

Notes
- Avoid heavy shadows; use 1px strokes and subtle surface tint.
- Use minimal animations only for button press + small cross-fades for info card changes.
