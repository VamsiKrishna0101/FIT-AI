import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/planner/views/weekly_plan_view.dart';
import 'package:setcraft/features/planner/repositories/weekly_plan_repository.dart';
import 'package:setcraft/features/planner/views/weekly_plan_card.dart';
import 'package:setcraft/features/body_scan/models/body_assessment_models.dart';
import 'package:setcraft/features/body_scan/views/body_entry_view.dart';

class _Repository extends WeeklyPlanRepository {
  bool generated = false;
  bool synthetic = false;
  bool unlockedAfterSave = false;
  int activations = 0;
  int generations = 0;
  bool currentScan = true;
  bool archived = false, withNutrition = false;
  bool wholeWeek = false;

  @override
  Future<BodyOverview> bodyOverview() async => BodyOverview.fromJson({
        'profile': {'weight': 70, 'height': 175, 'gender': 'male'},
        'records': currentScan
            ? [
                {
                  'id': 'scan',
                  'recordedDate':
                      DateTime.now().toIso8601String().substring(0, 10),
                  'status': 'SAVED',
                  'method': 'photo_review',
                  'metrics': {
                    'weightKg': {'value': 70, 'source': 'scale'},
                    'waistCm': {'value': 86, 'source': 'tape'}
                  },
                  'updatedAt': DateTime.now().toIso8601String(),
                }
              ]
            : [],
      });

  @override
  Future<Map<String, dynamic>> availability({bool refresh = false}) async => {
        'canGenerate': !generated || unlockedAfterSave,
        'cooldownActive': generated && !unlockedAfterSave,
        'lastPlanId': generated ? 'saved-plan' : null,
        'nextGenerationAt': generated
            ? DateTime.now()
                .add(const Duration(days: 7))
                .toUtc()
                .toIso8601String()
            : null,
        'pendingRun': null,
      };

  Map<String, dynamic> get plan => {
        'id': 'saved-plan',
        'weekStart': '2026-10-12',
        'version': 1,
        'status': archived ? 'ARCHIVED' : 'ACTIVE',
        'synthetic': synthetic,
        'payload': {
          'synthetic': synthetic,
          'summary':
              'This week uses familiar exercises and recovery between training days.',
          'warnings': [],
          'workouts': [
            for (var day = 0; day < (wholeWeek ? 7 : 1); day++)
              {
                'date': '2026-10-${12 + day}',
                'name': wholeWeek && (day == 1 || day > 3)
                    ? 'Rest day'
                    : 'Full body',
                'restDay': wholeWeek && (day == 1 || day > 3),
                'estimatedMinutes': 30,
                'exercises': wholeWeek && (day == 1 || day > 3)
                    ? []
                    : [
                        {
                          'exerciseId': 'press',
                          'name': 'Dumbbell floor press',
                          'sets': 2,
                          'repsMin': 10,
                          'repsMax': 12,
                          'weightKg': 12,
                          'weightBasis': 'as_logged',
                          'targetRpe': 7.5,
                          'restSeconds': 120,
                          'reason':
                              'Keep a familiar movement using your available equipment.',
                        }
                      ],
              }
          ],
          'nutrition': withNutrition
              ? {
                  'status': 'RECOMMENDED',
                  'targets': {
                    'calories': 2100,
                    'protein': 150,
                    'carbs': 240,
                    'fat': 60
                  },
                  'days': [
                    {
                      'date': '2026-10-12',
                      'totals': {'calories': 2100, 'protein': 150},
                      'meals': [
                        {
                          'mealType': 'BREAKFAST',
                          'foods': [
                            {'name': 'Oats', 'grams': 80}
                          ]
                        }
                      ],
                    }
                  ],
                }
              : {
                  'status': 'NEEDS_INPUT',
                  'reason': 'Review your food preferences.'
                },
        },
      };

  @override
  Future<List<Map<String, dynamic>>> plans() async => generated ? [plan] : [];

  @override
  Future<Map<String, dynamic>> savedPlan(String id) async {
    if (generated) return plan;
    final request = RequestOptions(path: '/api/plans/saved/$id');
    throw DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 404),
        type: DioExceptionType.badResponse);
  }

  @override
  Future<Map<String, dynamic>> generate(
      {required DateTime weekStart,
      DateTime? startDate,
      List<DateTime>? trainingDates}) async {
    generations++;
    generated = true;
    return {'id': 'run', 'status': 'COMPLETED'};
  }

  @override
  Future<Map<String, dynamic>> run(String id) async =>
      {'id': id, 'status': 'COMPLETED', 'plan': plan};

  @override
  Future<void> activate(String id) async {
    activations++;
  }
}

