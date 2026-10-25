# Setcraft identity

The public app name is **Setcraft**. The launcher icon is a continuous angular
S within a white circle on black. Use the same mark for native launch and Flutter
startup. Android's native splash hands off on Flutter's first rendered frame.
Flutter paints the same centred vector synchronously while preferences/session
load, then opens home immediately. There is no image decode, wordmark reveal,
forced timer, looping effect or first-frame hold waiting on storage/network.
Session, starter-plan, health-setup, subscription and dashboard-mode checks share the same
`SetcraftLaunchScreen`, so startup does not replace the mark with a spinner.
The complete logo leaves together when the next actual screen is ready.

## Assets

- Original concept: `docs/branding/setcraft-icon-generated.png` (archived).
- Production geometry: `tool/export_setcraft_icons.py`; generated SVG:
  `assets/branding/setcraft-mark.svg`.
- Raster export: `assets/branding/setcraft-icon.png` (opaque black, 1024px).
- Exporter: `tool/export_setcraft_icons.py` (Python + Pillow).
- Exports: Android launcher/adaptive/themed/notification icons and splash,
  iOS and macOS icon catalogs, iOS launch images, web icons and Windows ICO.
- The normalized circle is 70% of the tile width. Android's adaptive foreground
  is scaled by 72/108 to compensate for the launcher's viewport crop. Check the
  visible 72dp viewport, rather than judging only the full 108dp source layer.
- iOS launch is static and text-free. Native launches use a black background in
  both system themes to avoid a white flash.
- Android adaptive launcher, monochrome, notification and splash assets use
  VectorDrawable paths. Flutter uses generated geometry in CustomPaint. Store
  PNGs are drawn from geometry at each final size, rather than resizing a soft
  generated source. The platform exit listener removes the native splash without
  adding an icon translation/fade. The startup recovery screen offers retry.
- Flutter draws the ring as a filled annulus path. The previous stroked-circle
  primitive was absent in physical Android captures even though it appeared in
  widget-test renders. The native and Flutter geometry proportions are unchanged.
- Native launch and normal themes explicitly disable automatic Force Dark
  recoloring; the app already owns its black background and white foreground.
- LaunchTheme has no separate `values-night` override. Both modes select the
  explicit API 31 splash configuration on Android 12+, rather than a night theme
  that omits the splash drawable and falls back to the launcher icon.

## Compatibility

Keep the Dart package, Android application ID, Apple bundle IDs, OAuth/deep-link
configuration, API environment variables, purchase product identifiers,
database names and persisted `fitai_*` keys unchanged. These are technical
identifiers, not displayed branding. Existing authenticated users retain their
sessions and account-owned data. Store listing titles and remotely configured
services must be updated separately in their respective consoles.

## Generation

The original concept used the built-in imagegen tool. The user's WHOOP icon was supplied as
a reference for the monochrome circle, spacing and line weight. The inner W
was replaced with the Setcraft S. Earlier hexagonal S, stack and SC concepts
were discarded. The final generation prompt is in `setcraft-icon-prompt.txt`.

The production mark replaces the concept's textured raster edges with solid
white vector strokes. The launcher refinement removes the central cut from the
S and preserves generous black margins. The visible circle diameter is about
70% of the tile across platforms, including Android's adaptive viewport crop.

Suggested store metadata, to be entered in App Store Connect:

- Name: `Setcraft: AI Workout Planner`
- Subtitle: `Nutrition Plans & Muscle Maps`

This source update does not publish a store listing or modify remote accounts.

## Verification

- 85 distinct Flutter tests verified across startup, authenticated session
  recovery, localization, onboarding, subscription, settings and health screens.
- Dart analysis passed for the changed startup, branding, onboarding and test code.
- Backend TypeScript build passed.
- Android debug build passed. APK metadata confirms the displayed app name is
  Setcraft and the application ID remains `com.example.fitai_mobile`.
- Store icon dimensions/opacity, platform XML and bundled branding assets checked.
- The focus chips now reserve checkmark space, preventing selection from shifting
  neighbouring options. Existing Body tests scroll past the weekly plan card to
  reach their intended controls.
- Rendered Flutter splash: `build/branding/setcraft-splash-preview.png`.
- iOS/macOS assets and metadata updated; Apple builds were not run on Windows.
- Existing third-party glass shader/Kotlin migration warnings remain in Android
  tooling; the debug build completed successfully.
- Vector refinement: all 6 startup/root checks passed, including immediate home
  readiness, failure/retry, disposal, and centre alignment with unequal system
  insets. First-frame deferral was removed; Android no longer waits on account
  initialization before painting the app.
- Installed and checked on the connected Android 13 phone in night mode. The
  native icon changed from dark gray to white after correcting resource
  precedence. Evidence: `build/branding/setcraft-vector-night-final/frame-2.png`;
  actual launcher: `build/branding/setcraft-vector-launcher.png`.
- Ring handoff: 18 startup/root/starter-plan tests passed, including retaining the
  mark across pending session and account checks. Changed files passed analysis.
  The dashboard's mode initialization uses the complete logo before showing its
  banner and navigation, avoiding a final full-screen spinner between stages.
  Installed on the connected phone; 20 cold-launch captures show the full mark
  through frames 01–10, then the dashboard from frame 11. No S-only frame or
  intermediate full-screen spinner was captured. Evidence:
  `build/branding/setcraft-ring-final/review.png`.
