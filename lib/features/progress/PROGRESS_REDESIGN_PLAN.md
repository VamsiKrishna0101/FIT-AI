# Setcraft / FitAI — Progress Feature Premium UI Redesign Implementation Plan

> **Scope**: Redesigning `mobile/lib/features/progress` to match Setcraft's Pure Black OLED, Obsidian Glass, Liquid Silver, and Whoop 4.0 Biometric Design System.
> **Constraint**: Architecture and redesign plan only — zero functional regressions, preserving all caching, repositories, analytics, and business logic.

---

## 1. Executive Summary & Problem Diagnosis

### Current State Analysis
The `mobile/lib/features/progress` module is functionally rich and robust (supporting comprehensive workout tracking, body metric aggregation, wellness/nutrition trends, muscle distribution, and historical workout feeds). However, visually and aesthetically it diverges significantly from the rest of the app (`TodayHomeView`, `TrainDashboardView`, `LiquidSilverBottomBar`, and `BodyView`):

| Design Dimension | Rest of App (Today / Train / Body / Navigation) | Current `features/progress` |
| :--- | :--- | :--- |
| **Canvas & Theme** | Pure Black OLED (`#000000`, `DSColors.bg`), crisp contrast | Inconsistent mix of dark greys and muddy gradients |
| **Card Surface** | Obsidian Glass (`DSColors.bgCard` `#202020`), `FastGlassCard`, 0.7px specular borders (`DSColors.border`) | Custom `_SurfaceSheen` with hardcoded gradient `[0xFF1E1F22, 0xFF141416]` and raw custom canvas painters |
| **Tactile Interaction** | `MotionPress` spring scale micro-interaction on tap | Standard Flutter `InkWell` without spring bounce or haptic feedback |
| **Controls & Pickers** | Titanium pills, liquid segmented controls, custom modal sheets | Flutter Material `DropdownButtonHideUnderline` inside clunky 128px boxes |
| **Data Viz & Charts** | High-tech Whoop 4.0 style glowing charts, gradient fills, and smooth curves | Flat canvas lines with raw Cartesian grid ticks and basic sparklines |
| **Header Hierarchy** | Personalized headers with date stamps, profile avatars, and titanium controls | Static `Text('Progress')` with an offset, misaligned dropdown |
| **Typography & Numbers** | Tabular figures, tight tracking (`letterSpacing: -1.2`), metallic silver (`DSColors.silver`) | Oversized generic fonts (`48pt`), loose tracking, inconsistent font weights |

---

## 2. Target Design Language: "Obsidian Liquid & Biometric Titanium"

The redesigned Progress tab will align with Setcraft's core design pillars:
1. **Pure Black OLED Canvas**: Background remains strict `#000000` (`DSColors.bg`).
2. **Obsidian Glass Surfaces**: Reusable `FastGlassCard` with subtle specular top edge highlights (`Colors.white.withValues(alpha: 0.035)`), 0.7px borders (`DSColors.border`), and deep shadow blur (`blurRadius: 18, offset: Offset(0, 7)`).
3. **Whoop 4.0 Athletic Palette**:
   - Training & Workouts: `DSColors.accent` / Lime (`#67D7B0`)
   - Strength & Heavy Loads: `DSColors.ice` / Cyan (`#5AC8FA` / `#00E5FF`)
   - Muscle Distribution: `DSColors.pulse` / Electric Violet (`#8B7BFF`)
   - Personal Records (PRs): `DSColors.gold` / Radiant Gold (`#FFB84D`)
   - Recovery & Wellness: `DSColors.sage` / Emerald (`#37D69A` / `DSColors.whoopRecoveryGreen`)
   - Nutrition & Fuel: `DSColors.coral` / Warm Coral (`#ED927F`)
