# Apple Watch

## How it fits together

- **Flutter (Dart)** – `lib/core/watch/watch_sync_service.dart` sends the workout
  snapshot (exercises, logged sets, rest timer, watch settings) over the
  `setcraft/watch` method channel and receives watch actions as a stream.
  `workout_session_view.dart` listens and saves sets, rest changes, skips and finish.
- **iPhone native** – `ios/Runner/WatchManager.swift` bridges the channel to
  `WCSession`: application context (latest state, delivered even when the watch
  app is closed), `sendMessage` (instant, when reachable) and `transferUserInfo`
  (queued actions from the watch).
- **Watch app** – `ios/SetcraftWatchApp/` (SwiftUI, watchOS 9+). Bundle id
  `com.setcraft.app.watchkitapp`, embedded in Runner via "Embed Watch Content".
  It runs an `HKWorkoutSession` for live heart rate/calories and saves the
  strength workout to Apple Health.

## Testing without Apple hardware

- `flutter test test/watch_sync_test.dart test/watch_settings_test.dart`
- Debug builds (Android too) show a watch icon in the workout top bar. It opens
  the Virtual Apple Watch sheet, which sends the same actions a real watch would
  (log set, skip, rest +30s/skip, finish, heart rate).

## First build on a Mac (cloud Mac is fine)

1. `cd mobile && flutter pub get && cd ios && open Runner.xcworkspace`
2. Select the **SetcraftWatchApp** target → Signing & Capabilities: team is set,
   automatic signing registers `com.setcraft.app.watchkitapp`. Confirm the
   HealthKit capability is shown.
3. Build **Runner** for an iPhone simulator paired with a Watch simulator
   (Xcode → Window → Devices and Simulators → pair). The watch app installs with
   the phone app.
4. To run only the watch UI, pick the **SetcraftWatchApp** scheme and a Watch
   simulator.
5. `flutter build ios` must also succeed (it builds the watch target as a
   dependency).

Live heart rate needs real Apple Watch hardware; simulators show 0 BPM.
