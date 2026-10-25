import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/localization/language_manager.dart';
import 'package:fitai_mobile/core/localization/app_language.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/progress/repositories/progress_repository.dart';

String token(String owner) =>
    '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.test';

class ProgressAdapter implements HttpClientAdapter {
  final pending = <Completer<ResponseBody>>[];
  final observed = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    observed.add(options);
    final response = Completer<ResponseBody>();
    pending.add(response);
    return response.future;
  }

  void complete(int index, int value) =>
      pending[index].complete(ResponseBody.fromString(
          jsonEncode({
            'data': {'value': value}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          }));
  @override
  void close({bool force = false}) {}
}

Future<void> waitFor(ProgressAdapter adapter, int count) async {
  for (var attempt = 0;
      attempt < 100 && adapter.observed.length < count;
      attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(adapter.observed.length, count);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late ProgressAdapter adapter;
  late ProgressRepository repository;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared
        .saveTokens(accessToken: token('progress-alice'), refreshToken: 'test');
    adapter = ProgressAdapter();
    repository = ProgressRepository();
    await repository.invalidate();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
  });

  test(
      'Concurrent requests share a fetch and fresh cache avoids another request',
      () async {
    final first = repository.load('', '4w');
    final second = repository.load('', '4w');
    await waitFor(adapter, 1);
    adapter.complete(0, 10);
    expect((await first)['value'], 10);
    expect((await second)['value'], 10);
    expect((await repository.load('', '4w'))['value'], 10);
    expect(adapter.observed.length, 1);
  });

  test('An edit invalidates pending data and preserves the newer request',
      () async {
    final old = repository.load('', '4w');
    final failure = expectLater(old, throwsStateError);
    await waitFor(adapter, 1);
    await repository.invalidate();
    final newer = repository.load('', '4w');
    await waitFor(adapter, 2);
    adapter.complete(0, 1);
    await failure;
    final duplicate = repository.load('', '4w');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(adapter.observed.length, 2);
    adapter.complete(1, 2);
    expect((await newer)['value'], 2);
    expect((await duplicate)['value'], 2);
    expect((await repository.cached('', '4w'))!['value'], 2);
  });

  test('A response for a previous account cannot populate the new account',
      () async {
    final old = repository.load('', '4w');
    final failure = expectLater(old, throwsA(anything));
    await waitFor(adapter, 1);
    await SecureSessionStore.shared
        .saveTokens(accessToken: token('progress-bob'), refreshToken: 'test');
    adapter.complete(0, 99);
    await failure;
    expect(await repository.cached('', '4w'), isNull);
  });

  test('Exercise pins remain scoped to their account and limited to three',
      () async {
    for (final id in ['one', 'two', 'three']) {
      await repository.pin(id);
    }
    await expectLater(repository.pin('four'), throwsFormatException);
    expect(await repository.pins(), ['one', 'two', 'three']);
    await repository.setPinned('two', false);
    await repository.setPinned('four', true);
    expect(await repository.pins(), ['one', 'three', 'four']);
    await SecureSessionStore.shared
        .saveTokens(accessToken: token('progress-bob'), refreshToken: 'test');
    expect(await repository.pins(), isEmpty);
  });

  test('A previous language response cannot refill the selected language cache',
      () async {
    await LanguageManager.shared.selectLanguage(AppLanguage.uk);
    final old = repository.load('', '4w');
    final failure = expectLater(old, throwsStateError);
    await waitFor(adapter, 1);
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    final german = repository.load('', '4w');
    await waitFor(adapter, 2);
    adapter.complete(0, 99);
    await failure;
    adapter.complete(1, 25);
    expect((await german)['value'], 25);
    expect((await repository.cached('', '4w'))!['value'], 25);
    expect(adapter.observed.last.headers['Accept-Language'], 'de');
    await LanguageManager.shared.selectLanguage(AppLanguage.uk);
    expect(await repository.cached('', '4w'), isNull);
  });
}
