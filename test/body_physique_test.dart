import 'fixtures/body_map_fixture.dart';
import 'package:setcraft/features/body_scan/models/body_map_models.dart';
import 'package:setcraft/features/body_scan/models/planned_physique_models.dart';
import 'package:setcraft/features/planner/views/weekly_plan_card.dart';
import 'package:setcraft/core/theme/fitness_accents.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/body_scan/models/body_assessment_models.dart';
import 'package:setcraft/features/body_scan/models/training_map_models.dart';
import 'package:setcraft/features/body_scan/repositories/body_assessment_repository.dart';
import 'package:setcraft/features/body_scan/views/body_view.dart';
import 'package:setcraft/features/body_scan/views/body_entry_view.dart';
import 'package:setcraft/features/body_scan/views/body_photo_review_view.dart';
import 'package:setcraft/features/body_scan/views/body_estimate_view.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_focus_panel.dart';
import 'package:setcraft/features/body_scan/views/body_comparison_view.dart';
import 'package:setcraft/features/body_scan/views/body_history_view.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_physique_dashboard.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_physique_home.dart';
import 'package:setcraft/features/body_scan/views/widgets/anatomical_training_map.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_controls.dart';

Map<String, dynamic> _metric(double value, [String source = 'tape']) =>
    {'value': value, 'source': source};
Map<String, dynamic> _entry(String id, String date, {bool estimates = false}) =>
    {
      'id': id,
      'recordedDate': date,
      'status': estimates ? 'REVIEW' : 'SAVED',
      'method': estimates ? 'photo_review' : 'entered',
      'updatedAt': '${date}T10:00:00.000Z',
      'photos': [],
      'observations': [],
      'summary':
          estimates ? 'Synthetic visual review, not real member data.' : null,
      'quality': {
        'notes':
            estimates ? ['Legs are covered; no size estimate for them.'] : []
      },
      'metrics': {
        'weightKg': _metric(id == 'previous' ? 75.2 : 74.1, 'scale'),
        'bodyFatPct': estimates
            ? {'value': 22, 'low': 18, 'high': 26, 'source': 'photo_estimate'}
            : _metric(id == 'previous' ? 23.5 : 21.3,
                id == 'previous' ? 'calipers' : 'smart_scale'),
        'chestCm': _metric(id == 'previous' ? 102 : 103.5),
        'waistCm': estimates
            ? {'value': 87, 'low': 82, 'high': 92, 'source': 'photo_estimate'}
            : _metric(id == 'previous' ? 85.2 : 83.4),
        if (!estimates) ...{
          'hipsCm': _metric(98.5),
          'leftArmCm': _metric(34.7),
          'rightArmCm': _metric(35),
          'leftThighCm': _metric(59.8),
          'rightThighCm': _metric(60.2)
        },
      },
    };
final _current = _entry('current', '2026-10-07'),
    _previous = _entry('previous', '2026-09-30');
final _overview = BodyOverview.fromJson({
  'profile': {
    'gender': 'MALE',
    'weight': 75.2,
    'focusMuscles': ['chest', 'quads']
  },
  'records': [_current, _previous]
});
final _comparison = BodyComparison.fromJson({
  'current': _current,
  'previous': _previous,
  'metrics': {
    'weightKg': {'status': 'decreased', 'delta': -1.1},
    'waistCm': {'status': 'decreased', 'delta': -1.8},
    'chestCm': {'status': 'increased', 'delta': 1.5},
    'bodyFatPct': {'status': 'different_method', 'delta': null},
    'leftArmCm': {'status': 'unchanged', 'delta': 0},
    'rightArmCm': {'status': 'unchanged', 'delta': 0}
  },
  'regions': {
    'chest': 'increased',
    'core': 'decreased',
    'glutes': 'unchanged',
    'biceps': 'unchanged',
    'quads': 'unavailable',
    'calves': 'unavailable'
  },
});

class _Repository extends BodyAssessmentRepository {
  @override
  Future<BodyMapData> bodyMap(
          {DateTime? date, BodyDateSelection? selection}) async =>
      emptyBodyMap(date);

  @override
  Future<PlannedPhysiqueData> plannedPhysique({DateTime? date}) async =>
      PlannedPhysiqueData.fromJson({'status': 'none', 'workouts': []});
  int loads = 0;
  int comparisons = 0;
  @override
  Future<Map<String, dynamic>> history(
          {String? from, String? to, int page = 1}) async =>
      {'records': [], 'total': 0, 'page': page, 'pageSize': 12};
  @override
  Future<TrainingMapData> trainingMap(
          {DateTime? date, bool daily = false}) async =>
      TrainingMapData.fromJson(
          jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
              as Map<String, dynamic>);
  @override
  Future<BodyOverview> load() async {
    loads++;
    return _overview;
  }

