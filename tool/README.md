# Scroll benchmark

Run from `mobile` with a connected Android phone:

```powershell
flutter run --profile -d <device-id> --no-pub -t tool/today_scroll_benchmark.dart
```

This diagnostic entry point uses synthetic local fixtures. It does not call APIs,
read credentials, write to the database or clear app data. It temporarily opens a
benchmark in place of the normal app; restore it afterwards:

```powershell
flutter run --debug -d <device-id> --no-pub -t lib/main.dart
```

Each case warms the page, then measures three down/up scrolls lasting 900 ms per
direction. Frame timings come from Flutter's `SchedulerBinding` in profile mode.
Both variants use the same updated page and fixtures. The reference dock uses two
independent 28-sigma backdrop blurs. The current dock uses one grouped 12-sigma backdrop filter and a constant silver
tint while scrolling and stopped. This avoids changing material at scroll boundaries.

Results describe this device, data and run, not every real account or device.
The Body case covers the training map. Both Body modes share the optimized dock
and anatomical painter in production. Diagnostic source files are not imported
by the normal app entry point.

Historical 2026-10-07 run on Android `2201116PI` (previous adaptive implementation):

| Case | Frames | Render median | Render p90 | Render p99 | Render >16.67 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Today, reference dock | 221 | 23.455 ms | 26.905 ms | 47.272 ms | 99.55% |
| Today, scrolling chrome | 311 | 7.128 ms | 13.271 ms | 15.692 ms | 0.96% |
| Body, reference dock | 251 | 21.643 ms | 22.891 ms | 25.676 ms | 95.62% |
| Body, scrolling chrome | 321 | 11.072 ms | 11.503 ms | 12.595 ms | 0% |

Earlier runs with only grouped blur or lower blur strength were inconsistent.
The historical run above measured the earlier adaptive implementation. Current
measurements below apply to the consistent glass implementation.

2026-10-08 run on Android `CPH2613`, current consistent grouped glass:

| Case | Frames | Render median | Render p90 | Render p99 | Render >16.67 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Today, reference dock | 350 | 6.593 ms | 9.863 ms | 13.865 ms | 0% |
| Today, consistent grouped glass | 350 | 6.301 ms | 10.400 ms | 12.267 ms | 0% |
| Body, reference dock | 331 | 8.810 ms | 10.959 ms | 12.219 ms | 0% |
| Body, consistent grouped glass | 331 | 8.519 ms | 10.275 ms | 10.944 ms | 0% |

These measurements use synthetic screens on this phone. They do not establish
performance on the earlier Redmi or every device. Some render times exceed the
8.3 ms budget for 120 Hz, so these results do not promise a locked 120 fps.

## Exercise playback preview

`exercise_media_preview.dart` opens the exercise details screen with the
Cloudflare stretch animation. It reads the saved display language, but does not
sign in, fetch an account, create a workout or write to the database.

Create an ignored `build/media-probe.json` containing the public URL for exercise
1512 under the key `EXERCISE_PROBE_GIF`, then run:

```powershell
flutter run --debug -d <device-id> -t tool/exercise_media_preview.dart --dart-define-from-file=build/media-probe.json
```

Check movement over a complete three-second cycle, pause/resume, and background
the app. Restore the normal `lib/main.dart` entry point after the preview.

The normal player decodes original GIF bytes into a looping native codec, with
an animation cache separate from resized posters. A static response is rejected
and downloaded once more; persistent errors show Retry. Low-resolution media
uses a bounded illustration stage. MP4 demos retain their source aspect ratio.
White-backed anatomy demos retain their original background inside the compact
stage, preserving figure detail without background-removal artifacts. This does
not add source detail. Functional demos autoplay independently of Android transition
animation scales and provide an explicit pause control.

```powershell
flutter test test/exercise_media_test.dart test/exercise_localization_test.dart
```

The actual Cloudflare GIF check also runs when
`build/media-fixtures/exercise-1512.gif` is present locally; the committed
two-frame fixture keeps playback, pause, lifecycle, retry and stale-download
checks independent of the network.
