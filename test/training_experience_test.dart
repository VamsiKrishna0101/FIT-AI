import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/components/liquid_chrome_button.dart';
import 'package:fitai_mobile/core/components/premium_surface.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/onboarding/data/discovery_repository.dart';
import 'package:fitai_mobile/features/onboarding/views/discovery_onboarding_gate.dart';
import 'package:fitai_mobile/features/onboarding/data/starter_plan_repository.dart';
import 'package:fitai_mobile/features/onboarding/views/starter_plan_view.dart';
import 'package:fitai_mobile/features/train/components/exercise_muscle_map.dart';
import 'package:fitai_mobile/features/train/components/graphite_anatomy.dart';
import 'package:fitai_mobile/features/train/models/workout_exercise_models.dart';
import 'package:fitai_mobile/features/train/views/exercise_detail_screen.dart';
import 'package:fitai_mobile/features/today/components/today_dashboard.dart';
import 'package:fitai_mobile/features/today/components/readiness_score_ring.dart';
import 'package:fitai_mobile/features/today/views/readiness_detail_view.dart';
import 'package:fitai_mobile/models/home_models.dart';

const boundary = ValueKey('training-experience-preview');
Widget app(Widget child, {double scale = 1, String locale = 'en'}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(key: boundary, child: child))));

WorkoutExerciseModel exercise(String target,
        {List<String> secondary = const []}) =>
    WorkoutExerciseModel(
        id: target,
        name: target,
        bodyPart: target,
        target: target,
        secondaryMuscles: secondary,
        equipment: 'Dumbbell',
        difficulty: 'Beginner',
        category: 'strength',
        description: '',
        instructions: const ['Move with control.']);

Widget map(String target,
        {List<String> secondary = const [], bool female = false}) =>
    Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: PremiumSurface(
                    child: ExerciseMuscleMap(
                        exercise: exercise(target, secondary: secondary),
                        female: female)))));

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> loadAtlas(WidgetTester tester) async {
  await tester.runAsync(() => precacheImage(
      const AssetImage(graphiteAnatomyAsset),
      tester.element(find.byType(ExerciseMuscleMap))));
  await tester.pumpAndSettle();
}

class Survey extends DiscoveryRepository {
  static int serial = 0;
  String account = 'discovery-flow-${serial++}';
  bool done = false, offline = false, failStatus = false;
  final answers = <String?>[];
  @override
  Future<String?> owner() async => account;
  @override
  Future<bool> completed(String user) async {
    if (failStatus) throw StateError('Unavailable');
    return done;
  }

  @override
  Future<void> save(String user, String? answer) async {
    if (user != account || offline) throw StateError('Unavailable');
    answers.add(answer);
    done = true;
  }
}

class StarterProbe extends StarterPlanRepository {
  bool eligible = true;
  int starts = 0;
  @override
  Future<Map<String, dynamic>> current() async =>
      {'eligible': eligible, 'hasAccess': !eligible};
  @override
  Future<Map<String, dynamic>> start() async {
    starts++;
    throw StateError('Preview unavailable');
  }
}

Future<void> account(String owner) async {
  final claims = base64Url.encode(utf8.encode(jsonEncode({'userId': owner})));
  await SecureSessionStore.shared.saveTokens(
      accessToken: 'header.$claims.signature',
      refreshToken: 'fixture',
      userId: owner);
}

