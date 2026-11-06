import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/cache/user_data_cache.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/progress/components/progress_photos.dart';
import 'package:setcraft/features/progress/repositories/progress_photo_repository.dart';

String token(String owner) =>
    '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({
          'userId': owner
        })))}.test';

class PhotoAdapter implements HttpClientAdapter {
  int calls = 0;
  bool fail = false;
  List<Map<String, dynamic>> photos = [];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    calls++;
    return ResponseBody.fromString(
        jsonEncode(fail
            ? {'error': 'Unavailable'}
            : {'photos': photos, 'nextCursor': null}),
        fail ? 503 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late PhotoAdapter adapter;
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared
        .saveTokens(accessToken: token('photo-alice'), refreshToken: 'test');
    adapter = PhotoAdapter();
    ApiClient.shared.client.httpClientAdapter = adapter;
    await UserDataCache.shared.invalidate('progress_photos');
  });
  test('Prompt is claimed once per user and date', () async {
    final repo = ProgressPhotoRepository();
    expect(await repo.claimPrompt('2026-11-05'), isTrue);
    expect(await repo.claimPrompt('2026-11-05'), isFalse);
    expect(await repo.claimPrompt('2026-11-06'), isTrue);
    await SecureSessionStore.shared
        .saveTokens(accessToken: token('photo-bob'), refreshToken: 'test');
    expect(await repo.claimPrompt('2026-11-05'), isTrue);
  });
  test('Photo requests share cache and stay scoped by language and account',
      () async {
    final repo = ProgressPhotoRepository();
    await Future.wait([repo.load(), repo.load()]);
    expect(adapter.calls, 1);
    await repo.load();
    expect(adapter.calls, 1);
    await LanguageManager.shared.restoreAccountLanguage('de');
    addTearDown(() => LanguageManager.shared.restoreAccountLanguage('en'));
    await repo.load();
    expect(adapter.calls, 2);
    await SecureSessionStore.shared.saveTokens(
        accessToken: token('photo-cache-bob'), refreshToken: 'test');
    await repo.load();
    expect(adapter.calls, 3);
    await repo.delete('test-photo');
    await repo.load();
    expect(adapter.calls, 5);
  });
  testWidgets('Progress plus opens manual photo capture without a workout',
      (tester) async {
    adapter.photos = [
      {
        'id': 'photo',
        'recordedDate': '2026-11-05',
        'url': 'https://example.invalid/photo.jpg',
        'thumbnailUrl': 'https://example.invalid/thumb.jpg'
      }
    ];
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: ProgressPhotoShelf())));
    await tester.pumpAndSettle();
    expect(find.text('Progress photos'), findsOneWidget);
    expect(find.text('View all progress photos'), findsNothing);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('progress-photo-shelf')))
            .height,
        lessThan(190));
    await tester.tap(find.byTooltip('Add progress photo'));
    await tester.pumpAndSettle();
    expect(find.text('Capture your progress.'), findsOneWidget);
    expect(find.text('Your effort. Captured.'), findsNothing);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from library'), findsOneWidget);
    expect(find.text('Maybe later'), findsOneWidget);
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsNothing);
  });
  testWidgets('Gallery plus also opens manual photo capture', (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(), home: const ProgressPhotoGallery()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add progress photo'));
    await tester.pumpAndSettle();
    expect(find.text('Capture your progress.'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from library'), findsOneWidget);
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Photo shelf stays hidden when empty or unavailable',
      (tester) async {
    adapter.fail = true;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: ProgressPhotoShelf())));
    await tester.pumpAndSettle();
    expect(find.text('Progress photos'), findsNothing);
    expect(find.text('Retry'), findsNothing);
    adapter.fail = false;
    ProgressPhotoRepository.shared.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Progress photos'), findsNothing);
    expect(find.byTooltip('Add progress photo'), findsNothing);
  });
  testWidgets('Post workout sheet fits a phone and exposes optional actions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const preview = ValueKey('photo-prompt-preview');
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            RepaintBoundary(key: preview, child: child!),
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        home: Scaffold(
            backgroundColor: Colors.black,
            body: Builder(
                builder: (context) => Center(
                    child: TextButton(
                        onPressed: () => showProgressPhotoCapture(context,
                            afterWorkout: true),
                        child: const Text('Workout complete',
                            style: TextStyle(color: Colors.white))))))));
    await tester.tap(find.text('Workout complete'));
    await tester.pumpAndSettle();
    expect(find.text('Your effort. Captured.'), findsOneWidget);
    expect(
        find.text('Add a photo now, or later from Today → Update your stats.'),
        findsOneWidget);
    expect(find.textContaining('Optional.'), findsNothing);
    expect(find.text('Take a photo').hitTestable(), findsOneWidget);
    expect(find.text('Maybe later').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester
        .renderObject<RenderRepaintBoundary>(find.byKey(preview))
        .markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(preview))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/progress-photo-prompt.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
