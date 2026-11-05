import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/core/storage/session_sign_out.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('native notification and cache failures cannot prevent local logout',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': 'session',
      'fitai_refresh_token': 'refresh',
      'fitai_user_id': 'member',
    });
    var remainingCleanup = false;
    await completeSessionSignOut(
      detachNotifications: () async =>
          throw MissingPluginException('notifications'),
      clearSession: SecureSessionStore.shared.clear,
      cleanup: [
        () async => throw StateError('Cache unavailable'),
        () async {
          remainingCleanup = true;
        },
      ],
    );
    expect(await SecureSessionStore.shared.accessToken, isNull);
    expect(await SecureSessionStore.shared.refreshToken, isNull);
    expect(await SecureSessionStore.shared.userId, isNull);
    expect(remainingCleanup, isTrue);
  });
  test('failed credential removal is never reported as successful logout',
      () async {
    var cleaned = false;
    await expectLater(
        completeSessionSignOut(
          detachNotifications: () async {},
          clearSession: () async =>
              throw StateError('Secure storage unavailable'),
          cleanup: [
            () async {
              cleaned = true;
            }
          ],
        ),
        throwsStateError);
    expect(cleaned, isFalse);
  });
}