void main() {
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
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await account('anatomy-test');
  });
  void phone(WidgetTester tester, [Size size = const Size(393, 852)]) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  testWidgets(
      'Both body styles retain fibres, primary priority and front/back choice',
      (tester) async {
    phone(tester);
    for (final female in [false, true]) {
      await tester.pumpWidget(app(
          map('pectorals', secondary: ['triceps', 'delts'], female: female)));
      await loadAtlas(tester);
      final figure = tester
          .widget<GraphiteMuscleFigure>(find.byType(GraphiteMuscleFigure));
      expect(figure.female, female);
      expect(figure.back, isFalse);
      expect(figure.primary, {'chest'});
      expect(figure.secondary, {'shoulders', 'triceps'});
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Triceps · Shoulders'), findsOneWidget);
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<GraphiteAnatomyPainter>()
          .single;
      expect(painter.image, isNotNull);
      expect(painter.image!.width, 1024);
      expect(painter.image!.height, 1536);
      await capture(
          tester, 'exercise-anatomy-${female ? 'female' : 'male'}-front');
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<GraphiteMuscleFigure>(find.byType(GraphiteMuscleFigure))
              .back,
          isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    await tester
        .pumpWidget(app(map('lats', secondary: ['biceps'], female: true)));
    await loadAtlas(tester);
    expect(
        tester
            .widget<GraphiteMuscleFigure>(find.byType(GraphiteMuscleFigure))
            .back,
        isTrue);
    await capture(tester, 'exercise-anatomy-female-back');
    await tester
        .pumpWidget(app(map('hamstrings', secondary: ['glutes', 'calves'])));
    await loadAtlas(tester);
    await capture(tester, 'exercise-anatomy-male-back');
  });

  testWidgets('Unknown targets stay honest, and labels fit large text',
      (tester) async {
    phone(tester, const Size(320, 700));
    await tester.pumpWidget(app(map('unmapped target'), scale: 1.6));
    await tester.pumpAndSettle();
    expect(find.text('Muscle map unavailable'), findsOneWidget);
    expect(find.byType(GraphiteMuscleFigure), findsNothing);
    await tester.pumpWidget(app(
        map('quadriceps', secondary: ['glutes'], female: true),
        scale: 1.6));
    await loadAtlas(tester);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Capture every registered primary region for artwork alignment review',
      (tester) async {
    phone(tester, const Size(1540, 1240));
    const targets = [
      'chest',
      'shoulders',
      'biceps',
      'triceps',
      'forearms',
      'core',
      'quads',
      'upper_back',
      'lats',
      'lower_back',
      'glutes',
      'hamstrings',
      'calves'
    ];
    final items = [
      for (final female in [false, true])
        for (final target in targets) (female, target)
    ];
    await tester.pumpWidget(app(Scaffold(
        body: Column(children: [
      for (var row = 0; row < 4; row++)
        Row(children: [
          for (var column = 0; column < 7; column++)
            if (row * 7 + column < items.length)
              SizedBox(
                  width: 220,
                  height: 310,
                  child: Builder(builder: (context) {
                    final (female, target) = items[row * 7 + column];
                    final back = {
                      'triceps',
                      'upper_back',
                      'lats',
                      'lower_back',
                      'glutes',
                      'hamstrings',
                      'calves'
                    }.contains(target);
                    return Column(children: [
                      SizedBox(
                          height: 280,
                          width: 210,
                          child: GraphiteMuscleFigure(
                              female: female,
                              back: back,
                              primary: {target},
                              secondary: const {})),
                      Text('${female ? 'Female' : 'Male'} · $target',
                          style: const TextStyle(fontSize: 13))
                    ]);
                  }))
            else
              const SizedBox(width: 220, height: 310),
        ]),
    ]))));
    await tester.runAsync(() => precacheImage(
        const AssetImage(graphiteAnatomyAsset),
        tester.element(find.byType(Scaffold))));
    await tester.pumpAndSettle();
    await capture(tester, 'exercise-anatomy-registration');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Exercise details load the account body style before showing the figure',
      (tester) async {
    phone(tester);
    final profile = Completer<String?>();
    await tester.pumpWidget(app(ExerciseDetailView(
        exercise: exercise('lats'),
        loadDetail: false,
        profileGenderLoader: () => profile.future)));
    await tester.pump();
    expect(find.byType(GraphiteMuscleFigure), findsNothing);
    profile.complete('FEMALE');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('exercise-anatomy-map')), 250,
        scrollable: find.byType(Scrollable).last);
    await loadAtlas(tester);
    expect(
        tester
            .widget<GraphiteMuscleFigure>(find.byType(GraphiteMuscleFigure))
            .female,
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Discovery is optional, explicit, remembered and before the next screen',
      (tester) async {
    phone(tester);
    final repo = Survey();
    await tester.pumpWidget(app(DiscoveryOnboardingGate(
        repository: repo, child: const Scaffold(body: Text('Starter plan')))));
    await tester.pumpAndSettle();
    expect(find.text('Starter plan'), findsNothing);
    expect(
        tester
            .widget<LiquidChromeButton>(find.byType(LiquidChromeButton))
            .onPressed,
        isNull);
    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();
    expect(repo.answers, isEmpty);
    await capture(tester, 'onboarding-discovery');
    await tester.tap(find.byType(LiquidChromeButton));
    await tester.pumpAndSettle();
    expect(repo.answers, ['INSTAGRAM']);
    expect(find.text('Starter plan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(DiscoveryOnboardingGate(
        repository: repo, child: const Scaffold(body: Text('Starter plan')))));
    await tester.pumpAndSettle();
    expect(find.text('Where did you first hear about Setcraft?'), findsNothing);
  });

  testWidgets(
      'Offline Skip and survey outages do not block the membership flow',
      (tester) async {
    phone(tester, const Size(320, 700));
    final repo = Survey()..offline = true;
    await tester.pumpWidget(app(
        DiscoveryOnboardingGate(
            repository: repo,
            child: const Scaffold(body: Text('Membership flow'))),
        scale: 1.6));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('skip-discovery')).hitTestable(),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skip-discovery')));
    await tester.pumpAndSettle();
    expect(find.text('Membership flow'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    final unavailable = Survey()..failStatus = true;
    await tester.pumpWidget(app(DiscoveryOnboardingGate(
        repository: unavailable,
        child: const Scaffold(body: Text('Membership flow')))));
    await tester.pumpAndSettle();
    expect(find.text('Membership flow'), findsOneWidget);
  });

  testWidgets(
      'Starter gate asks before generating and Skip continues to the preview, not app access',
      (tester) async {
    phone(tester);
    final starter = StarterProbe();
    await tester.pumpWidget(app(StarterOnboardingGate(
        repository: starter,
        discoveryRepository: Survey(),
        child: const Scaffold(body: Text('Protected app')))));
    await tester.pumpAndSettle();
    expect(starter.starts, 0);
    expect(find.byType(DiscoveryOnboardingGate), findsOneWidget);
    expect(find.byType(StarterPlanView), findsNothing);
    await tester.tap(find.byKey(const ValueKey('skip-discovery')));
    await tester.pumpAndSettle();
    expect(starter.starts, 1);
    expect(find.byType(StarterPlanView), findsOneWidget);
    expect(find.text('Protected app'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    starter.eligible = false;
    await tester.pumpWidget(app(StarterOnboardingGate(
        repository: starter,
        discoveryRepository: Survey(),
        child: const Scaffold(body: Text('Protected app')))));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoveryOnboardingGate), findsNothing);
    expect(find.text('Protected app'), findsOneWidget);
  });

  testWidgets(
      'Today describes training readiness as a check-in estimate and keeps missing scores empty',
      (tester) async {
    phone(tester);
    Widget today(HomeReadiness? readiness) => Scaffold(
        body: TodayDashboard(
            data: HomeData.fromJson({
              'readiness': readiness?.toJson(),
              'sleepLog': {
                'sleepMinutes': 450,
                'rested': 4,
                'energy': 4,
                'soreness': 2
              }
            }),
            now: DateTime(2026, 10, 24),
            onRefresh: () async {},
            onProfile: () {},
            onSession: () {},
            onTrain: () {},
            onNutrition: () {},
            onBody: () {}));
    const reading = HomeReadiness(
        score: 8.25,
        label: 'Daily check-in estimate',
        aiTarget: '',
        source: 'check_in_estimate',
        date: '2026-10-24',
        sleepMinutes: 450);
    await tester.pumpWidget(app(today(reading)));
    await tester.pumpAndSettle();
    expect(find.text('Training readiness'), findsOneWidget);
    expect(find.text('Daily check-in estimate'), findsOneWidget);
    expect(find.text('Where did you first hear about Setcraft?'), findsNothing);
    final ring = tester.widget<ReadinessScoreRing>(
        find.byKey(const ValueKey('today-readiness-ring')));
    expect(ring.score, 83);
    await capture(tester, 'training-readiness-today');
    await tester.pumpWidget(app(const ReadinessDetailView(readiness: reading)));
    await tester.pumpAndSettle();
    await capture(tester, 'training-readiness-detail');
    await tester.pumpWidget(app(today(null)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ReadinessScoreRing>(
                find.byKey(const ValueKey('today-readiness-ring')))
            .score,
        isNull);
    expect(tester.takeException(), isNull);
  });
}
