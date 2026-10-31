import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';

String token(String owner, String tag) =>
    '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner,
          'tag': tag
        })))}.synthetic';

class _Adapter implements HttpClientAdapter {
  int renewals = 0, retries = 0;
  bool invalid = false;
  final seen = <String>[];
  Completer<void>? pending;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.path == '/api/auth/refresh') {
      renewals++;
      if (pending != null) await pending!.future;
      return ResponseBody.fromString(
          jsonEncode(invalid
              ? {'error': 'Expired'}
              : {
                  'tokens': {
                    'accessToken': token('alice', 'new'),
                    'refreshToken': 'refresh'
                  }
                }),
          invalid ? 401 : 200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    final header = options.headers['Authorization'] as String? ?? '';
    seen.add(header);
    if (header.endsWith(token('alice', 'new'))) {
      retries++;
      return ResponseBody.fromString('{"ok":true}', 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    return ResponseBody.fromString('{"error":"Expired"}', 401, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Adapter adapter;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('alice', 'old'), refreshToken: 'refresh');
    adapter = _Adapter();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
  });
  test('concurrent protected requests share one renewal and retry once',
      () async {
    adapter.pending = Completer<void>();
    final requests = Future.wait([
      ApiClient.shared.get('/api/body'),
      ApiClient.shared.get('/api/wellness/check-in/2026-10-09')
    ]);
    while (adapter.renewals == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    adapter.pending!.complete();
    final responses = await requests;
    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(adapter.renewals, 1);
    expect(adapter.retries, 2);
    expect(await SecureSessionStore.shared.userId, 'alice');
  });
  test('invalid refresh leaves credentials intact and never loops', () async {
    adapter.invalid = true;
    await expectLater(
        ApiClient.shared.get('/api/body'), throwsA(isA<DioException>()));
    expect(adapter.renewals, 1);
    expect(adapter.retries, 0);
    expect(await SecureSessionStore.shared.accessToken, token('alice', 'old'));
  });
  test(
      'account switch during renewal cannot replace credentials or replay an old request',
      () async {
    adapter.pending = Completer<void>();
    final request = ApiClient.shared.post('/api/wellness/check-in/2026-10-09');
    final expectation = expectLater(request, throwsA(isA<DioException>()));
    while (adapter.renewals == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('bob', 'login'), refreshToken: 'bob-refresh');
    adapter.pending!.complete();
    await expectation;
    expect(await SecureSessionStore.shared.userId, 'bob');
    expect(await SecureSessionStore.shared.refreshToken, 'bob-refresh');
    expect(adapter.retries, 0);
    expect(adapter.seen.any((header) => header.contains(token('bob', 'login'))),
        isFalse);
  });
}
