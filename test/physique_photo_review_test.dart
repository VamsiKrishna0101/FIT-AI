import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitai_mobile/core/theme/fitness_theme.dart';
import 'package:fitai_mobile/features/body_scan/models/body_assessment_models.dart';
import 'package:fitai_mobile/features/body_scan/repositories/body_assessment_repository.dart';
import 'package:fitai_mobile/features/body_scan/views/body_photo_review_view.dart';
import 'package:fitai_mobile/features/body_scan/views/body_estimate_view.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/body_controls.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/physique_photo_report.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/photo_comparison_studio.dart';
import 'package:fitai_mobile/features/body_scan/views/body_history_view.dart';
import 'package:fitai_mobile/features/body_scan/models/physique_dashboard_models.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/composition_readings_sheet.dart';

BodyAssessment scan(String id,
        {String date = '2026-10-20',
        List<String> views = const ['front'],
        bool saved = true,
        bool scored = false}) =>
    BodyAssessment.fromJson({
      'id': id,
      'recordedDate': date,
      'status': 'SAVED',
      'method': 'photo_review',
      'updatedAt': '${date}T12:00:00Z',
      'metrics': {},
      'observations': [],
      'photos': saved
          ? [
              for (final view in views)
                {'id': '$id-$view', 'view': view, 'url': '/private/$id/$view'}
            ]
          : [],
      'quality': {
        'visualCoachingConsent': true,
        'physiqueAssessment': {
          'version': 'physique-v3',
          'photosUsed': views.length,
          if (scored)
            'dashboard': {
              'version': 'photo-dashboard-v1',
              'geometry': {
                'version': 'visual-contour-index-v1',
                'status': 'experimental',
                'score': 94,
                'qualityNotes': []
              },
              'metrics': [
                {
                  'id': 'body_fat',
                  'value': 22.5,
                  'source': 'member_reading',
                  'recordedDate': date
                },
                {
                  'id': 'muscle_mass',
                  'value': 31,
                  'source': 'member_reading',
                  'recordedDate': date
                },
                {'id': 'v_taper', 'value': 1.24, 'source': 'photo_geometry'},
                {'id': 'definition', 'value': 45, 'source': 'ai_visual_rating'},
                {'id': 'chest', 'value': 96, 'source': 'photo_geometry'},
                {'id': 'shoulders', 'value': 98, 'source': 'photo_geometry'},
              ],
            },
          'overview':
              'Visible outlines, with clothing and pose taken into account.',
          'highlights': [
            {
              'id': 'symmetry',
              'appearanceStatus': 'unclear',
              'observation': 'Arm position limits left/right comparison.',
              'limitations': ['Match your arm position.']
            },
            {
              'id': 'v_taper',
              'appearanceStatus': 'observed',
              'observation': 'The shoulder-to-waist outline is visible.',
              'limitations': []
            },
            {
              'id': 'chest',
              'appearanceStatus': 'unclear',
              'observation': 'Clothing covers chest definition.',
              'limitations': []
            },
          ],
          'regions': [
            for (final id in bodyRegionNames.keys)
              {
                'region': id,
                'appearanceStatus': 'unclear',
                'visualObservation': 'Clothing limits the visible detail.',
                'limitations': ['A photo does not measure muscle size.']
              }
          ],
        }
      },
    });

class _Repository extends BodyAssessmentRepository {
  final Completer<BodyAssessment> result = Completer();
  Map<String, dynamic>? payload;
  List<BodyAssessment> records = [];
  List<BodyAssessment> baselines = [];
  @override
  Future<Map<String, dynamic>> history(
          {String? from, String? to, int page = 1}) async =>
      {
        'records': [],
        'comparisonBaselines': [],
        'total': 0,
        'pageSize': 12,
      };
  @override
  Future<BodyOverview> load() async => _Overview(records);
  @override
  Future<BodyAssessment> review(Map<String, dynamic> data,
      {required bool Function() cancelled,
      void Function(String)? onStage}) async {
    payload = data;
    onStage?.call('focus');
    return result.future;
  }
}

class _Overview extends BodyOverview {
  final List<BodyAssessment> _records;
  @override
  List<BodyAssessment> get records => _records;
  _Overview(this._records) : super.fromJson({'records': []});
}

const boundary = ValueKey('photo-review-preview');
Widget app(Widget child, {double scale = 1, bool reduced = false}) =>
    RepaintBoundary(
        key: boundary,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: reduced),
                child: child!),
            home: FitnessTheme(child: child)));
