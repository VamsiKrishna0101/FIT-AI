import 'package:setcraft/features/progress/repositories/progress_repository.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_training_scale.dart';
import 'package:setcraft/core/components/profile_avatar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setcraft/core/components/liquid_silver_bottom_bar.dart';
import 'package:setcraft/features/body_scan/models/body_map_models.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_muscle_map_card.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_progress_style.dart';
import 'package:setcraft/features/body_scan/views/widgets/anatomical_training_map.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/features/body_scan/models/body_assessment_models.dart';
import 'package:setcraft/features/body_scan/models/body_measurement_baseline.dart';
import 'package:setcraft/features/body_scan/models/body_progress_summary.dart';
import 'package:setcraft/features/body_scan/repositories/body_assessment_repository.dart';
import 'package:setcraft/features/body_scan/views/body_view.dart';
import 'package:setcraft/features/body_scan/views/body_entry_view.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_measurement_dashboard.dart';
import 'package:setcraft/features/progress/components/progress_chart.dart';

Map<String, dynamic> entry(String id, String date, Map<String, dynamic> metrics,
        {String status = 'SAVED', String time = '10'}) =>
    {
      'id': id,
      'recordedDate': date,
      'status': status,
      'method': 'entered',
      'updatedAt': '${date}T$time:00:00Z',
      'createdAt': '${date}T$time:00:00Z',
      'metrics': metrics,
    };
BodyOverview overview({bool empty = false}) => BodyOverview.fromJson({
      'profile': {'height': 175, 'weight': 80},
      'records': empty
          ? []
          : [
              entry('latest', '2026-10-20', {
                'weightKg': {'value': 78.4, 'source': 'scale'},
                'waistCm': {'value': 86, 'source': 'tape'},
              }),
              entry('baseline', '2026-10-01', {
                'weightKg': {'value': 80, 'source': 'scale'},
                'waistCm': {'value': 88, 'source': 'tape'},
              }),
            ],
    });

BodyMapData mapData(DateTime date, {bool noPlan = false}) {
  final week = bodyMapWeek(date);
  String day(int offset) =>
      week.add(Duration(days: offset)).toIso8601String().substring(0, 10);
  return BodyMapData.fromJson({
    'date': day(3),
    'weekStart': day(0),
    'weekEnd': day(6),
    'gender': 'MALE',
    'planId': noPlan ? null : 'weekly-plan',
    'summary': {
      'plannedSets': noPlan ? 0 : 15,
      'loggedSets': noPlan ? 0 : 18,
      'trainedMuscles': 3,
      'sessions': 1
    },
    'regions': [
      for (final row in [
        ['chest', 8, 4, 0, 'in_progress'],
        ['quads', 4, 8, 0, 'completed'],
        ['core', 0, 6, 0, 'logged'],
        ['shoulders', 3, 0, 0, 'planned'],
        ['triceps', 0, 0, 4, 'logged'],
      ])
        {
          'id': row[0],
          'plannedSets': noPlan ? 0 : row[1],
          'completedSets': noPlan ? 0 : row[2],
          'assistingSets': noPlan ? 0 : row[3],
          'status': noPlan ? 'none' : row[4],
          'lastTrained': row[0] == 'chest' ? day(2) : null,
          'loggedExercises': row[0] != 'chest' || noPlan
              ? []
              : [
                  {
                    'exerciseId': 'bench',
                    'name': 'Bench press',
                    'directSets': 4,
                    'assistingSets': 0,
                    'lastDate': day(2),
                    'sets': [
                      {'date': day(2), 'reps': 10, 'weight': 20}
                    ],
                  }
                ],
        },
    ],
    'workouts': noPlan
        ? []
        : [
            {
              'date': day(2),
              'name': 'Upper',
              'restDay': false,
              'status': 'IN_PROGRESS',
              'exercises': [
                {
                  'itemId': 'bench-item',
                  'exerciseId': 'bench',
                  'name': 'Bench press',
                  'sets': 8,
                  'targetReps': '10',
                  'primary': ['chest'],
                  'secondary': ['triceps'],
                }
              ],
            }
          ],
  });
}

