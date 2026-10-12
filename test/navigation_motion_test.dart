import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/components/content_transition.dart';
import 'package:fitai_mobile/core/navigation/onboarding_page_route.dart';
import 'package:fitai_mobile/features/planner/repositories/weekly_plan_repository.dart';
import 'package:fitai_mobile/features/planner/views/weekly_plan_view.dart';
import 'package:fitai_mobile/features/planner/views/widgets/weekly_plan_schedule.dart';

Map<String, dynamic> week(String id, String date) => {
      'id': id,
      'weekStart': date,
      'status': 'ACTIVE',
      'synthetic': false,
      'trainingDays': 0,
      'foodPlanIncluded': false,
      'payload': {
        'label': id,
        'warnings': [],
        'workouts': List.generate(
            7,
            (index) => {
                  'date': DateTime.parse(date)
                      .add(Duration(days: index))
                      .toIso8601String()
                      .split('T')
                      .first,
                  'name': 'Rest day',
                  'restDay': true,
                  'exercises': [],
                }),
        'nutrition': {
          'status': 'NEEDS_INPUT',
          'reason': 'No food plan.',
          'days': []
        },
      },
    };

class _DelayedPlans extends WeeklyPlanRepository {
  final available = Completer<Map<String, dynamic>>();
  final saved = Completer<List<Map<String, dynamic>>>();
  bool availabilityStarted = false, plansStarted = false;
  final first = week('first', '2026-10-12');
  final second = week('second', '2026-10-05');

  @override
  Future<Map<String, dynamic>> availability() {
    availabilityStarted = true;
    return available.future;
  }

  @override
  Future<List<Map<String, dynamic>>> plans() {
    plansStarted = true;
    return saved.future;
  }

  @override
  Future<Map<String, dynamic>> history({String? cursor}) async => {
        'items': [second],
        'nextCursor': null
      };

  @override
  Future<Map<String, dynamic>> savedPlan(String id) async => second;

  void complete() {
    available.complete(
        {'canGenerate': true, 'cooldownActive': false, 'lastPlanId': 'first'});
    saved.complete([first]);
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'fitai_access_token': 'test-token',
        'fitai_user_id': 'motion-test',
      }));

  testWidgets(
      'Content crossfades, blocks outgoing actions and settles after rapid changes',
      (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: selected,
        builder: (context, index, child) => ContentTransition(
          child: SizedBox(
              key: ValueKey(index), height: 180, child: Text('Content $index')),
        ),
      ),
    )));
    selected.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Content 0'), findsOneWidget);
    expect(find.text('Content 1'), findsOneWidget);
    final oldPointer = find.ancestor(
        of: find.text('Content 0'), matching: find.byType(IgnorePointer));
    expect(tester.widget<IgnorePointer>(oldPointer.first).ignoring, true);
    final fade = tester.widgetList<FadeTransition>(find.descendant(
        of: find.byType(ContentTransition),
        matching: find.byType(FadeTransition)));
    expect(fade.any((item) => item.opacity.value > 0 && item.opacity.value < 1),
        true);
    for (final index in [2, 3, 4]) {
      selected.value = index;
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();
    expect(find.text('Content 4'), findsOneWidget);
    expect(find.text('Content 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion shows new content immediately', (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: ValueListenableBuilder<int>(
        valueListenable: selected,
        builder: (context, index, child) => ContentTransition(
            child: Text('Content $index', key: ValueKey(index))),
      ),
    )));
    selected.value = 1;
    await tester.pump();
    expect(find.text('Content 0'), findsNothing);
    expect(find.text('Content 1'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNothing);
  });

  testWidgets(
      'Plan requests run together; loaded content fades in and refresh preserves its state',
      (tester) async {
    final repository = _DelayedPlans();
    await tester
        .pumpWidget(MaterialApp(home: WeeklyPlanView(repository: repository)));
    await tester.pump();
    expect(repository.availabilityStarted, true);
    expect(repository.plansStarted, true);
    expect(find.byType(LoadingPlaceholder), findsOneWidget);
    repository.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(WeeklyPlanSchedule), findsOneWidget);
    expect(find.byType(LoadingPlaceholder), findsOneWidget);
    await tester.pumpAndSettle();
    final schedule = tester.state(find.byType(WeeklyPlanSchedule));
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(WeeklyPlanSchedule)), same(schedule));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('History closes before the selected plan changes underneath it',
      (tester) async {
    final repository = _DelayedPlans()..complete();
    await tester
        .pumpWidget(MaterialApp(home: WeeklyPlanView(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan history'));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.text('Your saved weeks')))!;
    expect(route, isA<AppPageRoute>());
    await tester.scrollUntilVisible(find.text('Review week'), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Review week'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final oldSchedule = tester.widget<WeeklyPlanSchedule>(
        find.byType(WeeklyPlanSchedule, skipOffstage: false));
    expect(oldSchedule.payload['label'], 'first');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<WeeklyPlanSchedule>(find.byType(WeeklyPlanSchedule))
            .payload['label'],
        'second');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
