import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/cache/app_data_mode.dart';
import 'package:fitai_mobile/core/cache/cache_scope.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';

String token(String owner) =>
    '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.test';

class PreviewAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Completer<ResponseBody>? held;
  ResponseBody response(Map<String, dynamic> data) =>
      ResponseBody.fromString(jsonEncode(data), 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (options.path.endsWith('/status')) {
      return response({
        'data': {'available': true, 'days': 30}
      });
    }
    if (held != null) return held!.future;
    return response({
      'data': {},
      'source': options.path.contains('/preview/') ? 'preview' : 'real'
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late PreviewAdapter adapter;
  var sequence = 0;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('preview-${sequence++}'), refreshToken: 'test');
    adapter = PreviewAdapter();
    ApiClient.shared.client.httpClientAdapter = adapter;
    await AppDataMode.shared.initialize();
  });

  test('Real training preserves one calendar date and offset in the URL',
      () async {
    await ApiClient.shared
        .get('/api/workout/training?date=2026-10-09&utcOffsetMinutes=330');
    final url = adapter.requests.last.uri;
    expect(url.path, '/api/workout/training');
    expect(url.queryParametersAll['date'], ['2026-10-09']);
    expect(url.queryParametersAll['utcOffsetMinutes'], ['330']);
  });

  test('Old preview choices cannot change real data or account cache isolation',
      () async {
    final previewKey = await CacheScope.userDayKey('diet');
    await AppDataMode.shared.select(false);
    final realKey = await CacheScope.userDayKey('diet');
    expect(realKey, previewKey);
    await AppDataMode.shared.select(true);
    expect(AppDataMode.shared.preview, false);
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('other-preview-owner'), refreshToken: 'test');
    await AppDataMode.shared.initialize();
    expect(AppDataMode.shared.preview, false);
    expect(await CacheScope.userDayKey('diet'), isNot(previewKey));
  });

  test('Real workout, photo and nutrition writes use their normal endpoints',
      () async {
    final count = adapter.requests.length;
    for (final path in [
      '/api/workout/training/start',
      '/api/body/entries',
      '/api/nutrition/me/log'
    ]) {
      await ApiClient.shared.post(path, data: {});
      expect(adapter.requests.last.path, path);
    }
    expect(adapter.requests.length, count + 3);
  });

  test('A response from the old account cannot replace the current account',
      () async {
    adapter.held = Completer<ResponseBody>();
    final pending = ApiClient.shared.get('/api/home');
    final expectation = expectLater(pending, throwsA(isA<DioException>()));
    for (var attempt = 0;
        attempt < 100 && adapter.requests.isEmpty;
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await SecureSessionStore.shared
        .saveTokens(accessToken: token('changed-owner'), refreshToken: 'test');
    await AppDataMode.shared.ensureOwner();
    adapter.held!.complete(adapter.response({'source': 'preview'}));
    await expectation;
  });
}
