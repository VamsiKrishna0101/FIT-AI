import 'dart:io';
import 'dart:ui' as ui;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/features/body_scan/models/body_assessment_models.dart';
import 'package:fitai_mobile/features/body_scan/models/body_progress_summary.dart';
import 'package:fitai_mobile/features/body_scan/models/training_map_models.dart';
import 'package:fitai_mobile/features/body_scan/repositories/body_assessment_repository.dart';
import 'package:fitai_mobile/features/body_scan/views/body_view.dart';
import 'package:fitai_mobile/features/body_scan/views/body_measurements_view.dart';
import 'package:fitai_mobile/features/body_scan/views/body_history_view.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/anatomical_training_map.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/body_controls.dart';
import 'package:fitai_mobile/features/planner/repositories/weekly_plan_repository.dart';
import 'package:fitai_mobile/core/components/animated_tab_stack.dart';
import 'package:fitai_mobile/features/progress/views/progress_overview_view.dart';
import 'package:fitai_mobile/features/progress/models/progress_models.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/body_physique_home.dart';

Map<String, dynamic> _entry(String id, String date, double weight,
        {String source = 'scale', String hour = '10', bool estimate = false}) =>
    {
      'id': id,
      'recordedDate': date,
      'updatedAt': '${date}T$hour:00:00Z',
      'createdAt': '${date}T$hour:00:00Z',
      'status': 'SAVED',
      'method': estimate ? 'photo_review' : 'entered',
      'photos': [],
      'observations': [],
      'metrics': {
        'weightKg': {'value': weight, 'source': source},
        'chestCm': {'value': 102, 'source': 'tape'},
        'bodyFatPct': {'value': 20.2, 'source': 'calipers'},
        'waistCm': estimate
            ? {'value': 87, 'low': 82, 'high': 92, 'source': 'photo_estimate'}
            : {'value': 83.4, 'source': 'tape'},
        'rightArmCm': {'value': 35.1, 'source': 'tape'},
      },
      'quality': {
        'photoRetention': 'not_saved',
        'physiqueAssessment': {
          'photosUsed': 4,
          'regions': [
            for (final region in bodyRegionNames.keys)
              {
                'region': region,
                'appearanceStatus': 'observed',
                'visualObservation':
                    '${bodyRegionNames[region]} outline is visible in the supplied photos.',
                'visualEvidenceViews': ['front'],
                'limitations': [],
              },
          ],
        },
      },
    };

BodyOverview _overview() => BodyOverview.fromJson({
      'profile': {'weight': 75.2, 'gender': 'MALE'},
      'records': [
        _entry('current', '2026-10-09', 74.1, estimate: true),
        _entry('previous', '2026-10-02', 74.4),
      ],
    });

class _Repository extends BodyAssessmentRepository {
  int maps = 0;

  @override
  Future<BodyOverview> load() async => _overview();

  @override
  Future<TrainingMapData> trainingMap(
      {DateTime? date, bool daily = false}) async {
    maps++;
    return TrainingMapData.fromJson({
      'date': '2026-10-11',
      'weekStart': '2026-10-05',
      'regions': [],
      'summary': {'loggedSets': 0},
    });
  }
}

class _Plans extends WeeklyPlanRepository {
  @override
  Future<Map<String, dynamic>> availability() async => {'canGenerate': true};
}

