import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/body_scan/models/training_map_models.dart';
import 'package:setcraft/features/body_scan/views/widgets/weekly_muscle_coverage.dart';

Map<String, dynamic> fixture() =>
    jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
        as Map<String, dynamic>;
List<MuscleRegion> regions() => TrainingMapData.fromJson(fixture()).regions;
Widget page(Widget child,
        {Locale locale = const Locale('en', 'GB'), double scale = 1}) =>
    MaterialApp(
        locale: locale,
        supportedLocales: const [
          Locale('en', 'GB'),
          Locale('de', 'DE'),
          Locale('de', 'CH')
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: RepaintBoundary(
                    key: const ValueKey('coverage-capture'),
                    child: FitnessTheme(
                        child: Scaffold(
                            body: SafeArea(
                                child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: child))))))));
Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('coverage-capture')))
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
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
  test(
      'Six familiar groups preserve every muscle and exclude assisting sets from progress',
      () {
    final source = regions();
    final groups = MuscleCoverageGroup.fromRegions(source);
    expect(groups.map((group) => group.label),
        ['Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core']);
    final ids = groups
        .expand((group) => group.regions)
        .map((region) => region.id)
        .toList();
    expect(ids.toSet().length, source.length);
    expect(ids.length, source.length);
    expect(groups.first.completed, 6);
    expect(groups.first.target, 10);
    expect(groups.first.progress, .6);
    final arms = groups.firstWhere((group) => group.id == 'arms');
    expect(arms.completed, 0);
    expect(arms.progress, isNull);
    expect(
        arms.regions.fold<int>(0, (sum, region) => sum + region.assistingSets),
        greaterThan(0));
  });
  test('Over-target rings stay bounded while retaining the real logged count',
      () {
    final data = fixture();
    (data['regions'] as List).first['completedSets'] = 14;
    final group =
        MuscleCoverageGroup.fromRegions(TrainingMapData.fromJson(data).regions)
            .first;
    expect(group.progress, 1);
    expect(group.completed, 14);
    expect(group.target, 10);
  });
  testWidgets(
      'Cards open the original muscle detail, including grouped muscles',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? selected;
    await tester.pumpWidget(page(WeeklyMuscleCoverage(
        regions: regions(), onSelect: (id) => selected = id)));
    await tester.pumpAndSettle();
    expect(find.text('6 of 10 planned sets'), findsOneWidget);
    expect(find.text('No planned target'), findsWidgets);
    expect(tester.getTopLeft(find.text('Chest')).dy,
        tester.getTopLeft(find.text('Shoulders')).dy);
    expect(tester.getTopLeft(find.text('Arms')).dy,
        greaterThan(tester.getTopLeft(find.text('Chest')).dy));
    await capture(tester, 'weekly-coverage-populated');
    await tester.tap(find.text('Chest'));
    expect(selected, 'chest');
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Upper back'), findsOneWidget);
    expect(find.text('Lats'), findsOneWidget);
    await tester.tap(find.text('Upper back'));
    await tester.pumpAndSettle();
    expect(selected, 'upper_back');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Empty week has neutral progress and one compact Train action',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = fixture();
    for (final row in data['regions'] as List) {
      row['completedSets'] = 0;
    }
    var opened = false;
    await tester.pumpWidget(page(WeeklyMuscleCoverage(
        regions: TrainingMapData.fromJson(data).regions,
        onSelect: (_) {},
        onTrain: () => opened = true)));
    await tester.pumpAndSettle();
    expect(find.text('0 of 10 planned sets'), findsOneWidget);
    expect(find.text('Not trained yet'), findsWidgets);
    expect(find.text('Open Train'), findsOneWidget);
    await capture(tester, 'weekly-coverage-empty');
    await tester.ensureVisible(find.text('Open Train'));
    await tester.tap(find.text('Open Train'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
  for (final locale in [
    const Locale('en', 'GB'),
    const Locale('de', 'DE'),
    const Locale('de', 'CH')
  ]) {
    testWidgets(
        'Coverage fits narrow ${locale.toLanguageTag()} and larger text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(page(
          WeeklyMuscleCoverage(
              regions: regions(), daily: true, onSelect: (_) {}),
          locale: locale,
          scale: 1.4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'weekly-coverage-${locale.toLanguageTag()}');
      await tester.drag(
          find.byType(SingleChildScrollView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