4. **Tactile Spring Physics (`DSMotion`)**: Every interactive card, tab, and row wrapped in `MotionPress` with iOS-standard spring curves and haptic clicks (`HapticFeedback.selectionClick()`).
5. **Liquid Controls**: Custom floating segmented pills with animated sliding gradient thumb indicators (`liquidActivePill`, `glassControlGradient`).

---

## 3. Component-by-Component Redesign Plan

### Phase 1: Foundation & Design Tokens (`progress_surface.dart`)

- [ ] **Deprecate Custom Gradient Surface Painter**:
  - Replace the muddy gradient `[Color(0xFF1E1F22), Color(0xFF141416)]` in `ProgressSurface` with `FastGlassCard` or unified `DSColors.bgCard`.
  - Harmonize card corner radius to `20px` (matching `FitnessCard` and `_TodaySurface`).
- [ ] **Add Tactile Spring Interactions**:
  - Integrate `MotionPress(enabled: onTap != null, child: ...)` into `ProgressSurface` and all card wrappers.
- [ ] **Refactor Specular Sheen & Border Tokens**:
  - Replace hardcoded border opacities with `DSColors.border` (`0x1CFFFFFF`) and `DSColors.borderHi` (`0x2AFFFFFF`).
  - Standardize subtle accent corner glow using `DSColors.specularBorder` or radial highlights clamped to max 12% opacity.
- [ ] **Modernize `ProgressChangeChip`**:
  - Convert change badges to capsule pills with frosted translucent backgrounds (`color.withValues(alpha: 0.12)`), 0.7px tint borders, and micro trend arrows (`CupertinoIcons.arrow_up_right` / `arrow_down_right`).

---

### Phase 2: Screen Header & Liquid Time Filter (`progress_overview_view.dart` & `progress_date_filter.dart`)

- [ ] **Header Modernization**:
  - Replace the plain `Progress` title row with a modern dashboard masthead:
    - Title: "Progress" (`fontSize: 28`, `fontWeight: FontWeight.w700`, `letterSpacing: -0.9`).
    - Subtitle: Dynamic date range tag (e.g., `4 WEEKS · 2 OCT – 30 OCT`) in `DSColors.muted` (`fontSize: 11`, `letterSpacing: 0.6`, uppercase).
- [ ] **Replace Dropdown with Liquid Period Pill**:
  - Eliminate `DropdownButtonHideUnderline` and Android-style dropdown popups.
  - Implement a **Liquid Segmented Period Bar** (`4W` | `3M` | `1Y` | `ALL` | `Custom`) or a **Titanium Capsule Filter**:
    - Floating pill displaying the selected period with a subtle chevron (`CupertinoIcons.chevron_down`, size 12).
    - On tap: Opens an Obsidian Glass bottom sheet (`DSMotion.sheetStyle(context)`) with rich date range presets and a sleek calendar selector.
  - Add `HapticFeedback.selectionClick()` on every period switch.

---

### Phase 3: Hero Performance Scoreboard (`progress_training_hero.dart`)

- [ ] **Redesign Hero Card Layout**:
  - Transform `ProgressTrainingHero` into a Whoop-inspired **Athletic Work Capacity Hub**:
    - Left side: Large primary metric (e.g., total workouts or volume) using tabular figures (`FontFeature.tabularFigures()`), metallic silver gradient text, and clean unit label.
    - Period-over-period delta badge directly under the score with colored directional arrow.
    - Right side: Dual biometric pill gauges (Logged Sets & New Records) with glowing neon circular icons (`accentLime` and `gold`).
- [ ] **Luminous Mini-Sparkline / Rhythm Bar**:
  - Upgrade the inline weekly bar chart:
    - Rounded cap bars with gradient fill (`DSColors.accent` to transparent or semi-translucent base).
    - Highlight the current/latest week with a subtle neon vertical glow and full opacity.
    - Support interactive hover/tap tooltips with micro haptic feedback.

---

### Phase 4: Biometric Scoreboard Row (`_buildStatsRow`)

