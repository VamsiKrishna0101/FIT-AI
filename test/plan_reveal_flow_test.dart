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
import 'package:setcraft/core/cache/cache_scope.dart';
import 'package:setcraft/core/components/liquid_chrome_button.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/features/onboarding/components/starter_plan_reveal.dart';
import 'package:setcraft/features/onboarding/views/onboarding_view.dart';
import 'package:setcraft/features/onboarding/views/goal_selection_view.dart';
import 'package:setcraft/features/onboarding/views/starter_plan_view.dart';
import 'package:setcraft/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:setcraft/features/subscription/subscription_view.dart';
import 'package:setcraft/features/train/components/graphite_anatomy.dart';
import 'package:setcraft/features/train/models/training_session.dart';
import 'package:setcraft/features/train/views/workout_session_view.dart';
import 'package:setcraft/features/planner/views/widgets/weekly_plan_schedule.dart';
import 'starter_plan_view_test.dart' show StarterRepo, TrialService;
import 'training_session_test.dart' as session;

const _preview = ValueKey('plan-reveal-preview');
const profile = <String, dynamic>{
  'name': 'Nora Adams',
  'gender': 'FEMALE',
  'workingToward': 'BUILD_MUSCLE',
  'experience': 'BEGINNER',
  'trainingLocation': 'HOME',
  'equipmentIds': ['dumbbells'],
  'focusMuscles': ['chest', 'triceps']
};
Widget app(Widget child,
        {bool reduced = true, double scale = 1, String language = 'en'}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(language),
        supportedLocales: const [Locale('en'), Locale('de'), Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    disableAnimations: reduced,
                    textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(key: _preview, child: child))));
void phone(WidgetTester tester, [Size size = const Size(393, 852)]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> capture(WidgetTester tester, String name) =>
    tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(_preview))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
Future<void> artwork(WidgetTester tester) async {
  await tester.runAsync(() => precacheImage(
      const AssetImage(graphiteAnatomyAsset),
      tester.element(find.byType(StarterPlanReveal))));
  await tester.pumpAndSettle();
}

class SessionAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
          Future<void>? cancel) async =>
      ResponseBody.fromString(
          jsonEncode({
            'data': options.path.contains('/previous/')
                ? {'sets': []}
                : session.fixture(CacheScope.todayKey())
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'opaque', 'fitai_user_id': 'reveal-test'});
  });
  testWidgets(
      'Welcome animates briefly, leaves Get started usable, and does not sell a trial',
      (tester) async {
    phone(tester);
    final model = OnboardingController();
    await model.initialize();
    await tester
        .pumpWidget(app(OnboardingView(controller: model), reduced: false));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('welcome-goal-1')))
            .opacity,
        lessThan(1));
    expect(
        tester
            .widget<LiquidChromeButton>(find.byType(LiquidChromeButton))
            .onPressed,
        isNotNull);
    expect(find.text('Build my plan'), findsNothing);
    expect(find.textContaining('14-day trial'), findsNothing);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(GoalSelectionView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
  testWidgets(
      'Reduced motion shows the complete welcome immediately and captures the entry',
      (tester) async {
    phone(tester);
    final model = OnboardingController();
    await model.initialize();
    await tester.pumpWidget(app(OnboardingView(controller: model)));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(
          tester
              .widget<Opacity>(find.byKey(ValueKey('welcome-goal-$i')))
              .opacity,
          1);
    }
    await tester.runAsync(() => precacheImage(
        const AssetImage('assets/branding/setcraft-training-hero-v1.png'),
        tester.element(find.byType(OnboardingView))));
    await tester.pumpAndSettle();
    await capture(tester, 'welcome-get-started');
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
  testWidgets(
      'Personal reveal shows the whole recommended week and only two exercises before checkout',
      (tester) async {
    phone(tester);
    final repo = StarterRepo(), service = TrialService();
    final preview = (repo.value['plan'] as Map)['preview'] as Map;
    final days = preview['workouts'] as List;
    final names = [
      'Chest + Triceps',
      'Rest day',
      'Back + Biceps',
      'Rest day',
      'Legs + Glutes',
      'Rest day',
      'Shoulders + Core'
    ];
    for (var n = 0; n < days.length; n++) {
      (days[n] as Map)['name'] = names[n];
    }
    final firstWorkout = preview['firstWorkout'] as Map;
    firstWorkout['name'] = 'Chest + Triceps';
    ((firstWorkout['exercises'] as List)[1] as Map)['name'] =
        'Triceps extension';
    String? opened;
    await tester.pumpWidget(app(StarterPlanView(
        repository: repo,
        subscription: service,
        profileLoader: () async => profile,
        onComplete: (id) => opened = id)));
    await tester.pumpAndSettle();
    expect(find.text('Nora, your plan is ready'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Dumbbells'), findsNothing);
    expect(find.text('Your recommended week'), findsOneWidget);
    for (var day = 19; day <= 25; day++) {
      expect(find.byKey(ValueKey('starter-day-2026-10-$day')), findsOneWidget);
    }
    expect(find.text('Rest day'), findsNWidgets(3));
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('starter-day-2026-10-19')),
            matching: find.text('Chest + Triceps')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('starter-day-2026-10-21')),
            matching: find.text('Back + Biceps')),
        findsOneWidget);
    expect(find.text('Dumbbell row'), findsNothing);
    expect(find.byType(GraphiteMuscleFigure), findsNothing);
    expect(service.starts, 0);
    expect(repo.activations, 0);
    await capture(tester, 'personal-plan-reveal');
    final first = find.byKey(const ValueKey('starter-first-workout'));
    expect(
        find.descendant(of: first, matching: find.text('Dumbbell floor press')),
        findsOneWidget);
    expect(find.descendant(of: first, matching: find.text('Triceps extension')),
        findsOneWidget);
    expect(find.text('Unlock your full plan'), findsOneWidget);
    await tester.scrollUntilVisible(first, 250,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await capture(tester, 'personal-plan-workout-preview');
    await tester.scrollUntilVisible(find.text('Muscle focus'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Muscle focus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muscle focus'));
    await artwork(tester);
    expect(find.byType(GraphiteMuscleFigure), findsNWidgets(2));
    for (final figure in tester
        .widgetList<GraphiteMuscleFigure>(find.byType(GraphiteMuscleFigure))) {
      expect(figure.female, true);
      expect(figure.primary, {'chest', 'triceps'});
    }
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(repo.activations, 0);
    await tester.tap(find.byKey(const ValueKey('membership-close')));
    await tester.pumpAndSettle();
    expect(opened, isNull);
    expect(find.text('Unlock my plan'), findsOneWidget);
  });
  testWidgets(
      'A late profile response from another account never personalizes this preview',
      (tester) async {
    phone(tester);
    final pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(app(StarterPlanView(
        repository: StarterRepo(),
        subscription: TrialService(),
        profileLoader: () => pending.future,
        onComplete: (_) {})));
    await tester.pumpAndSettle();
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'other', 'fitai_user_id': 'other-owner'});
    pending.complete(profile);
    await tester.pumpAndSettle();
    expect(find.text('Nora, your plan is ready'), findsNothing);
    expect(find.byType(GraphiteMuscleFigure), findsNothing);
  });
  testWidgets('The male reveal uses the saved body style and training goal',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(StarterPlanView(
        repository: StarterRepo(),
        subscription: TrialService(),
        profileLoader: () async => {
              ...profile,
              'name': 'Alex',
              'gender': 'MALE',
              'workingToward': 'GET_STRONGER',
              'focusMuscles': ['chest', 'back'],
            },
        onComplete: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('Get stronger'), findsOneWidget);
    await capture(tester, 'personal-plan-reveal-male');
    await tester.scrollUntilVisible(find.text('Muscle focus'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Muscle focus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muscle focus'));
    await artwork(tester);
    expect(find.byType(GraphiteMuscleFigure), findsNWidgets(2));
    for (final figure in tester
        .widgetList<GraphiteMuscleFigure>(find.byType(GraphiteMuscleFigure))) {
      expect(figure.female, false);
      expect(figure.primary,
          containsAll(['chest', 'lats', 'upper_back', 'lower_back']));
    }
    expect(tester.takeException(), isNull);
  });
  for (final language in ['en', 'de', 'fr']) {
    testWidgets('The reveal fits narrow large-text $language', (tester) async {
      phone(tester, const Size(320, 740));
      await tester.pumpWidget(app(
          StarterPlanView(
              repository: StarterRepo(),
              subscription: TrialService(),
              profileLoader: () async =>
                  {...profile, 'name': 'Alexandra-Maria Elizabeth'},
              onComplete: (_) {}),
          scale: 1.6,
          language: language));
      await tester.pumpAndSettle();
      await artwork(tester);
      expect(find.byType(LiquidChromeButton).hitTestable(), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'personal-plan-large-$language');
    });
  }
  for (final offset in [0, 1]) {
    testWidgets(
        'Post-payment first workout action respects the actual date ($offset)',
        (tester) async {
      phone(tester);
      final today = CacheScope.todayKey();
      final date = CacheScope.todayKey(
          DateTime.parse(today).add(Duration(days: offset)));
      var starts = 0;
      final raw = session.fixture(date)..['session'] = null;
      final oldAdapter = ApiClient.shared.client.httpClientAdapter;
      ApiClient.shared.client.httpClientAdapter = SessionAdapter();
      addTearDown(() => ApiClient.shared.client.httpClientAdapter = oldAdapter);
      Widget schedule(bool active) => app(Scaffold(
              body: SingleChildScrollView(
                  child: WeeklyPlanSchedule(
                      payload: {
                'workouts': [
                  {
                    'date': date,
                    'restDay': false,
                    'name': 'Chest day',
                    'estimatedMinutes': 35,
                    'exercises': const []
                  }
                ]
              },
                      active: active,
                      fromOnboarding: true,
                      loadDay: (_) async => TrainingDay(raw),
                      startDay: (_) async {
                        starts++;
                        return TrainingDay(session.fixture(date));
                      }))));
      await tester.pumpWidget(schedule(false));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('onboarding-first-workout-action')),
          findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(schedule(true));
      await tester.pumpAndSettle();
      expect(starts, 0);
      expect(find.text(offset == 0 ? 'Start workout' : 'View workout'),
          findsOneWidget);
      if (offset == 0) {
        await tester.tap(find.text('Start workout'));
        await tester.pumpAndSettle();
        expect(starts, 1);
        expect(find.byType(WorkoutSessionView), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
