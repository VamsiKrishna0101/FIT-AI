import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/google_auth_config.dart';

enum SocialProvider { apple, google }

/// Android uses the verified public Firebase configuration by default.
/// Build defines can override it; provider secrets never belong in the app.
class SocialSignIn {
  static const googleEnabled = bool.fromEnvironment('SETCRAFT_GOOGLE_SIGN_IN',
      defaultValue: GoogleAuthConfig.androidEnabled);
  static const appleEnabled = bool.fromEnvironment('SETCRAFT_APPLE_SIGN_IN');
  static const _googleServerId = String.fromEnvironment(
      'SETCRAFT_GOOGLE_SERVER_CLIENT_ID',
      defaultValue: GoogleAuthConfig.serverClientId);
  static const _googleIosId =
      String.fromEnvironment('SETCRAFT_GOOGLE_IOS_CLIENT_ID');
  static Future<void>? _googleInitialization;

  bool available(SocialProvider provider) {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    return switch (provider) {
      SocialProvider.google => googleEnabled &&
          _googleServerId.isNotEmpty &&
          (defaultTargetPlatform == TargetPlatform.android ||
              _googleIosId.isNotEmpty),
      SocialProvider.apple => appleEnabled,
    };
  }

  /// A Firebase token is exchanged for a Setcraft session by our server.
  /// Firebase's local session never unlocks the app or its subscription gate.
  Future<String?> authenticate(SocialProvider provider) async {
    if (!available(provider)) throw StateError('Provider is not configured');
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    final auth = FirebaseAuth.instance;
    try {
      // Never reuse a different person's cached Firebase identity on this device.
      await auth.signOut();
      UserCredential result;
      if (provider == SocialProvider.google) {
        try {
          await (_googleInitialization ??= GoogleSignIn.instance.initialize(
            serverClientId: _googleServerId,
            clientId: _googleIosId.isEmpty ? null : _googleIosId,
          ));
        } catch (_) {
          _googleInitialization = null;
          rethrow;
        }
        final account = await GoogleSignIn.instance.authenticate();
        final token = account.authentication.idToken;
        if (token == null) {
          throw StateError('Google did not return an ID token');
        }
        result = await auth.signInWithCredential(
            GoogleAuthProvider.credential(idToken: token));
      } else {
        result = await auth.signInWithProvider(AppleAuthProvider()
          ..addScope('email')
          ..addScope('name'));
      }
      final token = await result.user?.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw StateError('Provider did not return an ID token');
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'web-context-canceled' ||
          error.code == 'popup-closed-by-user' ||
          error.code == 'canceled') {
        return null;
      }
      rethrow;
    } finally {
      // The app uses SecureSessionStore, not Firebase auth persistence.
      await auth.signOut();
    }
  }
}