- [ ] **Eliminate Plain Vertical Divider Grid**:
  - Replace the single partitioned card with a row of 3 discrete or smoothly bridged **Obsidian Glass Metric Tiles**:
    - **Tile 1**: Total Sets Logged (Ice / Cyan biometric theme).
    - **Tile 2**: Active Workouts (Accent Lime theme).
    - **Tile 3**: Personal Records (Gold PR theme).
  - Each tile features:
    - Subtle upper-left status pip / glowing indicator.
    - Micro label (`fontSize: 10`, `color: DSColors.muted`, uppercase tracking).
    - Big value (`fontSize: 22`, `letterSpacing: -0.8`, `color: DSColors.silver`).

---

### Phase 5: Exercise Progression Shelf & Cards (`progress_dashboard.dart` & `_ExerciseCard`)

- [ ] **Redesign `_ExerciseCard`**:
  - Standardize card geometry: Width `164px`, border radius `20px`, Obsidian Glass surface (`FastGlassCard`).
  - Top header: Exercise title with 2-line overflow protection and muscle group category pip.
  - Value display: Clean load/reps display with units styled in secondary font size (`kg` / `reps`).
  - Mini Sparkline: Replace the flat line with a curved bezier sparkline featuring a vertical gradient underfill (`LinearGradient(begin: top, end: bottom, colors: [cyan.withValues(alpha: 0.25), Colors.transparent])`).
  - Tactile Press: Wrap in `MotionPress`.
- [ ] **Shelf Carousel Interaction**:
  - Horizontal ListView with proper edge padding (`18px`) aligned to the screen grid.
  - Pinned exercises adorned with a sleek titanium pin badge (`CupertinoIcons.pin_fill`).

---

### Phase 6: Next-Gen Charts & Data Visualization (`progress_chart.dart` & `progress_weekly_bars.dart`)

- [ ] **Luminous Bezier Area Charts**:
  - Upgrade `ProgressChart` from jagged linear segments to smooth Catmull-Rom or Cubic Bezier splines.
  - Add ambient glow under the chart path using dual stroke passes (a blurred glow stroke underneath + crisp top stroke).
  - Area Fill: Seamless gradient fading down into pure black (`alpha: 0.25` down to `0.0`).
- [ ] **Interactive Scrubbing & Crosshair HUD**:
  - Touch scrubbing along the chart with a vertical hairline and frosted glass HUD tooltip pill displaying the exact reading, date, and delta.
  - Trigger light haptic tick (`HapticFeedback.selectionClick()`) when crossing data points.
- [ ] **Refined Empty States**:
  - Replace raw `ProgressEmpty` text with a polished obsidian card featuring an illuminated biometric glyph, calm copy, and a quick action button.

---

### Phase 7: Wellness, Nutrition & Body Previews (`ProgressBeyondTraining`)

- [ ] **Standardize 2-Column Grid**:
  - Ensure uniform heights and equal visual rhythm across Body, Recovery, and Nutrition cards.
- [ ] **Biometric Area Iconography**:
  - Body: Whoop amber/gold gradient icon.
  - Recovery: Whoop recovery green/sage icon with average sleep & HRV tags.
  - Nutrition: Coral gradient icon with daily average calorie / macro balance bar.
- [ ] **Trend Delta Indicators**:
  - Consistent directional badges comparing the current window against baseline.

---

### Phase 8: History Feed & Workout Tiles (`progress_workout_history.dart` & `progress_history_feed.dart`)

- [ ] **Redesign `ProgressWorkoutTile`**:
  - Replace the flat date container with a titanium date badge:
    - Frosted glass square (`48x48px`, radius `14px`) with metallic border.
    - Large day number (`18pt`, bold, white), uppercase month label in accent color.
  - Workout title with subtle chevron navigation icon.
  - Metrics row: Clean pill chips for sets, duration, and exercise count (matching `SessionOverviewCard` styling).
  - PR Highlight: When personal records exist, adorn the tile with a radiant gold border highlight (`DSColors.gold.withValues(alpha: 0.3)`) and gold rosette badge.
