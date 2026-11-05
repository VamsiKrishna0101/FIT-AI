# Progress scrolling: connected-device measurements

Measured on 4 November 2026 on the connected Android 2201116PI, in Flutter
profile mode at 120 Hz. The frame budget is approximately 8.33 ms.

The benchmark uses synthetic data: 13 muscles, six recent exercises, body
readings and daily nutrition/sleep logs. It scrolls the actual Progress overview
down and back up three times after an initial pass. It does not read account
credentials, call the backend or edit member data.

## Warm scroll results, with the navigation dock

| Dataset | UI build P90, before → after | Raster P90, before → after | Frames exceeding the 120 Hz budget, before → after |
| --- | --- | --- | --- |
| 7 days | 5.485 → 1.378 ms | 11.434 → 5.712 ms | 97.92% → 1.02% |
| 28 days | 5.264 → 1.533 ms | 11.483 → 6.097 ms | 96.97% → 1.13% |

The 28-day control without the original dock had a raster P90 of 7.073 ms and
2.77% of frames exceeding the budget. This identified the two live backdrop
passes in the Android dock as a major GPU cost. The UI also spent time
rebuilding and laying out animated bars and replaying section opacity effects
when the lazy list recreated cards.

These are repeatable fixture measurements on this phone, not a guarantee for
every device, dataset or thermal condition. A frame is counted above budget
when either its build time or raster time exceeds the display's frame budget.

## Changes

- Android paints the dock's existing translucent gradients and rim without live
  backdrop blur. The selection animation, hit targets and navigation behavior
  are retained. Other platforms keep their existing rendering path.
- Column charts create their labels and full-height bars once per data/layout
  build. The rise animation applies a paint transform to the plot. Repaint
  boundaries isolate the plot and labels.
- Progress sections no longer replay opacity animations as they mount during
  scrolling.
- Reopening Progress and returning from details use the repository's cache
  freshness policy. Pull-to-refresh and data invalidation still force refreshes.
  Body edits now invalidate Progress, alongside meals, wellness and workouts.
- Foreground load completion updates data and loading state together. Its cache
  notification no longer triggers an additional simultaneous overview update.

## Reproduce

Run from `mobile` with an authorized Android phone attached:

```powershell
flutter run --profile --no-pub -d <device-id> -t tool/progress_scroll_benchmark.dart --dart-define=PROGRESS_PERF_PHASE=after
```

The tool prints one `FITAI_PROGRESS_PROFILE` JSON record for each first/warm
pass, including a control with the dock removed. The phase define labels the
measurements; it does not select an older implementation.

After benchmarking, restore the normal application entry point:

```powershell
flutter run --profile --no-pub -d <device-id> -t lib/main.dart
```

Regression coverage includes scrolling to the last muscle and back, macro
selection/reset, chart selection and missing readings, cache freshness, body
invalidation, navigation gestures and accessibility.