Future<void> size(WidgetTester tester,
    {double width = 393, double height = 852}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<Uint8List> fixturePhoto() async {
  // An illustration for UI tests only, never uploaded or used as an AI finding.
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 500, 700),
      Paint()..color = const Color(0xFF25282D));
  final body = Path()
    ..moveTo(170, 100)
    ..lineTo(330, 100)
    ..lineTo(375, 170)
    ..lineTo(340, 300)
    ..lineTo(322, 300)
    ..lineTo(310, 220)
    ..lineTo(304, 390)
    ..lineTo(196, 390)
    ..lineTo(190, 220)
    ..lineTo(178, 300)
    ..lineTo(160, 300)
    ..lineTo(125, 170)
    ..close();
  canvas.drawPath(body, Paint()..color = const Color(0xFF747A82));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(197, 380, 48, 260), const Radius.circular(20)),
      Paint()..color = const Color(0xFF444B55));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(255, 380, 48, 260), const Radius.circular(20)),
      Paint()..color = const Color(0xFF444B55));
  final image = await recorder.endRecording().toImage(500, 700);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<void> snapshot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(
          image.image, tester.element(find.byType(Image).first));
    }
  });
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build').createSync(recursive: true);
    File('build/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List photo;
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
    photo = await fixturePhoto();
  });
  test('comparison requires two distinct saved scans with the same view', () {
    final current = scan('current');
    expect(
        current.canComparePhotosWith(scan('before', date: '2026-10-01')), true);
    expect(current.canComparePhotosWith(current), false);
    expect(
        current.canComparePhotosWith(
            scan('before', date: '2026-10-01', views: ['back'])),
        false);
    expect(
        current.canComparePhotosWith(
            scan('before', date: '2026-10-01', saved: false)),
        false);
    expect(
        scan('current', saved: false)
            .canComparePhotosWith(scan('before', date: '2026-10-01')),
        false);
    expect(
        current.canComparePhotosWith(scan('later', date: '2026-10-21')), false);
  });
  testWidgets(
      'one front photo and consent start review without weight or photo retention',
      (tester) async {
    await size(tester);
    final repo = _Repository();
    await tester.pumpWidget(app(
        BodyPhotoReviewView(repository: repo, pickPhoto: (_) async => photo)));
    await tester.tap(find.byKey(const ValueKey('pick-review-photo')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(repo.payload, isNull);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('photo-analysis-consent')), 160);
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const ValueKey('save-scan-photos')))
            .value,
        false);
    await tester.tap(find.byKey(const ValueKey('photo-analysis-consent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review my physique'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(repo.payload!['weightKg'], isNull);
    expect(repo.payload!['savePhotos'], false);
    expect((repo.payload!['photos'] as List).length, 1);
    expect(find.byKey(const ValueKey('physique-scan-line')), findsOneWidget);
    final scanProgress = (tester
            .widget<CustomPaint>(
                find.byKey(const ValueKey('physique-scan-line')))
            .painter as dynamic)
        .progress as double;
    await tester.pump(const Duration(milliseconds: 500));
    final nextProgress = (tester
            .widget<CustomPaint>(
                find.byKey(const ValueKey('physique-scan-line')))
            .painter as dynamic)
        .progress as double;
    expect(nextProgress, greaterThan(scanProgress),
        reason: 'The scan line must actually travel down the photo.');
    await snapshot(tester, 'physique-scan-preview');
    repo.result.complete(scan('current', saved: false, scored: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('physique-scan-line')), findsNothing);
    expect(find.byKey(const ValueKey('compare-saved-scans')), findsNothing);
    expect(find.byType(PhysiquePhotoReport), findsOneWidget);
    expect(find.text('94'), findsOneWidget);
    expect(find.text('BODY FAT'), findsOneWidget);
    expect(find.text('MUSCLE MASS'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await snapshot(tester, 'physique-photo-result-preview');
  });
  testWidgets(
      'compare appears only after the second scan with saved matching photos',
      (tester) async {
    await size(tester);
    final repo = _Repository()..records = [scan('before', date: '2026-10-01')];
    await tester.pumpWidget(app(BodyEstimateView(
        repository: repo,
        localPhotos: {'front': photo},
        estimate: (_, __) => repo.result.future)));
    await tester.pump();
    expect(find.byKey(const ValueKey('compare-saved-scans')), findsNothing);
    repo.result.complete(scan('current'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('compare-saved-scans')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const ValueKey('compare-saved-scans')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'scan sweep remains visible with Android animation scale disabled and stops on completion',
      (tester) async {
    await size(tester);
    final pending = Completer<BodyAssessment>();
    await tester.pumpWidget(app(
        BodyEstimateView(
            localPhotos: {'front': photo}, estimate: (_, __) => pending.future),
        reduced: true));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    final line = find.byKey(const ValueKey('physique-scan-line'));
    expect(line, findsOneWidget);
    final before = (tester.widget<CustomPaint>(line).painter as dynamic)
        .progress as double;
    await tester.pump(const Duration(milliseconds: 600));
    expect(
        (tester.widget<CustomPaint>(line).painter as dynamic).progress
            as double,
        greaterThan(before));
    pending.complete(scan('current', saved: false));
    await tester.pumpAndSettle();
    expect(find.byType(PhysiquePhotoReport), findsOneWidget);
    expect(line, findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'report-only scans retain the full dashboard with a private optional background',
      (tester) async {
    await size(tester);
    var picks = 0;
    await tester.pumpWidget(app(Scaffold(
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: PhysiquePhotoReport(
              entry: scan('report-only', saved: false, scored: true),
              pickBackground: () async {
                picks++;
                return photo;
              },
            )))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('physique-report-background')),
        findsOneWidget);
    for (final metric in [
      'body_fat',
      'muscle_mass',
      'v_taper',
      'definition',
      'chest',
      'shoulders'
    ]) {
      expect(find.byKey(ValueKey('photo-metric-$metric')), findsOneWidget);
    }
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('choose-report-background')), 200);
    await tester.tap(find.byKey(const ValueKey('choose-report-background')));
    await tester.pumpAndSettle();
    expect(picks, 1);
    expect(find.text('94'), findsOneWidget);
    expect(find.text('Display photo · not analysed'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'results retain real observations and detail sheets on small screens',
      (tester) async {
    await size(tester, width: 320, height: 720);
    await tester.pumpWidget(app(
        Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: PhysiquePhotoReport(
                    entry: scan('current', saved: false, scored: true),
                    localPhotos: {'front': photo}))),
        scale: 1.6));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('photo-summary-symmetry')), 160);
    await tester.tap(find.byKey(const ValueKey('photo-summary-symmetry')));
    await tester.pumpAndSettle();
    expect(find.text('Match your arm position.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'comparison drag, alignment and matching views work without phantom views',
      (tester) async {
    await size(tester);
    await tester.pumpWidget(app(Scaffold(
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: PhotoComparisonStudio(
                before: scan('before', date: '2026-10-01'),
                after: scan('current'),
                imageBuilder: (p) =>
                    Image.memory(photo, fit: BoxFit.contain))))));
    await tester.pumpAndSettle();
    expect(find.text('Back'), findsNothing);
    final slider = find.byKey(const ValueKey('photo-comparison-split'));
    final initial = tester.widget<Slider>(slider).value;
    await tester.drag(find.byKey(const ValueKey('photo-comparison-handle')),
        const Offset(65, 0));
    await tester.pump();
    expect(tester.widget<Slider>(slider).value, greaterThan(initial));
    await snapshot(tester, 'physique-comparison-preview');
    await tester.scrollUntilVisible(find.text('Align earlier photo'), 100);
    await tester.tap(find.text('Align earlier photo'));
    await tester.pumpAndSettle();
    expect(find.text('Horizontal'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Side by side'), -100);
    await tester.tap(find.text('Side by side'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-comparison-handle')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test('composition cannot be sourced from AI and missing scores stay missing',
      () {
    final data = PhysiqueDashboardData.fromJson({
      'metrics': [
        {'id': 'body_fat', 'value': 15, 'source': 'ai_visual_rating'},
        {'id': 'muscle_mass', 'value': 90, 'source': 'photo_geometry'},
      ]
    });
    expect(data.score, isNull);
    expect(data.metrics.where((m) => m.value != null), isEmpty);
  });
  testWidgets('reading form validates numbers and accepts decimal commas',
      (tester) async {
    await size(tester);
    Map<String, dynamic>? result;
    await tester.pumpWidget(app(Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                onPressed: () async => result = await showCompositionReadings(
                    context,
                    scanDate: '2026-10-20'),
                child: const Text('Readings'))))));
    await tester.tap(find.text('Readings'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '95');
    await tester.tap(find.text('Use these readings'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.enterText(find.byType(TextFormField).first, '22,5');
    await tester.tap(find.text('Use these readings'));
    await tester.pumpAndSettle();
    expect(result?['bodyFatPct'], 22.5);
    expect(result?['source'], 'smart_scale');
    expect(result?.containsKey('muscleMassKg'), false);
  });
  testWidgets('history empty state has one compact date filter and no compare',
      (tester) async {
    await size(tester);
    await tester.pumpWidget(
        app(BodyHistoryView(repository: _Repository(), onRecord: (_) {})));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.text('Compare'), findsNothing);
    expect(find.text('No saved scans yet.'), findsOneWidget);
  });
}
