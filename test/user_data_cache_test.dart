import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/features/nutrition/repositories/nutrition_repository.dart';
import 'dart:async';
import 'dart:convert';

import 'package:setcraft/core/cache/user_data_cache.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String token(String owner) =>
    '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.test';

class _NutritionAdapter implements HttpClientAdapter {
  int catalogReads = 0;
  bool logged = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    // Home refresh is a separate dependency. Keep it offline in this repository
    // test so it cannot initialize the platform SQLite cache.
    if (options.path.startsWith('/api/home')) {
      return ResponseBody.fromString('{"error":"offline fixture"}', 503,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/me/log')) logged = true;
    final catalog = options.path == '/api/nutrition/catalog';
    if (catalog) catalogReads++;
    return ResponseBody.fromString(
        jsonEncode({
          'data': catalog
              ? {
                  'foods': logged
                      ? [
                          {
                            'id': 'cache-food',
                            'name': 'Boiled egg',
                            'category': 'PROTEIN_SOURCE'
                          }
                        ]
                      : [],
                  'page': 1,
                  'total': logged ? 1 : 0,
                  'totalPages': 1,
                  'hasNextPage': false,
                }
              : {}
        }),
        options.method == 'POST' ? 201 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var account = 0;

  Future<void> signIn(String owner) => SecureSessionStore.shared
      .saveTokens(accessToken: token(owner), refreshToken: 'test');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await signIn('cache-test-${account++}');
    await LanguageManager.shared.restoreAccountLanguage('en');
  });

  test('logging an everyday food immediately refreshes the Recent cache',
      () async {
    final adapter = _NutritionAdapter();
    final original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final repository = NutritionRepository.shared;
    expect((await repository.getFoodPage(source: 'RECENT')).foods, isEmpty);
    await repository.getFoodPage(source: 'RECENT');
    expect(adapter.catalogReads, 1);
    expect(
        await repository.logMeal(
            nutritionId: 'cache-food', mealType: 'BREAKFAST'),
        isTrue);
    expect((await repository.getFoodPage(source: 'RECENT')).foods.single.name,
        'Boiled egg');
    expect(adapter.catalogReads, 2);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  test('changing language preserves the selected country', () async {
    final draft = await OnboardingDraft.load();
    draft.countryCode = 'FR';
    await draft.save();
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    final changed = await OnboardingDraft.load();
    expect(changed.countryCode, 'FR');
    expect(changed.languageCode, 'de');
  });

  test('fresh entries reuse data; refresh and expiry request new data',
      () async {
    var reads = 0;
    Future<Map<String, dynamic>> fetch() async => {'value': ++reads};
    final cache = UserDataCache.shared;
    expect((await cache.load('test', 'page', fetch))['value'], 1);
    expect((await cache.load('test', 'page', fetch))['value'], 1);
    expect(
        (await cache.load('test', 'page', fetch, refresh: true))['value'], 2);
    expect(
        (await cache.load('test', 'page', fetch, ttl: Duration.zero))['value'],
        3);
  });

  test('simultaneous requests share one fetch', () async {
    final gate = Completer<Map<String, dynamic>>();
    var reads = 0;
    Future<Map<String, dynamic>> fetch() {
      reads++;
      return gate.future;
    }

    final first = UserDataCache.shared.load('test', 'parallel', fetch);
    final second = UserDataCache.shared.load('test', 'parallel', fetch);
    await Future<void>.delayed(Duration.zero);
    gate.complete({'value': 1});
    expect(await first, await second);
    expect(reads, 1);
  });

  test('account and language changes cannot reuse another scope', () async {
    var reads = 0;
    Future<Map<String, dynamic>> fetch() async => {'value': ++reads};
    final cache = UserDataCache.shared;
    await cache.load('test', 'scope', fetch);
    await LanguageManager.shared.restoreAccountLanguage('de');
    expect((await cache.load('test', 'scope', fetch))['value'], 2);
    await signIn('different-cache-account-${account++}');
    expect((await cache.load('test', 'scope', fetch))['value'], 3);
  });

  test('invalidated in-flight reads cannot overwrite a confirmed change',
      () async {
    final gate = Completer<Map<String, dynamic>>();
    final started = Completer<void>();
    final first = UserDataCache.shared.load('test', 'race', () {
      started.complete();
      return gate.future;
    });
    final rejected = expectLater(first, throwsStateError);
    await started.future;
    await UserDataCache.shared.invalidate('test');
    await UserDataCache.shared.load('test', 'race', () async => {'value': 2});
    gate.complete({'value': 1});
    await rejected;
    expect(
        (await UserDataCache.shared
            .load('test', 'race', () async => {'value': 3}))['value'],
        2);
  });
}
