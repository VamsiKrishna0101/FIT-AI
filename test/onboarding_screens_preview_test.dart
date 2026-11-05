// Run after the starter integration check to capture the real catalogue posters.
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/features/onboarding/views/starter_plan_view.dart';
import 'exercise_thumbnail_test.dart' show LocalPosterCache;
import 'starter_plan_view_test.dart' show StarterRepo, TrialService;
import 'plan_reveal_flow_test.dart' show app, phone, capture, profile;

void main() {
  final source =
      File('../backend/build/planner-review/starter-preview-female.json');
  testWidgets(
      'Capture the visual plan and separate trial membership with real posters',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'opaque', 'fitai_user_id': 'preview-owner'});
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    final cacheDirectory = Directory('build/previews/poster-cache')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => cacheDirectory.absolute.path);
    phone(tester);
    final preview =
        jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
    final samples = (preview['firstWorkout'] as Map)['exercises'] as List;
    final paths = <String, String>{
      for (var i = 0; i < samples.length; i++)
        samples[i]['exercise']['thumbnailUrl'] as String:
            File('build/previews/starter-exercise-$i.jpg').absolute.path
    };
    final previous = CachedNetworkImageProvider.defaultCacheManager;
    CachedNetworkImageProvider.defaultCacheManager = LocalPosterCache(paths);
    addTearDown(
        () => CachedNetworkImageProvider.defaultCacheManager = previous);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    for (final url in paths.keys) {
      await tester.runAsync(() => precacheImage(
          ResizeImage.resizeIfNeeded(88, null, CachedNetworkImageProvider(url)),
          tester.element(find.byType(SizedBox))));
    }
    final repo = StarterRepo();
    (repo.value['plan'] as Map)['preview'] = preview;
    await tester.pumpWidget(app(StarterPlanView(
        requestAiConsent: (_) async => true,
        repository: repo,
        subscription: TrialService(),
        profileLoader: () async => profile,
        onComplete: (_) {})));
    await tester.pumpAndSettle();
    await capture(tester, 'starter-visual-plan');
    await tester.tap(find.byKey(const ValueKey('starter-unlock')));
    await tester.pumpAndSettle();
    await capture(tester, 'starter-trial-membership');
    expect(find.text('Day 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  },
      skip: !source.existsSync() ||
          !File('build/previews/starter-exercise-0.jpg').existsSync());
}
