/// Public OAuth configuration verified against Setcraft's Firebase Android app.
/// Regenerate with tool/prepare_google_sign_in.ps1 when Firebase config changes.
abstract final class GoogleAuthConfig {
  static const androidEnabled = true;

  /// iOS OAuth client from ios/Runner/GoogleService-Info.plist (CLIENT_ID).
  static const iosClientId =
      '796945284176-qha91hlr5b8bi948342bfe3p0c91a0h9.apps.googleusercontent.com';
  static const serverClientId =
      '796945284176-ojqomfn9ll3rs8a399aht2bdo2hmltde.apps.googleusercontent.com';
}
