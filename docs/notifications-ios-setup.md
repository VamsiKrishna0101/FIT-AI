# iOS notification setup to finish after enrollment

The code is prepared for bundle ID `com.setcraft.app`. Apple Developer enrollment can remain pending while app work continues.

Already prepared:

- Push Notifications/background notification capabilities and the APNs entitlement.
- Development APNs for Debug, production APNs for Release/Profile.
- Firebase Messaging registration, account-safe routing and foreground handling.
- Device-local rest timers with explicit permission and pause/extend/cancel/sign-out cleanup. These do not depend on APNs or backend scheduling.
- Optional Firebase configuration bundling. Builds without the real plist remain usable with remote reminders unavailable.

After Apple enrollment is approved:

1. Verify the explicit `com.setcraft.app` identifier in the Apple team and enable Push Notifications. Select the team for Runner in Xcode and refresh signing/provisioning profiles.
2. Register the matching iOS app in the existing Firebase project. Download its actual `GoogleService-Info.plist` to `mobile/ios/Runner/GoogleService-Info.plist`, or set `GOOGLE_SERVICE_INFO_FILE` to its absolute path in the build environment. The build verifies the bundle ID and copies the file into Runner.app. No dummy plist is needed.
3. Create an APNs authentication key and upload it in Firebase Project Settings → Cloud Messaging, with its Key ID and Apple Team ID. The private `.p8` belongs in Firebase/secure storage, not app source or chat.
4. On a Mac, fetch Flutter dependencies, resolve generated native packages and sign/build Runner. An unsigned CI build cannot establish APNs registration.
5. On a physical iPhone, enable reminders explicitly and send a test. Check foreground/background/terminated delivery, workout/report/meal dates, expired targets, logout/account switch, OS permission changes and token refresh.
6. Check local rest alerts with the phone locked; extend, pause, skip and finish a workout. Verify sign-out cancels stale alerts. Finally verify production push through TestFlight.

Remaining inputs: the Firebase client plist and Apple/Firebase account configuration. No passwords or private keys are needed in chat.

Official references: [Firebase Flutter messaging setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [Apple APNs registration](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns).
