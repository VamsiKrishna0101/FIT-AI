import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/planner/views/weekly_plan_view.dart';
import 'package:fitai_mobile/features/planner/repositories/weekly_plan_repository.dart';
import 'package:fitai_mobile/features/planner/views/weekly_plan_card.dart';

class _Repository extends WeeklyPlanRepository {
  bool generated = false;
  bool synthetic = false;
  bool unlockedAfterSave = false;
  int activations = 0;
  int generations = 0;

  @override
  Future<Map<String, dynamic>> availability() async => {
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
        'status': 'DRAFT',
        'synthetic': synthetic,
        'payload': {
          'synthetic': synthetic,
          'warnings': [],
          'workouts': [
            {
              'date': '2026-10-12',
              'name': 'Full body',
              'restDay': false,
              'estimatedMinutes': 30,
              'exercises': [
                {
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
          'nutrition': {
            'status': 'NEEDS_INPUT',
            'reason': 'Review your food preferences.'
          },
        },
      };

  @override
  Future<List<Map<String, dynamic>>> plans() async => generated ? [plan] : [];

  @override
  Future<Map<String, dynamic>> generate({required DateTime weekStart}) async {
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

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'fitai_access_token': 'opaque',
        'fitai_user_id': 'weekly-plan-test',
      }));

  testWidgets(
      'Real generation has no demo toggle and opens a usable saved plan',
      (tester) async {
    final repository = _Repository();
    await tester
        .pumpWidget(MaterialApp(home: WeeklyPlanView(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Use test history'), findsNothing);
    await tester.ensureVisible(find.text('Generate weekly plan'));
    await tester.tap(find.text('Generate weekly plan'));
    await tester.pumpAndSettle();
    expect(find.text('Your week is ready'), findsOneWidget);
    await tester.ensureVisible(find.text('View weekly plan'));
    await tester.tap(find.text('View weekly plan'));
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell floor press'), findsOneWidget);
    expect(find.text('2 × 10–12 · 12 kg · as logged'), findsOneWidget);
    expect(find.text('Use this weekly plan'), findsOneWidget);
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
      child: WeeklyPlanView(repository: repository),
    )));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Food'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Saved plan replaces generation with view and next availability',
      (tester) async {
    final repository = _Repository()..generated = true;

    await tester
        .pumpWidget(MaterialApp(home: WeeklyPlanView(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Generate weekly plan'), findsNothing);
    expect(find.text('View weekly plan'), findsOneWidget);
    expect(find.textContaining('Next plan available'), findsOneWidget);

    await tester.ensureVisible(find.text('View weekly plan'));
    await tester.tap(find.text('View weekly plan'));
    await tester.pumpAndSettle();

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

    expect(find.text('Generate weekly plan'), findsOneWidget);
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
}