Widget _app(Widget body,
        {double scale = 1, bool reducedMotion = false, Key? capture}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reducedMotion),
          child: child!),
      home: RepaintBoundary(key: capture, child: Scaffold(body: body)),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': 'opaque',
      'fitai_user_id': 'body-test',
    });
  });

  test(
      'Latest synced readings retain their source and exclude profile/preview trends',
      () {
    final summary = BodyProgressSummary(BodyOverview.fromJson({
      'profile': {'weight': 80},
      'records': [
        _entry('profile', '2026-10-11', 80, source: 'profile'),
        _entry('manual', '2026-10-09', 75),
        _entry('preview', '2026-10-12', 10, source: 'preview'),
      ],
      'syncedMeasurements': [
        {
          'date': '2026-10-10',
          'weight': 74.4,
          'sourceProvider': 'GOOGLE_HEALTH_CONNECT'
        },
        {
          'date': '2026-10-08',
          'weight': 74.8,
          'sourceProvider': 'GOOGLE_HEALTH_CONNECT'
        },
      ],
    }));
    expect(summary.weight!.metric.value, 74.4);
    expect(summary.weight!.sourceLabel, 'Health Connect');
    expect(summary.weightTrend.map((reading) => reading.metric.value),
        [74.8, 74.4]);
  });

  test('Latest corrections and photo ranges retain their provenance', () {
    final summary = BodyProgressSummary(BodyOverview.fromJson({
      'records': [
        _entry('early', '2026-10-09', 74.4, hour: '08'),
        _entry('late', '2026-10-09', 74.1, hour: '12', estimate: true),
        _entry('baseline', '2026-10-02', 75),
      ],
    }));
    expect(summary.weight!.metric.value, 74.1);
    expect(summary.weightTrend.length, 2);
    expect(summary.latest('waistCm')!.metric.display('cm'), '82–92 cm');
  });

  testWidgets(
      'Training and Physique stay separate; measurements and history remain reachable',
      (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(_app(BodyView(
        repository: repository, planRepository: _Plans(), onTrain: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Physique'), findsOneWidget);
    expect(find.byType(AnatomicalTrainingMap), findsOneWidget);
    expect(repository.maps, 1);

    await tester.tap(find.text('Physique'));
    await tester.pumpAndSettle();
    expect(find.text('Photo scan'), findsOneWidget);
    expect(find.text('Generate weekly plan'), findsOneWidget);
    expect(find.byType(AnatomicalTrainingMap), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('Your saved readings and sources'), 220,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Your saved readings and sources'));
    await tester.pumpAndSettle();
    expect(find.byType(BodyMeasurementsView), findsOneWidget);
    await tester.scrollUntilVisible(find.text('82–92 cm'), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('82–92 cm'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Right arm'), -150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Right arm'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Body history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body history'));
    await tester.pumpAndSettle();
    expect(find.byType(BodyHistoryView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Body and Progress stay intact during tab and animation changes',
      (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    final bodyRepository = _Repository();
    final plans = _Plans();

    Widget dashboard({bool reducedMotion = false}) => _app(
          ValueListenableBuilder<int>(
            valueListenable: selected,
            builder: (context, index, _) => AnimatedTabStack(
              index: index,
              children: [
                TickerMode(
                  enabled: index == 0,
                  child: BodyView(
                    isActive: index == 0,
                    repository: bodyRepository,
                    planRepository: plans,
                    onTrain: () {},
                  ),
                ),
                TickerMode(
                  enabled: index == 1,
                  child: ProgressOverviewView(
                    isActive: index == 1,
                    initial: const ProgressOverview({}),
                  ),
                ),
              ],
            ),
          ),
          reducedMotion: reducedMotion,
        );

    await tester.pumpWidget(dashboard());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Physique'));
    await tester.pumpAndSettle();
    expect(find.text('Your weekly plan'), findsOneWidget);
    expect(find.text('Photo scan'), findsOneWidget);

    selected.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    await tester.pumpWidget(dashboard(reducedMotion: true));
    await tester.pumpAndSettle();
    expect(find.text('Progress'), findsOneWidget);
    expect(tester.takeException(), isNull);

    selected.value = 0;
    await tester.pumpAndSettle();
    final physique = find.byType(BodyPhysiqueHome);
    expect(physique, findsOneWidget);
    expect(find.text('Your weekly plan'), findsOneWidget);
    expect(find.text('Photo scan'), findsOneWidget);
    await tester
        .widget<RefreshIndicator>(find.descendant(
          of: physique,
          matching: find.byType(RefreshIndicator),
        ))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(find.text('Your weekly plan'), findsOneWidget);
    expect(find.text('Photo scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Physique preserves the map and fits large text on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(
        BodyView(
            repository: _Repository(),
            planRepository: _Plans(),
            onTrain: () {}),
        scale: 1.8));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Physique'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Arms'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.text('Arms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arms'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Biceps'), 150,
        scrollable: find.byType(Scrollable).last);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Measurement and history screens keep ranges and fit enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var additions = 0;
    await tester.pumpWidget(_app(
        BodyMeasurementsView(
            overview: _overview(), onAdd: () => additions++, onRecord: (_) {}),
        scale: 1.8));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('82–92 cm'), 160,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Add measurements'));
    await tester.pump();
    expect(additions, 1);
    await tester.pumpWidget(_app(
        BodyHistoryView(overview: _overview(), onRecord: (_) {}),
        scale: 1.8));
    await tester.pumpAndSettle();
    expect(find.text('Report saved · Photos not kept'), findsOneWidget);
    expect(find.text('Waist 82–92 cm'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Capture the silver measurements and history', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final screen in {
      'body-measurements': BodyMeasurementsView(
          overview: _overview(), onAdd: () {}, onRecord: (_) {}),
      'body-history': BodyHistoryView(overview: _overview(), onRecord: (_) {}),
    }.entries) {
      final capture = ValueKey(screen.key);
      await tester.pumpWidget(_app(screen.value, capture: capture));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/previews/${screen.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Capture the restored native Physique screen', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const capture = ValueKey('body-physique-capture');
    await tester.pumpWidget(_app(
        BodyView(
            repository: _Repository(),
            planRepository: _Plans(),
            onTrain: () {}),
        capture: capture));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Physique'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/body-physique-restored.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });
}
