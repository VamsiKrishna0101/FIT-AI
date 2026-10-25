import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/localization/language_manager.dart';
import 'package:fitai_mobile/core/localization/app_language.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/train/models/workout_exercise_models.dart';
import 'package:fitai_mobile/features/train/repositories/workout_repository.dart';
import 'package:fitai_mobile/features/train/views/exercise_library_view.dart';
import 'package:fitai_mobile/features/train/views/exercise_detail_view.dart';
import 'package:fitai_mobile/features/train/views/today_plan_view.dart';
import 'package:fitai_mobile/features/train/components/add_exercise_sheet.dart';
import 'package:fitai_mobile/features/today/models/session_guidance.dart';

Map<String, dynamic> _exercise(String id, String locale) => {
      'id': id,
      'name': locale == 'fr'
          ? 'Développé avec haltères'
          : locale == 'de-CH'
              ? 'Kurzhantel-Bankdrücken'
              : 'Dumbbell press',
      'canonicalName': 'Dumbbell press',
      'bodyPart': 'Chest',
      'target': 'Pectorals',
      'equipment': 'Dumbbell',
      'difficulty': 'BEGINNER',
      'category': 'Chest',
      'description': 'A controlled press.',
      'instructions': locale == 'de-CH'
          ? ['Drücke die Hanteln kontrolliert nach oben.']
          : ['Press the weights with control.'],
      'contentLanguage': locale == 'de-CH' ? 'de' : locale,
    };

