import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/cache/cache_scope.dart';
import 'package:fitai_mobile/features/body_scan/models/training_map_models.dart';
import 'package:fitai_mobile/features/body_scan/views/body_training_view.dart';
import 'package:fitai_mobile/features/train/models/training_session.dart';
import 'package:fitai_mobile/features/train/repositories/training_repository.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/anatomical_training_map.dart';

void main() {
  testWidgets(
      'Empty day is grey even when an older response includes strength ranks',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final json =
        jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
            as Map<String, dynamic>;
    json['summary'] = {'loggedSets': 0, 'trainedMuscles': 0, 'sessions': 0};
    for (final region in json['regions'] as List) {
      region['completedSets'] = 0;
      region['strength'] = {
        'tier': 5,
        'title': 'Elite',
        'provisional': true,
        'exercises': []
      };
    }
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TrainingMapDashboard(
      data: TrainingMapData.fromJson(json),
      daily: true,
      onRefresh: () async {},
      onCheckIn: (_, __) async {},
      onTrain: () {},
      onPreferences: () {},
      onProfile: () {},
    ))));
    await tester.pumpAndSettle();
    final map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(map.colors.values.every((color) => color == const Color(0xFF606060)),
        isTrue);
    expect(find.byKey(const ValueKey('body-period-empty')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('body-strength-provisional')), findsNothing);
    map.onSelected('chest');
    await tester.pumpAndSettle();
    expect(find.text('No direct sets in this period'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Day/week transitions clear previous totals and filtered failures never restore old results',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final today = DateUtils.dateOnly(DateTime.now());
    final dayResult = Completer<TrainingMapData>();
    var fail = false;
    Future<TrainingMapData> load(DateTime date, bool daily) async {
      if (fail) throw StateError('Offline');
      if (daily) return dayResult.future;
      return TrainingMapData.fromJson({
        'date': CacheScope.todayKey(date),
        'weekStart': CacheScope.todayKey(date),
        'regions': [],
        'summary': {'loggedSets': 18, 'trainedMuscles': 2, 'sessions': 2}
      });
    }

    await tester.pumpWidget(
        MaterialApp(home: BodyTrainingView(onTrain: () {}, loadMap: load)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        tester
            .widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard))
            .data,
        isNull);
    dayResult.complete(TrainingMapData.fromJson({
      'date': CacheScope.todayKey(today),
      'weekStart': CacheScope.todayKey(today),
      'regions': [],
      'summary': {'loggedSets': 0, 'trainedMuscles': 0, 'sessions': 0}
    }));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard))
            .data!
            .summary['loggedSets'],
        0);
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard))
            .data!
            .summary['loggedSets'],
        18);
    fail = true;
    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();
    final dashboard =
        tester.widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard));
    expect(dashboard.failed, isTrue);
    expect(dashboard.data, isNull);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard))
            .data!
            .date,
        CacheScope.todayKey(DateTime(today.year, today.month, today.day - 1)));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Training filters load the chosen date and ignore late responses',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final calls = <(DateTime, bool)>[];
    final delayed = Completer<TrainingMapData>();
    TrainingMapData result(DateTime date, int sets) =>
        TrainingMapData.fromJson({
          'date': CacheScope.todayKey(date),
          'weekStart': CacheScope.todayKey(date),
          'regions': [],
          'summary': {'loggedSets': sets, 'trainedMuscles': 0, 'sessions': 0},
        });
    Future<TrainingMapData> load(DateTime date, bool daily) async {
      calls.add((date, daily));
      if (DateUtils.isSameDay(date, yesterday) && !daily) return delayed.future;
      return result(date, daily ? 21 : 42);
    }

    await tester.pumpWidget(
        MaterialApp(home: BodyTrainingView(onTrain: () {}, loadMap: load)));
    await tester.pumpAndSettle();
    expect(calls.last, (today, false));
    await tester.tap(find.text('Yesterday'));
    await tester.pump();
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(calls.last, (yesterday, true));
    delayed.complete(result(yesterday, 999));
    await tester.pumpAndSettle();
    final dashboard =
        tester.widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard));
    expect(dashboard.data!.summary['loggedSets'], 21);
    expect(dashboard.daily, isTrue);
    expect(dashboard.data!.date, CacheScope.todayKey(yesterday));

    await tester.tap(find.text('Choose date'));
    await tester.pumpAndSettle();
    final picker =
        tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker));
    expect(picker.lastDate, today);
    final custom = DateTime(today.year, today.month, today.day - 5);
    picker.onDateChanged(custom);
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(calls.last, (custom, true));
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(calls.last, (today, true));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Historical muscle details cannot submit a check-in for today',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final json =
        jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
            as Map<String, dynamic>;
    json['date'] = '2020-01-01';
    final data = TrainingMapData.fromJson(json);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TrainingMapDashboard(
      data: data,
      daily: true,
      onRefresh: () async {},
      onCheckIn: (_, __) async => fail('Historical check-in submitted'),
      onTrain: () {},
      onPreferences: () {},
      onProfile: () {},
    ))));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(AnatomicalTrainingMap));
    final point = musclePaths(back: false)['chest']!.first.getBounds().center;
    await tester.tapAt(Offset(rect.left + rect.width * point.dx / 220,
        rect.top + rect.height * point.dy / 440));
    await tester.pumpAndSettle();
    expect(find.text('Direct sets'), findsOneWidget);
    expect(find.text('How does it feel today?'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('6 of 10 direct sets · daily plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Saving sets refreshes the active Body map; reactivation refreshes the inactive map',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    int loads = 0;
    int savedSets = 0;
    final date = CacheScope.todayKey();
    Future<TrainingMapData> load(DateTime selectedDate, bool daily) async {
      loads++;
      return TrainingMapData.fromJson({
        'date': date,
        'weekStart': date,
        'regions': [],
        'summary': {'loggedSets': savedSets},
      });
    }

    Widget app(bool active) => MaterialApp(
        home:
            BodyTrainingView(isActive: active, onTrain: () {}, loadMap: load));
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(loads, 1);
    savedSets = 2;
    TrainingRepository.shared.changes
        .add(TrainingDay({'date': date, 'items': []}));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(
        tester
            .widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard))
            .data!
            .summary['loggedSets'],
        2);
    await tester.pumpWidget(app(false));
    savedSets = 3;
    TrainingRepository.shared.changes
        .add(TrainingDay({'date': date, 'items': []}));
    await tester.pumpAndSettle();
    expect(loads, 2);
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(loads, 3);
    expect(
        tester
            .widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard))
            .data!
            .summary['loggedSets'],
        3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