class _UnavailableMeasurementsRepository extends _Repository {
  @override
  Future<BodyOverview> bodyOverview() async => throw DioException(
      requestOptions: RequestOptions(path: '/api/body/overview'));
}

void main() {
  testWidgets(
      'Refreshing a reset plan removes the old selection and unlocks generation',
      (tester) async {
    final repository = _Repository()..generated = true;
    await tester.pumpWidget(MaterialApp(
        home: WeeklyPlanView(
            requestAiConsent: (_) async => true, repository: repository)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-day-2026-10-12')), findsOneWidget);
    repository.generated = false;
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-day-2026-10-12')), findsNothing);
    expect(find.text('Generate weekly plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test(
      'Entered measurements are reused; photo estimates do not skip the prompt',
      () {
    BodyOverview overview(String date, {String source = 'tape'}) =>
        BodyOverview.fromJson({
          'profile': {'height': 175},
          'records': [
            {
              'id': 'scan',
              'recordedDate': date,
              'status': 'SAVED',
              'method': 'entered',
              'metrics': {
                'weightKg': {
                  'value': 70,
                  'source': source == 'photo_estimate' ? source : 'scale'
                },
                'waistCm': {'value': 86, 'source': source}
              },
              'updatedAt': '2026-10-12T09:00:00Z',
            }
          ]
        });
    final today = DateTime(2026, 10, 12, 23);
    expect(
        WeeklyPlanRepository.hasEnteredMeasurements(
            overview('2026-10-12'), today),
        isTrue);
    expect(
        WeeklyPlanRepository.hasEnteredMeasurements(
            overview('2026-10-11'), today),
        isTrue);
    expect(
        WeeklyPlanRepository.hasEnteredMeasurements(
            overview('2026-10-13'), today),
        isFalse);
    expect(
        WeeklyPlanRepository.hasEnteredMeasurements(
            overview('2026-10-12', source: 'photo_estimate'), today),
        isFalse);
  });

  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'fitai_access_token': 'opaque',
        'fitai_user_id': 'weekly-plan-test',
      }));

  testWidgets('Missing measurements are required before generation',
      (tester) async {
    final repository = _Repository()..currentScan = false;
    await tester.pumpWidget(MaterialApp(
        home: WeeklyPlanView(
            requestAiConsent: (_) async => true, repository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Generate weekly plan'));
    await tester.tap(find.text('Generate weekly plan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use these dates'));
    await tester.tap(find.text('Use these dates'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BodyEntryView), findsOneWidget);
    expect(find.text('Complete your baseline'), findsOneWidget);
    expect(find.text('Continue without measurements'), findsNothing);
    expect(repository.generations, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(repository.generations, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Measurement service failure blocks plan generation until verified',
      (tester) async {
    final repository = _UnavailableMeasurementsRepository();
    await tester.pumpWidget(MaterialApp(
        home: WeeklyPlanView(
            requestAiConsent: (_) async => true, repository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Generate weekly plan'));
    await tester.tap(find.text('Generate weekly plan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use these dates'));
    await tester.tap(find.text('Use these dates'));
    await tester.pumpAndSettle();
    expect(repository.generations, 0);
    expect(find.text('Add measurements (optional)'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Measurement action opens entered measurements before generation',
      (tester) async {
    final repository = _Repository()..currentScan = false;
    await tester.pumpWidget(MaterialApp(
        home: WeeklyPlanView(
            requestAiConsent: (_) async => true, repository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Generate weekly plan'));
    await tester.tap(find.text('Generate weekly plan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use these dates'));
    await tester.tap(find.text('Use these dates'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(BodyEntryView), findsOneWidget);
    expect(repository.generations, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(repository.generations, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Real generation has no demo toggle and opens a usable saved plan',
      (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(MaterialApp(
        home: WeeklyPlanView(
            requestAiConsent: (_) async => true, repository: repository)));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Use test history'), findsNothing);
    await tester.ensureVisible(find.text('Generate weekly plan'));
    await tester.tap(find.text('Generate weekly plan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use these dates'));
    await tester.tap(find.text('Use these dates'));
    // Start the route ticker before advancing time; the underlying generate
    // button remains busy while the progress page is open.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Your week is ready'), findsOneWidget);
    await tester.ensureVisible(find.text('View weekly plan'));
    await tester.tap(find.text('View weekly plan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-day-2026-10-12')), findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const ValueKey('plan-day-2026-10-12')));
    await tester.tap(find.byKey(const ValueKey('plan-day-2026-10-12')));
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell floor press'), findsOneWidget);
    expect(find.text('12 kg'), findsOneWidget);
    expect(find.text('Use this weekly plan'), findsNothing);
    expect(repository.activations, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Weekly plan remains readable on a small screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _Repository()..generated = true;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
      child: WeeklyPlanView(
          requestAiConsent: (_) async => true, repository: repository),
    )));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('plan-day-2026-10-12')));
    await tester.tap(find.byKey(const ValueKey('plan-day-2026-10-12')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Nutrition'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Nutrition'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Saved plan shows its content without a duplicate open-plan footer',
      (tester) async {
    final repository = _Repository()..generated = true;

    await tester.pumpWidget(MaterialApp(
        home: WeeklyPlanView(
            requestAiConsent: (_) async => true, repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Generate weekly plan'), findsNothing);
    expect(find.text('View weekly plan'), findsNothing);
    expect(find.textContaining('Next plan available'), findsNothing);
    expect(
        find.text(
            'This week uses familiar exercises and recovery between training days.'),
        findsNothing);
    await tester.ensureVisible(find.text('Why this plan'));
    await tester.tap(find.text('Why this plan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Next plan available'), findsOneWidget);
    expect(
        find.text(
            'This week uses familiar exercises and recovery between training days.'),
        findsOneWidget);
    expect(
        find.text('Keep a familiar movement using your available equipment.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('plan-day-2026-10-12')), findsOneWidget);

    expect(repository.generations, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('The training planner card opens the saved weekly plan',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _Repository()..generated = true;

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
      child: WeeklyPlanCard(repository: repository),
    ))));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('View weekly plan'), 140);
    await tester.ensureVisible(find.text('View weekly plan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Next plan available'), findsOneWidget);
    await tester.tap(find.text('View weekly plan'));
    await tester.pumpAndSettle();

    expect(find.byType(WeeklyPlanView), findsOneWidget);
    expect(repository.generations, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Generation returns to the card when the server unlocks it',
      (tester) async {
    final repository = _Repository()
      ..generated = true
      ..unlockedAfterSave = true;

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: WeeklyPlanCard(repository: repository),
    )));
    await tester.pumpAndSettle();

    expect(find.text('View weekly plan'), findsOneWidget);
    expect(find.textContaining('Next plan available'), findsNothing);
    expect(repository.generations, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Planner card fits a small phone with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
      child: Scaffold(
          body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: WeeklyPlanCard(repository: _Repository()..generated = true),
      )),
    )));
    await tester.pumpAndSettle();

    expect(find.text('View weekly plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final large in [false, true]) {
    testWidgets(
        'Weekly plan training and nutrition fit ${large ? 'large German text' : 'a phone'}',
        (tester) async {
      tester.view.physicalSize =
          large ? const Size(320, 720) : const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final font in {
        'Inter': 'assets/fonts/Inter.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        'packages/cupertino_icons/CupertinoIcons':
            'packages/cupertino_icons/assets/CupertinoIcons.ttf',
      }.entries) {
        await (FontLoader(font.key)..addFont(rootBundle.load(font.value)))
            .load();
      }
      final repository = _Repository()
        ..generated = true
        ..archived = true
        ..withNutrition = true
        ..wholeWeek = true;
      const captureKey = ValueKey('weekly-plan-screen');
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        locale: Locale(large ? 'de' : 'en'),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(large ? 1.8 : 1),
                disableAnimations: true),
            child: child!),
        home: RepaintBoundary(
            key: captureKey,
            child: WeeklyPlanView(
                requestAiConsent: (_) async => true, repository: repository)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dumbbell floor press'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center_outlined), findsNothing);
      expect(find.byIcon(Icons.restaurant_outlined), findsNothing);
      expect(tester.takeException(), isNull);
      Future<void> capture(String section) => tester.runAsync(() async {
            final boundary = tester
                .renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                'build/previews/weekly-plan-$section-${large ? 'large-de' : 'phone'}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
      await capture('training');
      final nutrition = find.text(large ? 'Ernährung' : 'Nutrition');
      await tester.ensureVisible(nutrition);
      await tester.pumpAndSettle();
      await tester.tap(nutrition);
      await tester.pumpAndSettle();
      expect(find.text('2100'), findsOneWidget);
      expect(find.text('150 g'), findsOneWidget);
      expect(find.text('240 g'), findsOneWidget);
      expect(find.text('60 g'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('nutrition');
      expect(repository.activations, 0);
      expect(repository.generations, 0);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