  @override
  Future<BodyComparison> compare(String current, String previous) async {
    comparisons++;
    return _comparison;
  }
}

const _preview = ValueKey('physique-preview');
Widget _app(Widget child, {double scale = 1, double keyboard = 0}) =>
    RepaintBoundary(
        key: _preview,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            builder: (context, navigator) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    viewInsets: EdgeInsets.only(bottom: keyboard)),
                child: navigator!),
            home: FitnessTheme(child: Scaffold(body: child))));
BodyPhysiqueDashboard _dashboard(
        {BodyOverview? data, BodyComparison? comparison}) =>
    BodyPhysiqueDashboard(
        overview: data ?? _overview,
        comparison: comparison ?? _comparison,
        onRefresh: () async {},
        onAdd: () {},
        onPhotos: () {},
        onPreferences: () {},
        onTrain: () {},
        onCompare: () {},
        onBaseline: () {},
        onRecord: (_) {});
Future<void> _size(WidgetTester tester,
    {double width = 393, double height = 852}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _snapshot(WidgetTester tester, String name,
    {Key preview = _preview}) async {
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(preview));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build').createSync(recursive: true);
    File('build/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('visual ranges and comparison labels retain provenance', () {
    final review = BodyAssessment.fromJson(
        _entry('review', '2026-10-07', estimates: true));
    expect(review.metrics['bodyFatPct']!.display('%'), '18–26%');
    expect(review.metrics['waistCm']!.display('cm'), '82–92 cm');
    expect(_comparison.label('bodyFatPct'), 'Different sources');
    expect(_comparison.label('waistCm'), '-1.8 cm');
  });
  testWidgets(
      'Body keeps its fixed header and measurement history without photo sections',
      (tester) async {
    await _size(tester);
    final repository = _Repository();
    await tester
        .pumpWidget(_app(BodyView(onTrain: () {}, repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text('Measurements'), findsOneWidget);
    expect(find.text('Target met'), findsNothing);
    expect(find.byType(WeeklyPlanCard), findsNothing);
    expect(find.byType(BodyPhysiqueHome), findsNothing);
    expect(repository.loads, 1);
    expect(repository.comparisons, 0);
    await tester
        .ensureVisible(find.byKey(const ValueKey('body-measurement-weightKg')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-measurement-weightKg')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Measurement history').last);
    await tester.pumpAndSettle();
    expect(find.byType(BodyHistoryView), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Compare'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final header =
        tester.getTopLeft(find.byKey(const ValueKey('body-fixed-header')));
    await tester.drag(
        find.byKey(const ValueKey('body-scroll')), const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('body-fixed-header'))),
        header);
    expect(tester.takeException(), isNull);
  });

  testWidgets('front/back map and chosen focus use explicit meanings',
      (tester) async {
    await _size(tester);
    await tester.pumpWidget(_app(_dashboard()));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
            .colors['core'],
        FitnessTheme.coral);
    await tester.tap(find.text('Your focus'));
    await tester.pumpAndSettle();
    final map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(map.colors['chest'], FitnessTheme.blue);
    expect(map.colors['core'], const Color(0xFF555555));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
            .back,
        isTrue);
    await _snapshot(tester, 'body-physique-back-preview');
  });
  testWidgets(
      'small phone and enlarged text: dashboard, female map and comparison fit',
      (tester) async {
    await _size(tester, width: 320, height: 640);
    final female = BodyOverview.fromJson({
      'profile': {
        'gender': 'FEMALE',
        'focusMuscles': ['glutes']
      },
      'records': [_current, _previous]
    });
    await tester.pumpWidget(_app(_dashboard(data: female), scale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        tester
            .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
            .female,
        isTrue);
    await tester.drag(
        find.byType(BodyPhysiqueDashboard), const Offset(0, -620));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester
        .pumpWidget(_app(BodyComparisonPanel(data: _comparison), scale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('No saved photos'), findsOneWidget);
    expect(find.text('Right'), findsNothing);
    await _snapshot(tester, 'body-comparison-preview');
  });
  testWidgets('photo midpoint is excluded from measured trends',
      (tester) async {
    await _size(tester);
    final review = BodyAssessment.fromJson(
        _entry('review', '2026-10-07', estimates: true));
    await tester.pumpWidget(_app(BodyMetricTrend(
        records: [review, _overview.records.last], metricKey: 'waistCm')));
    await tester.pumpAndSettle();
    expect(find.text('Add two tape readings to see a trend.'), findsOneWidget);
  });
  testWidgets(
      'Editing measurements excludes old visual estimates unless replaced by an entered reading',
      (tester) async {
    await _size(tester);
    Map<String, dynamic>? submitted;
    final review = BodyAssessment.fromJson(
        _entry('review', '2026-10-07', estimates: true));
    await tester.pumpWidget(_app(BodyEntryView(
        existing: review,
        onSubmit: (data) async {
          submitted = data;
        })));
    await tester.pumpAndSettle();
    expect(find.text('18–26%'), findsNothing);
    final field = find.byKey(const ValueKey('body-input-bodyFatPct'));
    await tester.ensureVisible(field);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    await tester.enterText(field, '21');
    await tester.tap(find.text('Save measurements'));
    await tester.pumpAndSettle();
    expect((submitted!['metrics'] as Map)['bodyFatPct'],
        {'value': 21.0, 'source': 'manual_estimate'});
  });

  testWidgets('Forms survive keyboard and reject implausible entered weight',
      (tester) async {
    await _size(tester, width: 320, height: 640);
    var saves = 0;
    await tester.pumpWidget(_app(BodyEntryView(onSubmit: (_) async {
      saves++;
    }), scale: 1.3, keyboard: 260));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('body-input-weightKg')), '999');
    await tester.tap(find.text('Save measurements'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.text('20–500 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'initial physique fits small screens without reports or comparisons',
      (tester) async {
    await _size(tester, width: 320, height: 640);
    await tester.pumpWidget(_app(
        BodyPhysiqueHome(
            overview: BodyOverview.fromJson({
              'records': [_current]
            }),
            onRefresh: () async {},
            onPhotos: () {},
            onManual: () {},
            onMeasurements: () {},
            onHistory: () {}),
        scale: 1.3));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Explore'), 120,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Compare'), findsNothing);
    expect(find.text('Your progress'), findsNothing);
    expect(find.text('Report saved · Photos not kept'), findsNothing);
    expect(tester.takeException(), isNull);
    await _snapshot(tester, 'body-initial-small-preview');
  });
  testWidgets(
      'estimate stages lead directly to a saved heatmap without measurement review',
      (tester) async {
    await _size(tester);
    final result = Completer<BodyAssessment>();
    ValueChanged<String>? stage;
    bool? saved;
    await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
                  builder: (_) =>
                      BodyEstimateView(estimate: (onStage, cancelled) {
                        stage = onStage;
                        return result.future;
                      })));
            },
            child: const Text('Start estimate')))));
    await tester.tap(find.text('Start estimate'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    stage!('outlines');
    await tester.pump();
    expect(find.text('Reading your body outlines'), findsOneWidget);
    stage!('focus');
    await tester.pump();
    expect(find.text('Preparing your body report'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    await _snapshot(tester, 'body-estimate-loading-preview');
    result.complete(BodyAssessment.fromJson({
      ..._current,
      'summary': 'Build a consistent, balanced routine.',
      'quality': {'focusStatus': 'ready'},
      'observations': [
        {
          'region': 'chest',
          'kind': 'suggested_focus',
          'basis': 'profile_goal',
          'observation': 'Chest training supports your muscle-building goal.'
        }
      ]
    }));
    await tester.pumpAndSettle();
    expect(find.byType(BodyFocusPanel), findsOneWidget);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('Extra emphasis'), findsOneWidget);
    expect(find.text('Body fat'), findsNothing);
    expect(find.text('Generate this week’s plan · Coming soon'), findsNothing);
    expect(tester.takeException(), isNull);
    await _snapshot(tester, 'body-estimate-result-preview');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(saved, true);
    expect(find.text('Start estimate'), findsOneWidget);
  });
  testWidgets(
      'small estimate screen reports failures and cancels pending work on back',
      (tester) async {
    await _size(tester, width: 320, height: 640);
    var calls = 0;
    bool Function()? cancelled;
    final pending = Completer<BodyAssessment>();
    await tester.pumpWidget(_app(
        Builder(
            builder: (context) => TextButton(
                onPressed: () =>
                    Navigator.of(context).push<bool>(MaterialPageRoute(
                        builder: (_) => BodyEstimateView(
                            female: true,
                            estimate: (stage, isCancelled) {
                              calls++;
                              cancelled = isCancelled;
                              if (calls == 1) {
                                return Future.error(
                                    StateError('Retake the back view.'));
                              }
                              stage('outlines');
                              return pending.future;
                            }))),
                child: const Text('Start estimate'))),
        scale: 1.3));
    await tester.tap(find.text('Start estimate'));
    await tester.pumpAndSettle();
    expect(find.text('Retake the back view.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(calls, 2);
    expect(cancelled!(), false);
    await tester.tap(find.byTooltip('Cancel estimate'));
    await tester.pumpAndSettle();
    expect(cancelled!(), true);
    pending.complete(BodyAssessment.fromJson(_current));
    await tester.pumpAndSettle();
    expect(find.byType(BodyFocusPanel), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'photo insights cover observed areas independently of three training priorities',
      (tester) async {
    await _size(tester, width: 320, height: 640);
    final entry = BodyAssessment.fromJson({
      ..._current,
      'observations': [
        {
          'region': 'chest',
          'kind': 'suggested_focus',
          'basis': 'profile_goal',
          'observation': 'Goal-based extra emphasis.'
        }
      ],
      'quality': {
        'focusStatus': 'ready',
        'bodyRegions': [
          for (final id in bodyRegionNames.keys)
            {
              'region': id,
              'status': id == 'chest' ? 'focus' : 'balanced',
              'reason': 'Train $id in your routine.',
              'basis': 'profile_goal'
            }
        ],
        'physiqueAssessment': {
          'version': 'physique-v2',
          'photosUsed': 4,
          'model': 'synthetic-model',
          'overview':
              'Synthetic visible proportions; pose and clothing limit interpretation.',
          'regions': [
            for (final id in bodyRegionNames.keys)
              {
                'region': id,
                'appearanceStatus': id == 'forearms' ? 'unclear' : 'observed',
                'visualObservation': id == 'forearms'
                    ? 'Clothing obscures this area.'
                    : 'Visible $id outline in the supplied view.',
                'visualEvidenceViews': id == 'forearms' ? [] : ['front'],
                'trainingDirection': 'Train $id in your routine.',
                'basis': 'profile_goal',
                'limitations': ['Pose can change apparent proportions.']
              }
          ]
        },
        'processing': {
          'operation': 'photo_scan',
          'measurementMs': 1250,
          'geminiMs': 7300,
          'totalMs': 8550
        }
      }
    });
    await tester.pumpWidget(_app(
        SingleChildScrollView(child: BodyFocusPanel(assessment: entry)),
        scale: 1.3));
    await tester.pumpAndSettle();
    var map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(map.colors['chest'], FitnessAccents.gold);
    expect(map.colors['biceps'], FitnessAccents.blue);
    expect(map.colors['forearms'], FitnessAccents.blue);
    expect(
        map.colors.entries
            .where((entry) => entry.value == FitnessAccents.blue)
            .length,
        12);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('Your photo report'), findsOneWidget);
    expect(find.text('Training focus'), findsNothing);
    expect(find.text('Goal-based extra emphasis.'), findsNothing);
    await tester.scrollUntilVisible(find.text('Arms'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Arms'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Biceps'), 150,
        scrollable: find.byType(Scrollable).first);
    await _snapshot(tester, 'body-photo-insights-preview');
    await tester.tap(find.text('Biceps'));
    await tester.pumpAndSettle();
    expect(find.text('Visible biceps outline in the supplied view.'),
        findsNWidgets(2));
    expect(find.textContaining('Pose can change apparent proportions.'),
        findsOneWidget);
    expect(find.text('Train biceps in your routine.'), findsOneWidget);
    expect(find.text('Balanced routine'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await _snapshot(tester, 'body-photo-insights-small-preview');
  });
  testWidgets('body cards shorten old paragraphs and retain details on tap',
      (tester) async {
    await _size(tester);
    const observation =
        'Chest outline is visible from the front. This longer saved observation stays available in the detail sheet.';
    final assessment = BodyAssessment.fromJson({
      ..._current,
      'quality': {
        'photoRetention': 'not_saved',
        'physiqueAssessment': {
          'photosUsed': 4,
          'regions': [
            for (final id in bodyRegionNames.keys)
              {
                'region': id,
                'appearanceStatus': id == 'chest' ? 'observed' : 'unclear',
                'visualObservation':
                    id == 'chest' ? observation : 'Clothing hides this area.',
                'visualEvidenceViews': id == 'chest' ? ['front'] : [],
                'limitations': [],
              }
          ],
        },
      },
    });
    await tester.pumpWidget(_app(
        SingleChildScrollView(child: BodyFocusPanel(assessment: assessment))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Chest outline is visible from the front.'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text(observation), findsNothing);
    await _snapshot(tester, 'body-simple-report-preview');
    await tester.tap(find.text('Chest outline is visible from the front.'));
    await tester.pumpAndSettle();
    expect(find.text(observation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'photo saving is optional and starts off independently of analysis',
      (tester) async {
    await _size(tester, width: 320, height: 720);
    await tester.pumpWidget(
        _app(const BodyPhotoReviewView(profileWeight: 75), scale: 1.8));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-scan-photos')), 160,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const ValueKey('save-scan-photos')))
            .value,
        false);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        false);
    await tester.tap(find.byKey(const ValueKey('save-scan-photos')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const ValueKey('save-scan-photos')))
            .value,
        true);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        false);
    expect(tester.takeException(), isNull);
    await _snapshot(tester, 'body-private-save-small-preview');
  });
  testWidgets(
      'saved reports offer an explicit update with visible photo-use context',
      (tester) async {
    await _size(tester);
    var updates = 0;
    await tester.pumpWidget(_app(SingleChildScrollView(
        child: BodyFocusPanel(
            assessment: BodyAssessment.fromJson(_current),
            onRefreshReport: () => updates++))));
    await tester.pumpAndSettle();
    expect(updates, 0);
    await tester.scrollUntilVisible(find.text('Update body report'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Uses saved measurements with OpenAI.'),
        findsOneWidget);
    await tester.tap(find.text('Update body report'));
    await tester.pump();
    expect(updates, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing guidance stays neutral without inventing scan results',
      (tester) async {
    await _size(tester, width: 320, height: 640);
    await tester.pumpWidget(_app(
        SingleChildScrollView(
            child: BodyFocusPanel(
                assessment: BodyAssessment.fromJson({
          ..._current,
          'summary':
              'Your photo baseline is saved. Focus suggestions are unavailable right now.',
          'quality': {'focusStatus': 'unavailable'}
        }))),
        scale: 1.3));
    await tester.pumpAndSettle();
    final map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(
        map.colors.entries
            .every((entry) => entry.value == FitnessAccents.untrained),
        true);
    expect(find.text('Training guidance, not a strength or symmetry score.'),
        findsOneWidget);
    expect(find.text('Not enough context'), findsOneWidget);
    expect(find.text('Body fat'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'assessment guidance does not colour a workout map without an active plan',
      (tester) async {
    await _size(tester);
    final overview = BodyOverview.fromJson({
      'profile': {
        'gender': 'FEMALE',
        'focusMuscles': ['chest']
      },
      'records': [
        {
          ..._current,
          'quality': {
            'bodyRegions': [
              {
                'region': 'chest',
                'status': 'focus',
                'reason': 'Chest matches your chosen goal.',
                'basis': 'profile_goal'
              },
              {
                'region': 'biceps',
                'status': 'balanced',
                'reason': 'Keep curls in your routine.',
                'basis': 'training_history'
              },
            ]
          }
        }
      ],
    });
    await tester.pumpWidget(_app(BodyPhysiqueHome(
        overview: overview,
        onRefresh: () async {},
        onManual: () {},
        onPhotos: () {},
        onMeasurements: () {},
        onHistory: () {})));
    await tester.pumpAndSettle();
    final map = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(map.colors['chest'], const Color(0xFF30343B));
    expect(map.colors['biceps'], const Color(0xFF30343B));
    expect(map.colors['quads'], const Color(0xFF30343B));
    expect(map.highlighted, isEmpty);
    expect(map.female, isTrue);
    await tester.tapAt(tester.getCenter(find.byType(AnatomicalTrainingMap)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Measurement updates save entered readings without AI coaching or profile defaults',
      (tester) async {
    await _size(tester);
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(_app(BodyEntryView(
        profileWeight: 75,
        onSubmit: (value) async {
          submitted = value;
        })));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('body-input-weightKg')))
            .controller!
            .text,
        isEmpty);
    await tester.enterText(
        find.byKey(const ValueKey('body-input-waistCm')), '86');
    await tester.tap(find.text('Save measurements'));
    await tester.pumpAndSettle();
    expect(submitted!['requestCoaching'], false);
    expect((submitted!['metrics'] as Map).keys, ['waistCm']);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(BodyEntryView(
        weightOnly: true,
        onSubmit: (value) async {
          submitted = value;
        })));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('body-input-waistCm')), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('body-input-weightKg')), '76');
    await tester.tap(find.text('Save weight'));
    await tester.pumpAndSettle();
    expect(submitted!['requestCoaching'], false);
    expect((submitted!['metrics'] as Map)['weightKg'],
        {'value': 76.0, 'source': 'scale'});
  });
}
