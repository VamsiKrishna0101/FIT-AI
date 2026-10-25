import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/theme/fitness_theme.dart';
import 'package:fitai_mobile/features/planner/views/widgets/plan_schedule_sheet.dart';
import 'package:fitai_mobile/features/train/components/reschedule_workout_sheet.dart';
import 'package:fitai_mobile/features/train/repositories/workout_schedule_repository.dart';

class _ScheduleRepository extends WorkoutScheduleRepository {
  int applications = 0;
  bool stale = false;
  @override
  Future<Map<String, dynamic>> preview(String date,
          {String action = 'SHIFT', List<String>? availableDates}) async =>
      {
        'fingerprint': 'preview',
        'candidateDates': ['2026-12-31', '2027-01-01'],
        'availableDates': availableDates ?? ['2026-12-31'],
        'changes': action == 'SKIP'
            ? [
                {
                  'workoutId': 'a',
                  'name': 'Chest',
                  'fromDate': '2026-12-30',
                  'toDate': null,
                  'reason': 'You chose to skip this workout.'
                }
              ]
            : [
                {
                  'workoutId': 'a',
                  'name': 'Chest',
                  'fromDate': '2026-12-30',
                  'toDate': '2026-12-31'
                },
                {
                  'workoutId': 'b',
                  'name': 'Back',
                  'fromDate': '2026-12-31',
                  'toDate': null,
                  'reason': 'No available training date remains this week.'
                },
              ],
      };
  @override
  Future<Map<String, dynamic>> apply(
      String date, Map<String, dynamic> preview, String action) async {
    applications++;
    if (stale) {
      throw const FormatException(
          'Your schedule changed. Review the updated dates again.');
    }
    return {};
  }
}

void main() {
  test(
      'Calendar choices stop on Sunday across year and daylight-saving boundaries',
      () {
    expect(
        remainingWeekDates(DateTime(2026, 12, 30))
            .map((d) => '${d.year}-${d.month}-${d.day}'),
        ['2026-12-30', '2026-12-31', '2027-1-1', '2027-1-2', '2027-1-3']);
    expect(remainingWeekDates(DateTime(2026, 10, 25)).length, 1);
    expect(remainingWeekDates(DateTime(2026, 10, 26)).length, 7);
  });

  testWidgets(
      'Start choices and session count produce only the selected real dates',
      (tester) async {
    PlanScheduleSelection? selection;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      selection =
                          await showModalBottomSheet<PlanScheduleSelection>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => FitnessTheme(
                                      child: PlanScheduleSheet(
                                          initialStart: DateTime(2026, 12, 30),
                                          now: DateTime(2026, 12, 30),
                                          preferredDays: const [
                                        'WEDNESDAY',
                                        'FRIDAY',
                                        'SUNDAY'
                                      ])));
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('training-date-2026-12-30')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('session-count-2')));
    await tester.ensureVisible(find.text('Use these dates'));
    await tester.tap(find.text('Use these dates'));
    await tester.pumpAndSettle();
    expect(selection!.start, DateTime(2026, 12, 31));
    expect(selection!.dates, [DateTime(2026, 12, 31), DateTime(2027, 1, 3)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Sunday offers one remaining session and cannot continue with no date selected',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: FitnessTheme(
                child: PlanScheduleSheet(
                    initialStart: DateTime(2027, 1, 3),
                    now: DateTime(2027, 1, 3))))));
    expect(find.byKey(const ValueKey('session-count-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('session-count-2')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('training-date-2027-01-03')));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets(
      'Move preview names skipped workouts and requires explicit confirmation',
      (tester) async {
    final repository = _ScheduleRepository();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: FitnessTheme(
                child: RescheduleWorkoutSheet(
                    date: '2026-12-30', repository: repository)))));
    await tester.pumpAndSettle();
    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.textContaining('Skip this workout'), findsOneWidget);
    expect(find.text('Apply dates and confirm skips'), findsOneWidget);
    expect(repository.applications, 0);
    await tester.tap(find.text('Skip today only'));
    await tester.pumpAndSettle();
    expect(find.text('Back'), findsNothing);
    expect(repository.applications, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A stale preview cannot be submitted again until it is reviewed',
      (tester) async {
    final repository = _ScheduleRepository()..stale = true;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: FitnessTheme(
                child: RescheduleWorkoutSheet(
                    date: '2026-12-30', repository: repository)))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply dates and confirm skips'));
    await tester.tap(find.text('Apply dates and confirm skips'));
    await tester.pumpAndSettle();
    expect(repository.applications, 1);
    expect(find.text('Apply dates and confirm skips'), findsNothing);
    expect(find.text('Review schedule again'), findsOneWidget);
    await tester.ensureVisible(find.text('Review schedule again'));
    await tester.tap(find.text('Review schedule again'));
    await tester.pumpAndSettle();
    expect(find.text('Apply dates and confirm skips'), findsOneWidget);
  });

  testWidgets('Schedule preview fits small screens with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
                body: FitnessTheme(
                    child: RescheduleWorkoutSheet(
                        date: '2026-12-30',
                        repository: _ScheduleRepository()))))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply dates and confirm skips'));
    expect(tester.takeException(), isNull);
  });
}
