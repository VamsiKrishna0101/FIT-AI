import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/body_scan/models/body_assessment_models.dart';
import 'package:setcraft/features/body_scan/models/planned_physique_models.dart';
import 'package:setcraft/features/body_scan/views/widgets/anatomical_training_map.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_physique_home.dart';
import 'package:setcraft/features/body_scan/views/widgets/planned_physique_map.dart';
import 'package:setcraft/features/body_scan/views/widgets/physique_photo_report.dart';
import 'package:setcraft/features/body_scan/views/widgets/physique_week_filter.dart';

PlannedPhysiqueData plan({String gender = 'MALE'}) =>
    PlannedPhysiqueData.fromJson({
      'status': 'active',
      'planId': 'active-plan',
      'date': '2026-10-20',
      'gender': gender,
      'workouts': [
        {
          'date': '2026-10-20',
          'name': 'Upper body',
          'restDay': false,
          'exercises': [
            {
              'itemId': 'bench-1',
              'exerciseId': 'bench',
              'name': 'Bench press',
              'sets': 3,
              'targetReps': '8-10',
              'primary': ['chest'],
              'secondary': ['triceps', 'shoulders'],
              'reason': 'Matches your available bench.'
            },
          ]
        },
        {
          'date': '2026-10-22',
          'name': 'Lower body',
          'restDay': false,
          'exercises': [
            {
              'itemId': 'squat-1',
              'exerciseId': 'squat',
              'name': 'Squat',
              'sets': 4,
              'targetReps': '8-12',
              'primary': ['quads'],
              'secondary': ['glutes']
            },
          ]
        },
      ],
    });
Widget app(Widget child, {double scale = 1}) => RepaintBoundary(
    key: const ValueKey('plan-map-preview'),
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: FitnessTheme(child: Scaffold(body: SafeArea(child: child)))));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await initializeDateFormatting();
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });
  Future<void> size(WidgetTester tester, {double width = 393}) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('saved scans never replace the plan muscle map', (tester) async {
    await size(tester);
    var photos = 0;
    await tester.pumpWidget(app(BodyPhysiqueHome(
        planData: plan(),
        overview: BodyOverview.fromJson({
          'records': [
            {
              'id': 'photo',
              'recordedDate': '2026-10-20',
              'updatedAt': '2026-10-20T12:00:00Z',
              'status': 'SAVED',
              'method': 'photo_review',
              'metrics': {},
              'quality': {
                'physiqueAssessment': {'photosUsed': 1}
              },
              'photos': [],
              'observations': []
            }
          ]
        }),
        onRefresh: () async {},
        onManual: () {},
        onPhotos: () => photos++,
        onMeasurements: () {},
        onHistory: () {})));
    await tester.pumpAndSettle();
    expect(find.byType(AnatomicalTrainingMap), findsOneWidget);
    expect(find.byType(PhysiquePhotoReport), findsNothing);
    await tester.scrollUntilVisible(find.text('Photo review'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Photo review'));
    await tester.pump();
    expect(photos, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('actual planned muscles and exercise selection drive the map',
      (tester) async {
    await size(tester);
    await tester.pumpWidget(app(SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PlannedPhysiqueMap(data: plan()))));
    await tester.pumpAndSettle();
    var map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(map.colors['chest'], const Color(0xFF8FB9F0));
    expect(map.colors['quads'], const Color(0xFF8FB9F0));
    expect(map.colors['triceps'], const Color(0xFF4D627F));
    map.onSelected('chest');
    await tester.pumpAndSettle();
    expect(find.text('3 direct sets planned for this week'), findsOneWidget);
    expect(find.text('Matches your available bench.'), findsOneWidget);
    expect(find.text('3 sets · 8-10 reps · Primary'), findsOneWidget);
    await tester.tap(find.text('Bench press').last);
    await tester.pumpAndSettle();
    map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(map.colors['quads'], const Color(0xFF30343B));
    expect(map.colors['chest'], const Color(0xFF8FB9F0));
    expect(find.text('Today'), findsNothing);
    map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(map.colors['quads'], const Color(0xFF30343B));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('plan-map-preview')))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/planned-physique-preview.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
  test('week arithmetic stays on Mondays across month and year boundaries', () {
    expect(physiqueWeekStart(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
    expect(
        physiqueWeekShift(DateTime(2026, 10, 19), 1), DateTime(2026, 10, 26));
    expect(physiqueWeekShift(DateTime(2026, 3, 23), 1), DateTime(2026, 3, 30));
  });
  testWidgets(
      'Physique filters select whole weeks and custom never opens a day picker',
      (tester) async {
    await size(tester, width: 320);
    DateTime selected = DateTime(2026, 10, 19);
    await tester.pumpWidget(app(
        StatefulBuilder(
            builder: (context, setState) => PhysiqueWeekFilter(
                selected: selected,
                now: DateTime(2026, 10, 21),
                onChanged: (week) => setState(() => selected = week))),
        scale: 1.6));
    await tester.tap(find.byKey(const ValueKey('physique-filter-Last week')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 10, 12));
    await tester.tap(find.byKey(const ValueKey('physique-filter-Custom')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsNothing);
    expect(find.text('Choose a week'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('physique-week-2026-10-05')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 10, 5));
    expect(find.text('Choose a week'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('week search finds months, ISO weeks and dates inside a week',
      (tester) async {
    await size(tester);
    DateTime? selected;
    await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
            onPressed: () async => selected = await showPhysiqueWeekPicker(
                context,
                selected: DateTime(2026, 10, 19),
                now: DateTime(2026, 10, 21)),
            child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('physique-week-search'));
    await tester.enterText(search, 'October 2026');
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('physique-week-2026-10-19')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('physique-week-2025-10-20')), findsNothing);
    await tester.enterText(search, 'week43 2026');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(
        find.byKey(const ValueKey('physique-week-2026-10-19')), findsOneWidget);
    await tester.enterText(search, 'nothing matches');
    await tester.pumpAndSettle();
    expect(find.text('No matching weeks'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('No matching weeks'), findsNothing);
    // A Sunday finds its containing Monday, including at the ISO year boundary.
    await tester.enterText(search, '2027-01-03');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    await tester.enterText(search, 'week53 2026');
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('physique-week-2026-12-28')), findsOneWidget);
    await tester.enterText(search, '21/10/2026');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('physique-week-2026-10-19')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 10, 19));
    expect(tester.takeException(), isNull);
  });
  testWidgets('neutral map remains for first use and small female layouts fit',
      (tester) async {
    await size(tester, width: 320);
    await tester.pumpWidget(app(
        SingleChildScrollView(
            child: PlannedPhysiqueMap(data: plan(gender: 'FEMALE'))),
        scale: 1.6));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
            .female,
        true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
        app(const SingleChildScrollView(child: PlannedPhysiqueMap())));
    await tester.pumpAndSettle();
    final map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(map.colors.values.every((c) => c == const Color(0xFF30343B)), true);
    expect(tester.takeException(), isNull);
  });
}