class _Adapter implements HttpClientAdapter {
  final catalogueLocales = <String>[];
  final pageQueries = <Map<String, dynamic>>[];
  final detailQueries = <Map<String, dynamic>>[];
  bool failPages = false;
  final heldSearches = <String, Completer<void>>{};
  bool failMutations = false;
  Map<String, dynamic>? customPayload;
  Completer<void>? delaySpanish;
  Completer<void>? delayProfile;
  final statuses = <String, String>{};
  final mutations = <String>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final locale = options.headers['Accept-Language'].toString();
    Object data;
    var status = 200;
    if (options.path == '/api/workout/exercises') {
      catalogueLocales.add(locale);
      if (locale == 'es' && delaySpanish != null) await delaySpanish!.future;
      if (options.queryParameters['page'] != null) {
        final query = Map<String, dynamic>.from(options.queryParameters);
        pageQueries.add(query);
        final search = query['search'] as String? ?? '';
        if (heldSearches[search] != null) await heldSearches[search]!.future;
        status = failPages ? 503 : 200;
        final rows = List.generate(
                49,
                (i) => {
                      ..._exercise('paged-$i', locale),
                      'name': 'Exercise $i',
                      'canonicalName': 'Exercise $i',
                      'bodyPart': i.isEven ? 'Chest' : 'Back',
                      'target': i.isEven ? 'Pectorals' : 'Lats',
                      'equipment': i.isEven ? 'Dumbbell' : 'Band',
                      'mediaVariants': {
                        if (i % 3 != 1)
                          'male': {'url': 'https://example.test/male-$i.mp4'},
                        if (i % 3 != 0)
                          'female': {
                            'url': 'https://example.test/female-$i.mp4'
                          },
                      },
                    })
            .where((e) =>
                (query['mediaGender'] == null ||
                    (e['mediaVariants'] as Map)
                        .containsKey(query['mediaGender'])) &&
                (query['bodyPart'] == null ||
                    e['bodyPart'] == query['bodyPart']) &&
                (query['equipment'] == null ||
                    e['equipment'] == query['equipment']) &&
                ['name', 'bodyPart', 'target', 'equipment'].any((field) =>
                    (e[field] as String)
                        .toLowerCase()
                        .contains(search.toLowerCase())))
            .toList();
        final page = query['page'] as int, size = query['pageSize'] as int;
        data = {
          'data': rows
              .skip((page - 1) * size)
              .take(size)
              .map((row) => {
                    ...row,
                    if (query['mediaGender'] != null)
                      'url': (row['mediaVariants'] as Map)[query['mediaGender']]
                          ['url'],
                  })
              .toList(),
          'pagination': {
            'page': page,
            'total': rows.length,
            'totalPages': (rows.length / size).ceil()
          },
          'filters': {
            'bodyParts': [
              {'value': 'Back', 'label': 'Back'},
              {'value': 'Chest', 'label': 'Chest'}
            ],
            'equipment': [
              {'value': 'Band', 'label': 'Band'},
              {'value': 'Dumbbell', 'label': 'Dumbbell'}
            ]
          }
        };
      } else {
        data = {
          'data': [_exercise('one', locale), _exercise('two', locale)]
        };
      }
    } else if (options.path.startsWith('/api/workout/exercises/')) {
      detailQueries.add(Map<String, dynamic>.from(options.queryParameters));
      data = {
        'data': {
          ..._exercise('one', locale),
          if (options.queryParameters['mediaGender'] != null)
            'url':
                'https://example.test/${options.queryParameters['mediaGender']}.mp4'
        }
      };
    } else if (options.path.startsWith('/api/workout/me/')) {
      data = {
        'data': {
          'id': 'plan',
          'weekLabel': '2026-W41',
          'status': 'IN_PROGRESS',
          'items': [
            {
              'id': 'item',
              'status': statuses['item'] ?? 'NOT_STARTED',
              'targetSets': 3,
              'targetReps': '10',
              'targetWeight': 0,
              'restSeconds': 60,
              'workout': _exercise('one', locale)
            }
          ]
        }
      };
    } else if (options.path == '/api/workout/item') {
      customPayload = Map<String, dynamic>.from(options.data as Map);
      status = 201;
      data = {
        'data': {'id': 'custom-item'}
      };
    } else if (options.path.startsWith('/api/workout/item/')) {
      mutations.add(options.path);
      status = failMutations ? 503 : 200;
      if (!failMutations) {
        statuses['item'] = options.path.endsWith('/complete')
            ? 'COMPLETED'
            : options.path.endsWith('/skip')
                ? 'SKIPPED'
                : 'NOT_STARTED';
      }
      data = {'error': 'Synthetic failure'};
    } else if (options.path == '/api/home') {
      data = {};
    } else if (options.path == '/api/onboarding') {
      if (options.method == 'GET' && delayProfile != null) {
        await delayProfile!.future;
      }
      status = failMutations ? 503 : 200;
      data = {
        'data': {'language': options.data?['language'] ?? 'fr'}
      };
    } else {
      throw StateError('Unexpected test endpoint ${options.path}');
    }
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

Widget _app(Widget page, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de'), Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF111111),
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                    key: const ValueKey('preview'), child: page))));
Future<void> _capture(WidgetTester tester, String filename) async {
  await tester.pump(const Duration(milliseconds: 150));
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/$filename').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: 'synthetic',
        refreshToken: 'synthetic',
        userId: 'exercise-test');
    await LanguageManager.shared.restoreAccountLanguage('en');
    await WorkoutRepository.shared.invalidateExerciseMedia();
  });
  test('catalogues are language scoped and preserve variants sharing a name',
      () async {
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final repo = WorkoutRepository.shared;
    expect((await repo.getAllExercises(forceRefresh: true)).length, 2);
    await LanguageManager.shared.restoreAccountLanguage('fr');
    expect(repo.cachedCatalog, isNull);
    expect(
        (await repo.getAllExercises()).first.name, 'Développé avec haltères');
    await LanguageManager.shared.restoreAccountLanguage('en');
    expect((await repo.getAllExercises()).first.name, 'Dumbbell press');
    expect(adapter.catalogueLocales, ['en', 'fr']);
    await LanguageManager.shared.restoreAccountLanguage('es');
    adapter.delaySpanish = Completer<void>();
    final stale = repo.getAllExercises(forceRefresh: true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await LanguageManager.shared.restoreAccountLanguage('de-CH');
    adapter.delaySpanish!.complete();
    expect(await stale, isEmpty);
    expect((await repo.getExerciseDetail('one'))!.instructions,
        ['Drücke die Hanteln kontrolliert nach oben.']);
  });
  test('failed completion and target edits roll back the cached plan',
      () async {
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final repo = WorkoutRepository.shared;
    await repo.getTodayWorkoutPlan(forceRefresh: true);
    adapter.failMutations = true;
    expect(await repo.markItemComplete('item'), isFalse);
    expect(repo.currentPlan!.items.first.status, 'NOT_STARTED');
    expect(repo.currentPlan!.items.first.completedAt, isNull);
    expect(await repo.updateWorkoutItem('item', targetSets: 9), isFalse);
    expect(repo.currentPlan!.items.first.targetSets, 3);
  });
  testWidgets('list actions persist, undo and sync with the open form guide',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await tester.runAsync(
        () => WorkoutRepository.shared.getTodayWorkoutPlan(forceRefresh: true));
    await tester.pumpWidget(_app(const TodayPlanView()));
    await tester.pumpAndSettle();
    await _capture(tester, 'today-workout-preview.png');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('1 of 1 completed'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(
        WorkoutRepository.shared.currentPlan!.items.first.completedAt, isNull);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Skipped'), findsOneWidget);
    expect(find.text('0 of 1 completed'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    adapter.failMutations = true;
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
    adapter.failMutations = false;
    await tester.tap(find.text('Dumbbell press'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailView), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(adapter.mutations.where((path) => path.endsWith('/skip')).length, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('German workout actions fit a small phone with larger text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.reset);
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await LanguageManager.shared.restoreAccountLanguage('de');
    await tester.runAsync(
        () => WorkoutRepository.shared.getTodayWorkoutPlan(forceRefresh: true));
    await tester
        .pumpWidget(_app(const TodayPlanView(), locale: 'de', scale: 1.6));
    await tester.pumpAndSettle();
    expect(find.text('Training heute'), findsOneWidget);
    expect(find.text('Fertig'), findsOneWidget);
    expect(find.text('Überspringen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'today-workout-german-preview.png');
  });
  test('failed account language saves preserve the current selection',
      () async {
    final adapter = _Adapter()..failMutations = true,
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await expectLater(
        LanguageManager.shared
            .selectLanguage(AppLanguage.france, persistAccount: true),
        throwsA(isA<DioException>()));
    expect(LanguageManager.shared.currentLanguage, AppLanguage.uk);
    expect(LanguageManager.shared.saving, isFalse);
    adapter.failMutations = false;
    await LanguageManager.shared
        .selectLanguage(AppLanguage.france, persistAccount: true);
    expect(LanguageManager.shared.currentLanguage, AppLanguage.france);
  });
  test(
      'translated effort notes preserve the plan effort without deriving readiness',
      () {
    final note = SessionGuidance.fromNote(
        'Zielanstrengung: 8,5/10 — Passe die Belastung an.',
        fallback: 'Fallback');
    expect(note.effort, 8.5);
    expect(note.summary, 'Passe die Belastung an.');
  });
  test('a delayed profile restore cannot undo a newer language selection',
      () async {
    final adapter = _Adapter()..delayProfile = Completer<void>(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    final pending = LanguageManager.shared.syncAccountLanguage();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    adapter.delayProfile!.complete();
    await pending;
    expect(LanguageManager.shared.currentLanguage, AppLanguage.germany);
  });
  testWidgets(
      'library pages and dropdown filters query the server and reset to page one',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await tester.pumpWidget(_app(ExerciseLibraryView(onExerciseAdded: () {})));
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.single['pageSize'], 24);
    expect(find.text('Page 1 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-0')), findsOneWidget);
    await _capture(tester, 'exercise-library-paginated-preview.png');
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.last['page'], 2);
    expect(find.text('Page 2 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-24')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.last['bodyPart'], 'Back');
    expect(adapter.pageQueries.last['page'], 1);
    expect(find.text('Page 1 of 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dumbbell').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.text('No exercises found'), findsOneWidget);
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 3'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'Exercise 40');
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.last['search'], 'Exercise 40');
    expect(find.byKey(const ValueKey('exercise-paged-40')), findsOneWidget);
    adapter.failPages = true;
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'offline');
    await tester.pumpAndSettle();
    expect(find.text('Could not load exercises.'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-40')), findsNothing);
    adapter.failPages = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No exercises found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'chest search includes presses and flies across pages and exposes active filters',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await WorkoutRepository.shared.invalidateExerciseMedia();
    await tester.pumpWidget(_app(ExerciseLibraryView(onExerciseAdded: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'chest');
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.last['page'], 1);
    expect(adapter.pageQueries.last['search'], 'chest');
    expect(find.text('25 exercises'), findsOneWidget);
    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-0')), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, false);
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pumpAndSettle();
    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-48')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dumbbell').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    final chip = find.byKey(const ValueKey('active-equipment-filter'));
    expect(chip, findsOneWidget);
    await tester
        .tap(find.descendant(of: chip, matching: find.byTooltip('Delete')));
    await tester.pumpAndSettle();
    expect(chip, findsNothing);
    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.text('25 exercises'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'library ignores an old search response and fits small enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await tester.pumpWidget(
        _app(ExerciseLibraryView(onExerciseAdded: () {}), scale: 1.8));
    await tester.pumpAndSettle();
    await _capture(tester, 'exercise-library-small-preview.png');
    final hold = Completer<void>();
    adapter.heldSearches['Exercise 47'] = hold;
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'Exercise 47');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'Exercise 48');
    await tester.pumpAndSettle();
    hold.complete();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-paged-48')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-47')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'demo filters stay scoped through searches, reset and detail caches',
      (tester) async {
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await tester.pumpWidget(_app(ExerciseLibraryView(onExerciseAdded: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-filter-male')));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.last['mediaGender'], 'male');
    expect(find.text('33 exercises'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-1')), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'chest');
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.last['mediaGender'], 'male');
    expect(find.text('17 exercises'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-filter-female')));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.last['mediaGender'], 'female');
    expect(find.text('16 exercises'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-paged-0')), findsNothing);
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    // Reset can reuse the previously loaded unfiltered page without a new request.
    expect(find.byKey(const ValueKey('active-demo-filter')), findsNothing);
    expect(find.text('49 exercises'), findsOneWidget);
    final male = await tester.runAsync(() =>
        WorkoutRepository.shared.getExerciseDetail('one', mediaGender: 'male'));
    final female = await tester.runAsync(() => WorkoutRepository.shared
        .getExerciseDetail('one', mediaGender: 'female'));
    expect(male?.url, endsWith('/male.mp4'));
    expect(female?.url, endsWith('/female.mp4'));
    expect(
        adapter.detailQueries.map((q) => q['mediaGender']), ['male', 'female']);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'typing retains rows, debounces requests and ignores cursor changes',
      (tester) async {
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    await tester.pumpWidget(_app(ExerciseLibraryView(onExerciseAdded: () {})));
    await tester.pumpAndSettle();
    final before = adapter.pageQueries.length;
    final search = find.byKey(const ValueKey('exercise-search'));
    await tester.enterText(search, 'c');
    await tester.pump(const Duration(milliseconds: 80));
    await tester.enterText(search, 'ch');
    await tester.pump(const Duration(milliseconds: 80));
    expect(adapter.pageQueries.length, before);
    expect(find.byKey(const ValueKey('exercise-paged-0')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('exercise-search-progress')), findsOneWidget);
    await tester.enterText(search, 'chest');
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.length, before + 1);
    final controller = tester.widget<TextField>(search).controller!;
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pumpAndSettle();
    expect(adapter.pageQueries.length, before + 1);
    expect(find.text('25 exercises'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'premium library searches translated names and fits enlarged text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final exercises = [
      WorkoutExerciseModel.fromJson(_exercise('one', 'fr')),
      WorkoutExerciseModel.fromJson({
        ..._exercise('two', 'en'),
        'name': 'Barbell squat',
        'bodyPart': 'Upper Legs',
        'target': 'Quads'
      })
    ];
    await tester.pumpWidget(_app(
        ExerciseLibraryView(
            initialExercises: exercises, onExerciseAdded: () {}),
        locale: 'fr'));
    await tester.pumpAndSettle();
    expect(find.text('Exercices'), findsOneWidget);
    await _capture(tester, 'exercise-library-preview.png');
    await tester.enterText(
        find.byKey(const ValueKey('exercise-search')), 'développé');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-one')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-two')), findsNothing);
    await tester.pumpWidget(_app(
        ExerciseLibraryView(
            initialExercises: exercises, onExerciseAdded: () {}),
        scale: 1.6));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'full form guide stays readable and a failed add keeps detail open',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final exercise = WorkoutExerciseModel.fromJson({
      ..._exercise('one', 'en'),
      'instructions': [
        'Lie on a flat bench with your feet on the floor.',
        'Hold the dumbbells beside your chest.',
        'Press upwards with control, then lower to the starting position.'
      ]
    });
    await tester.pumpWidget(_app(ExerciseDetailView(
        exercise: exercise,
        loadDetail: false,
        onAddToPlan: () async => false)));
    await tester.pumpAndSettle();
    await _capture(tester, 'exercise-detail-preview.png');
    await tester.tap(find.text('Add to today'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailView), findsOneWidget);
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Press upwards with control, then lower to the starting position.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('custom exercises use canonical difficulty and fit small phones',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    final adapter = _Adapter(),
        original = ApiClient.shared.client.httpClientAdapter;
    ApiClient.shared.client.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.shared.client.httpClientAdapter = original);
    var added = 0;
    await tester.pumpWidget(_app(
        Scaffold(
            body: AddExerciseSheet(
                startCustom: true, onExerciseAdded: () => added++)),
        scale: 1.3));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'My controlled row');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back').last);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.scrollUntilVisible(find.text('Create exercise'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create exercise'));
    await tester.pumpAndSettle();
    expect(adapter.customPayload?['customExercise']['difficulty'], 'BEGINNER');
    expect(adapter.customPayload?['customExercise']['bodyPart'], 'Back');
    expect(added, 1);
    expect(tester.takeException(), isNull);
  });
}
