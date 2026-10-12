import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps authentication credentials in the platform's secure key store.
class SecureSessionStore {
  static final SecureSessionStore shared = SecureSessionStore._();

  static const String _accessTokenKey = 'fitai_access_token';
  static const String _refreshTokenKey = 'fitai_refresh_token';
  static const String _userIdKey = 'fitai_user_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SecureSessionStore._();

  Future<void> _writes = Future<void>.value();
  Future<T> _write<T>(Future<T> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  bool sameOwner(String? first, String? second) {
    final owner = _ownerFromToken(first);
    return owner != null && owner == _ownerFromToken(second);
  }

  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);
  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get userId async {
    final token = await accessToken;
    final tokenOwner = _ownerFromToken(token);
    final storedOwner = await _storage.read(key: _userIdKey);
    // Recover sessions saved by older versions without an ID, and repair stale
    // cache ownership after account switches. This is a local cache identity;
    // authenticated API routes still verify the JWT signature and expiry.
    if (tokenOwner != null && tokenOwner != storedOwner) {
      if (await accessToken != token) return _ownerFromToken(await accessToken);
      await _storage.write(key: _userIdKey, value: tokenOwner);
    }
    return tokenOwner ?? storedOwner;
  }

  String? _ownerFromToken(String? token) {
    try {
      if (token == null) return null;
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final claims = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final owner = claims is Map ? claims['userId'] : null;
      return owner is String && owner.trim().isNotEmpty ? owner : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) =>
      _write(() => _saveTokens(accessToken, refreshToken, userId));

  Future<void> _saveTokens(
      String accessToken, String refreshToken, String? userId) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    final owner = userId ?? _ownerFromToken(accessToken);
    if (owner != null) {
      await _storage.write(key: _userIdKey, value: owner);
    } else {
      await _storage.delete(key: _userIdKey);
    }
    await _phoneSleepOwner(owner);
  }

  Future<void> syncPhoneSleepSession() async => _phoneSleepOwner(await userId);
  Future<void> _phoneSleepOwner(String? owner) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await const MethodChannel('fitai/sleep_estimate')
          .invokeMethod<void>('sessionOwner', {'owner': owner});
    } catch (_) {
      /* Optional native feature may be unavailable on this build. */
    }
  }

  Future<void> saveUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  Future<void> clear() => _write(() async {
        await _phoneSleepOwner(null);
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
        await _storage.delete(key: _userIdKey);
      });

  Future<bool> saveRefreshedTokens(
          {required String expectedAccessToken,
          required String expectedRefreshToken,
          required String accessToken,
          required String refreshToken}) =>
      _write(() async {
        if (await this.accessToken != expectedAccessToken ||
            await this.refreshToken != expectedRefreshToken) {
          return false;
        }
        final owner = _ownerFromToken(expectedAccessToken);
        if (owner == null || _ownerFromToken(accessToken) != owner) {
          return false;
        }
        await _saveTokens(accessToken, refreshToken, owner);
        return true;
      });
}
