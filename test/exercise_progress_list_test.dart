import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/progress/components/exercise_overview_control.dart';
import 'package:setcraft/features/progress/repositories/progress_repository.dart';
import 'package:setcraft/features/progress/views/progress_exercises_view.dart';

class _Repository extends ProgressRepository {
  final queries = <Map<String, dynamic>>[];
  final selected = <String>[];
  @override
  Future<Map<String, dynamic>> load(String path, String period,
      {bool refresh = false, Map<String, dynamic> query = const {}}) async {
    queries.add({...query});
    final more = query['cursor'] != null;
    final search = query['search'] as String? ?? '';
    return {
      'range': {'start': '2026-09-25', 'end': '2026-10-22'},
      'nextCursor': more ? null : 'next',
      'items': [
        {
          'id': more ? 'squat' : 'row',
          'name': more
              ? 'Barbell squat'
              : search.isEmpty
                  ? 'Dumbbell bent over row'
                  : 'Cable row',
          'latest': {'weight': more ? 40 : 12, 'reps': 10},
          'latestDate': '2026-10-21',
          'sessions': 4,
          'metric': 'load',
          'change': 20,
          'sparkline': [
            {'date': '2026-10-01', 'value': 10},
            {'date': '2026-10-21', 'value': 12}
          ]
        },
        if (!more && search.isEmpty)
          {
            'id': 'bench',
            'name': 'Barbell bench press',
            'latest': {'weight': null, 'reps': 10},
            'latestDate': '2026-10-20',
            'sessions': 1,
            'metric': 'reps',
            'sparkline': [
              {'date': '2026-10-20', 'value': 10}
            ]
          },
      ],
    };
  }

  @override
  Future<List<String>> pins() async => [...selected];
  @override
  Future<void> setPinned(String id, bool enabled) async {
    if (enabled && selected.length >= 3)
      throw const FormatException(
          'Your overview already shows three exercises. Remove one before adding another.');
    if (enabled) {
      selected.add(id);
    } else {
      selected.remove(id);
    }
  }
}

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  testWidgets(
      'Search, muscle selection and pagination retain their query context',
      (tester) async {
    final repo = _Repository();
    await tester.pumpWidget(MaterialApp(
        home: ProgressExercisesView(
            period: 'custom',
            muscles: const [
              {'id': 'lats', 'label': 'Lats'}
            ],
            query: const {'start': '2026-09-25', 'end': '2026-10-22'},
            repository: repo)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pin exercise'), findsNothing);
    expect(find.textContaining('Weight not recorded'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'row');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All muscles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lats').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(repo.queries.last, containsPair('search', 'row'));
    expect(repo.queries.last, containsPair('muscle', 'lats'));
    expect(repo.queries.last, containsPair('start', '2026-09-25'));
    expect(repo.queries.last, containsPair('cursor', 'next'));
    expect(find.text('Cable row'), findsOneWidget);
    expect(find.text('Barbell squat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Overview limit explains the conflict without replacing a saved exercise',
      (tester) async {
    final repo = _Repository()..selected.addAll(['one', 'two', 'three']);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FitnessTheme(
                child: ExerciseOverviewControl(
                    exerciseId: 'four', repository: repo)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show on overview'));
    await tester.pumpAndSettle();
    expect(repo.selected, ['one', 'two', 'three']);
    expect(find.textContaining('Remove one before adding another'),
        findsOneWidget);
  });
  testWidgets(
      'List remains readable at larger text sizes and renders the native preview',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final capture = GlobalKey();
    Widget app(double scale) => MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
                key: capture,
                child: ProgressExercisesView(
                    period: '4w',
                    muscles: const [],
                    repository: _Repository()))));
    await tester.pumpWidget(app(1.8));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    final boundary =
        capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/exercise-progress-list.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