class Repository extends BodyAssessmentRepository {
  final bool empty;
  bool failMap = false;
  final weeks = <DateTime>[];
  final selections = <BodyDateSelection?>[];
  Repository({this.empty = false});
  @override
  Future<BodyMapData> bodyMap(
      {DateTime? date, BodyDateSelection? selection}) async {
    weeks.add(date ?? DateTime.now());
    selections.add(selection);
    if (failMap) throw StateError('Map unavailable');
    return mapData(date ?? DateTime.now(), noPlan: empty);
  }

  @override
  Future<BodyOverview> load() async => overview(empty: empty);
}

Widget app(Widget child, {double scale = 1}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Inter'),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: child,
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'test', 'fitai_user_id': 'body-test'});
    SharedPreferences.setMockInitialValues({});
  });
  test('Baseline requires measured weight, tape waist and profile height', () {
    expect(BodyMeasurementBaseline(overview()).isComplete, isTrue);
    expect(BodyMeasurementBaseline(overview(empty: true)).missing,
        ['weightKg', 'waistCm']);
    final estimates = BodyOverview.fromJson({
      'profile': {'height': 175},
      'records': [
        entry('photo', '2026-10-01', {
          'weightKg': {'value': 80, 'source': 'profile'},
          'waistCm': {'value': 88, 'source': 'photo_estimate'},
        }),
      ]
    });
    expect(BodyMeasurementBaseline(estimates).isComplete, isFalse);
  });
  test(
      'Trend excludes estimates, future and draft data and keeps latest daily reading',
      () {
    final data = BodyOverview.fromJson({
      'records': [
        entry('future', '2099-01-01', {
          'weightKg': {'value': 100, 'source': 'scale'}
        }),
        entry(
            'draft',
            '2026-10-20',
            {
              'weightKg': {'value': 90, 'source': 'scale'}
            },
            status: 'REVIEW'),
        entry('estimate', '2026-10-20', {
          'weightKg': {'value': 60, 'source': 'photo_estimate'}
        }),
        entry('old', '2026-10-10', {
          'weightKg': {'value': 80, 'source': 'scale'}
        }),
        entry(
            'new',
            '2026-10-10',
            {
              'weightKg': {'value': 79, 'source': 'scale'}
            },
            time: '18'),
        entry('first', '2026-10-01', {
          'weightKg': {'value': 81, 'source': 'scale'}
        }),
      ]
    });
    expect(
        BodyProgressSummary(data)
            .measuredTrend('weightKg')
            .map((r) => r.metric.value),
        [81, 79]);
  });
  testWidgets(
      'Body shows one map and compact measurements with meaningful progress colors',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(app(BodyView(onTrain: () {}, repository: Repository())));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileAvatar), findsNothing);
    expect(find.byType(ProfileAvatar), findsNothing);
    expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('body-calendar-button')))
            .dy,
        closeTo(
            tester
                    .getTopLeft(find.byKey(const ValueKey('body-map-trained')))
                    .dy -
                3,
            4));
    expect(find.byType(AnatomicalTrainingMap), findsOneWidget);
    final map = tester.widget<AnatomicalTrainingMap>(
        find.byKey(const ValueKey('body-front-map')));
    expect(map.colors['chest'], bodyTrainingLow);
    expect(map.colors['quads'], bodyTrainingMedium);
    expect(map.colors['shoulders'], BodyMapPalette.neutral);
    expect(map.colors['triceps'], bodyTrainingLow);
    expect(map.satin, isTrue);
    expect(tester.getSize(find.byKey(const ValueKey('body-front-map'))).width,
        greaterThan(210));
    expect(find.byType(BodyProgressCard), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('body-show-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('body-front-map')), findsNothing);
    expect(
        tester
            .widget<AnatomicalTrainingMap>(
                find.byKey(const ValueKey('body-back-map')))
            .back,
        isTrue);
    await tester.tap(find.byKey(const ValueKey('body-show-front')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('body-front-map')), findsOneWidget);
    expect(find.byType(ProgressChart), findsNothing);
    expect(find.text('Photo review'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('body-map-trained')));
    await tester.pumpAndSettle();
    final logged = tester.widget<AnatomicalTrainingMap>(
        find.byKey(const ValueKey('body-front-map')));
    expect(logged.colors['shoulders'], BodyMapPalette.neutral);
    expect(logged.colors['triceps'], bodyTrainingLow);
    expect(logged.colors['chest'], bodyTrainingLow);
    logged.onSelected('chest');
    await tester.pumpAndSettle();
    expect(find.text('Direct sets'), findsNothing);
    expect(find.text('Assisting sets'), findsNothing);
    expect(find.text('Last trained'), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('Exercises performed'), findsNothing);
    expect(find.text('Bench press'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('body-measurement-waistCm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-measurement-waistCm')));
    await tester.pumpAndSettle();
    expect(tester.widget<ProgressChart>(find.byType(ProgressChart)).unit, 'cm');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Week selection reloads one unified map and errors offer retry',
      (tester) async {
    final repo = Repository();
    await tester.pumpWidget(app(BodyView(onTrain: () {}, repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-map-plan')));
    await tester.pumpAndSettle();
    final card =
        tester.widget<BodyMuscleMapCard>(find.byType(BodyMuscleMapCard));
    card.onWeekChanged(
        bodyMapWeek(DateTime.now()).subtract(const Duration(days: 7)));
    await tester.pumpAndSettle();
    expect(repo.weeks.last,
        bodyMapWeek(DateTime.now()).subtract(const Duration(days: 7)));
    repo.failMap = true;
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(find.text('Retry training data'), findsOneWidget);
    repo.failMap = false;
    await tester.tap(find.text('Retry training data'));
    await tester.pumpAndSettle();
    expect(find.text('Retry training data'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Incomplete baseline opens a short required form and blocks incomplete save',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        app(BodyView(onTrain: () {}, repository: Repository(empty: true))));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('body-update-measurements')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-update-measurements')));
    await tester.pumpAndSettle();
    expect(find.byType(BodyEntryView), findsOneWidget);
    expect(find.text('Complete your baseline'), findsOneWidget);
    expect(find.byKey(const ValueKey('body-input-weightKg')), findsOneWidget);
    expect(find.byKey(const ValueKey('body-input-waistCm')), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('More measurements'), findsNothing);
    expect(find.text('Suggest my training focus'), findsNothing);
    await tester.tap(find.text('Save measurements'));
    await tester.pumpAndSettle();
    expect(find.byType(BodyEntryView), findsOneWidget);
    expect(find.text('Required for your plan'), findsNWidgets(2));
  });
  testWidgets(
      'Saving a partial update never requests coaching or adds unmeasured profile weight',
      (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(app(BodyEntryView(
        profileWeight: 80,
        onSubmit: (payload) async {
          saved = payload;
        })));
    await tester.enterText(
        find.byKey(const ValueKey('body-input-waistCm')), '86.5');
    await tester.tap(find.text('Save measurements'));
    await tester.pumpAndSettle();
    expect(saved?['requestCoaching'], isFalse);
    expect((saved?['metrics'] as Map).keys, ['waistCm']);
  });
  testWidgets('Body remains readable at large text on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        app(BodyView(onTrain: () {}, repository: Repository()), scale: 2));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const ValueKey('body-scroll')), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test('Training ranges stay fixed and have no overlapping boundaries', () {
    final bands = bodyTrainingBands();
    expect(bodyTrainingColor(0, bands, BodyMapPalette.neutral),
        BodyMapPalette.neutral);
    for (final count in [1, 7]) {
      expect(bodyTrainingColor(count, bands, BodyMapPalette.neutral),
          bodyTrainingLow);
    }
    for (final count in [8, 14]) {
      expect(bodyTrainingColor(count, bands, BodyMapPalette.neutral),
          bodyTrainingMedium);
    }
    for (final count in [15, 250]) {
      expect(bodyTrainingColor(count, bands, BodyMapPalette.neutral),
          bodyTrainingHigh);
    }
  });

  testWidgets('Measurements opens by default and collapses as one card',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(app(BodyView(onTrain: () {}, repository: Repository())));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('body-measurement-weightKg')),
        findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const ValueKey('body-measurements-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-measurements-toggle')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('body-measurement-weightKg')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('body-measurements-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('body-measurement-weightKg')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Week mode switches reuse data and workout updates refresh it',
      (tester) async {
    final repo = Repository();
    await tester.pumpWidget(app(BodyView(onTrain: () {}, repository: repo)));
    await tester.pumpAndSettle();
    final reads = repo.weeks.length;
    await tester.tap(find.byKey(const ValueKey('body-map-plan')));
    await tester.pumpAndSettle();
    expect(repo.weeks.length, reads);
    await tester.tap(find.byKey(const ValueKey('body-map-trained')));
    await tester.pumpAndSettle();
    expect(repo.weeks.length, reads);
    ProgressRepository.shared.updates.add('invalidated');
    await tester.pumpAndSettle();
    expect(repo.weeks.length, reads + 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Render Body dashboard preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: app(Scaffold(
            extendBody: true,
            body: BodyView(onTrain: () {}, repository: Repository()),
            bottomNavigationBar: LiquidSilverBottomBar(
                selectedIndex: 2,
                onTabSelected: (_) {},
                labels: const ['Today', 'Train', 'Body', 'Progress'])))));
    await tester.pumpAndSettle();
    expect(find.byType(BodyMeasurementDashboard), findsOneWidget);
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    Future<void> capture(String name) => tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/previews').create(recursive: true);
          await File('build/previews/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
    await capture('body-map-refined');
    await tester.tap(find.byKey(const ValueKey('body-calendar-button')));
    await tester.pumpAndSettle();
    await capture('body-calendar-refined');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    tester
        .widget<AnatomicalTrainingMap>(
            find.byKey(const ValueKey('body-front-map')))
        .onSelected('chest');
    await tester.pumpAndSettle();
    await capture('body-muscle-details-refined');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('body-update-measurements')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-update-measurements')));
    await tester.pumpAndSettle();
    await capture('body-all-measurements-refined');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Calendar applies exact nonconsecutive dates and all time',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = Repository();
    await tester.pumpWidget(app(BodyView(onTrain: () {}, repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-calendar-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Multiple days'));
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final dates = [
      DateTime(now.year, now.month - 1, 10),
      DateTime(now.year, now.month - 1, 12)
    ];
    for (final date in dates) {
      await tester.tap(find.byKey(ValueKey(
          'body-calendar-${date.toIso8601String().substring(0, 10)}')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(repo.selections.last!.mode, BodyDateMode.days);
    expect(repo.selections.last!.dates, dates);
    expect(repo.selections.last!.query['dates'],
        dates.map((d) => d.toIso8601String().substring(0, 10)).join(','));
    await tester.tap(find.byKey(const ValueKey('body-calendar-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(repo.selections.last!.query, {'all': 'true'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Muscle exercise tap returns the exercise ID directly',
      (tester) async {
    String? opened;
    await tester.pumpWidget(app(Scaffold(
        body: SingleChildScrollView(
            child: BodyMuscleMapCard(
                data: mapData(DateTime.now()),
                female: false,
                week: bodyMapWeek(DateTime.now()),
                onWeekChanged: (_) {},
                onExercise: (id) => opened = id,
                onPreparePlan: () {},
                onRetry: () {},
                onTrain: () {})))));
    await tester.pumpAndSettle();
    tester
        .widget<AnatomicalTrainingMap>(
            find.byKey(const ValueKey('body-front-map')))
        .onSelected('chest');
    await tester.pumpAndSettle();
    expect(find.text('Exercises performed'), findsNothing);
    expect(find.text('Completed'), findsNothing);
    await tester.tap(find.text('Bench press'));
    await tester.pumpAndSettle();
    expect(opened, 'bench');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Every measurement is editable without expanding a section',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const BodyEntryView()));
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsNothing);
    for (final key in [
      'weightKg',
      'waistCm',
      ...bodyMetricSpecs.keys.where((k) => !['weightKg', 'waistCm'].contains(k))
    ]) {
      await tester.scrollUntilVisible(
          find.byKey(ValueKey('body-input-$key')), 220,
          scrollable: find
              .descendant(
                  of: find.byKey(const ValueKey('body-entry-scroll')),
                  matching: find.byType(Scrollable))
              .first);
      expect(find.byKey(ValueKey('body-input-$key')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