- [ ] **Heatmap Modernization (`progress_training_heatmap.dart`)**:
  - Replace square blocks with smooth rounded squircle cells (`radius: 4px`).
  - Color gradient: Pure OLED black (`#0D0D0D`) for 0 workouts, scaling up to vibrant mint glow (`#00E676` / `#67D7B0`) for high-volume days.

---

### Phase 9: Detail & Drill-down Views (`progress_detail_view.dart` & `progress_exercises_view.dart`)

- [ ] **Frosted Obsidian App Bar**:
  - Replace standard Flutter `AppBar` with frosted glass titanium navigation bar (`BackdropFilter` with blur 20, border line at bottom).
  - Circular frosted glass back button (`CupertinoIcons.chevron_left`).
- [ ] **Segmented Metric Pickers**:
  - Redesign metric pickers (e.g., Load vs Volume vs Reps) using Setcraft's `liquidActivePill` and `glassControlGradient`.
- [ ] **Exercise Search & Filter (`ProgressExercisesView`)**:
  - Obsidian search bar with `0.7px` border, magnifying glass icon, and active glow state when focused.

---

## 4. File Modification Roadmap

| File Path | Planned Redesign Scope |
| :--- | :--- |
| `mobile/lib/features/progress/components/progress_surface.dart` | Replace custom painter with `FastGlassCard` / `DSColors.bgCard`, add `MotionPress`, standardize borders & pips |
| `mobile/lib/features/progress/components/progress_date_filter.dart` | Replace clunky dropdown with liquid segmented pill & obsidian bottom sheet selector |
| `mobile/lib/features/progress/views/progress_overview_view.dart` | Modernize top header, integrate new period controls, polish sliver padding & transitions |
| `mobile/lib/features/progress/components/progress_training_hero.dart` | Redesign into Whoop-style Work Capacity hero scoreboard with glowing rhythm bars |
| `mobile/lib/features/progress/components/progress_chart.dart` | Implement smooth bezier curves, glowing gradient underfills, and haptic touch scrubbing |
| `mobile/lib/features/progress/components/progress_weekly_bars.dart` | Add rounded caps, neon active-week glow, and micro tooltips |
| `mobile/lib/features/progress/components/progress_dashboard.dart` | Redesign `_ExerciseCard`, exercise trend shelf carousel, and `ProgressBeyondTraining` cards |
| `mobile/lib/features/progress/components/progress_workout_history.dart` | Overhaul workout list tiles with titanium date badges, PR gold trims, and session chips |
| `mobile/lib/features/progress/components/progress_training_heatmap.dart` | Upgrade heatmap squircle styling and neon green density scales |
| `mobile/lib/features/progress/views/progress_detail_view.dart` | Implement frosted glass app bar, liquid metric switchers, and obsidian card containers |
| `mobile/lib/features/progress/views/progress_exercises_view.dart` | Add obsidian search bar, smooth list animations, and tactile row items |

---

## 5. Verification & Testing Strategy

1. **Visual Regression & Polish Audit**:
   - Side-by-side comparison between `TodayHomeView` (Tab 0) and `ProgressView` (Tab 3) to ensure 100% cohesion in background blackness, card sheen, corner radii, and typography.
2. **Platform & Accessibility Verification**:
   - Verify Dynamic Type scaling across all cards without text clipping.
   - High Contrast Mode validation (using `DSColors.borderHi` and solid cards).
   - VoiceOver / TalkBack semantics check on all charts and interactive cards.
3. **Performance & Frame Rate**:
   - Maintain steady 60/120 FPS during fast scrolling and interactive chart scrubbing.
   - Verify zero layout jank on data refresh.
4. **Data Integrity**:
   - Ensure all period filter parameters (`4w`, `3m`, `1y`, `all`, `custom`) continue to query `ProgressRepository` seamlessly.

