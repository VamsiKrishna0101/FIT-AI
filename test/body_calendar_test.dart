import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/features/body_scan/models/body_map_models.dart';
import 'package:setcraft/features/body_scan/views/body_view.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_calendar.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_muscle_map_card.dart';
import 'body_measurement_dashboard_test.dart' as fixtures;

final today = DateTime(2026, 11, 2);
const captureKey = ValueKey('body-calendar-capture');

Widget app(Widget home, {double scale = 1, String locale = 'en'}) =>
    MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: captureKey, child: child!)),
        home: home);

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String key, String value,
    {double delta = 120}) async {
  await tap(tester, find.byKey(ValueKey(key)));
  final option = find.text(value);
  await tester.scrollUntilVisible(option, delta,
      scrollable: find.byType(Scrollable).last, maxScrolls: 40);
  await tap(tester, option);
}

Future<void> capture(WidgetTester tester, String name) =>
    tester.runAsync(() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/previews').create(recursive: true);
      await File('build/previews/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

Widget picker({
  required ValueChanged<BodyDateSelection?> onResult,
  bool planned = false,
  BodyDateSelection? selection,
  double scale = 1,
  String locale = 'en',
}) =>
    app(Scaffold(body: Builder(builder: (context) {
      return Center(
          child: TextButton(
              onPressed: () async => onResult(
                  await showModalBottomSheet<BodyDateSelection>(
                      context: context,
                      isScrollControlled: true,
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .9),
                      builder: (_) => BodyCalendar(
                          today: today,
                          planned: planned,
                          selection:
                              selection ?? BodyDateSelection.thisWeek(today)))),
              child: const Text('Open calendar')));
    })), scale: scale, locale: locale);

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'test', 'fitai_user_id': 'body-calendar-test'});
  });

  testWidgets('Planned jumps to a previous month and year and applies its week',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    BodyDateSelection? result;
    await tester.pumpWidget(picker(planned: true, onResult: (s) => result = s));
    await tap(tester, find.text('Open calendar'));
    expect(find.text('Previous'), findsNothing);
    expect(find.text('This week'), findsNothing);
    expect(find.text('Next'), findsNothing);
    expect(find.textContaining('Sleep'), findsNothing);
    await choose(tester, 'body-calendar-year-picker', '2024');
    await choose(tester, 'body-calendar-month-picker', 'December', delta: 120);
    expect(result, isNull, reason: 'Browsing never applies the filter');
    await tap(tester, find.byKey(const ValueKey('body-calendar-2024-12-31')));
    await capture(tester, 'body-calendar-planned-month-year');
    await tap(tester, find.byKey(const ValueKey('body-calendar-apply')));
    expect(result!.start, DateTime(2024, 12, 30));
    expect(result!.end, DateTime(2025, 1, 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trained applies an exact range across months and years',
      (tester) async {
    BodyDateSelection? result;
    await tester.pumpWidget(picker(onResult: (s) => result = s));
    await tap(tester, find.text('Open calendar'));
    await tap(tester, find.text('Date range'));
    await choose(tester, 'body-calendar-year-picker', '2024');
    await choose(tester, 'body-calendar-month-picker', 'December');
    await tap(tester, find.byKey(const ValueKey('body-calendar-2024-12-29')));
    await choose(tester, 'body-calendar-year-picker', '2025', delta: -120);
    await choose(tester, 'body-calendar-month-picker', 'January', delta: -120);
    await tap(tester, find.byKey(const ValueKey('body-calendar-2025-01-04')));
    await tap(tester, find.byKey(const ValueKey('body-calendar-apply')));
    expect(result!.start, DateTime(2024, 12, 29));
    expect(result!.end, DateTime(2025, 1, 4));
    expect(result!.query, {'from': '2024-12-29'});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Trained keeps selected dates when browsing and blocks the future',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    BodyDateSelection? result;
    await tester.pumpWidget(picker(onResult: (s) => result = s));
    await tap(tester, find.text('Open calendar'));
    await tap(tester, find.text('Multiple days'));
    await choose(tester, 'body-calendar-year-picker', '2025');
    await choose(tester, 'body-calendar-month-picker', 'December');
    await tap(tester, find.byKey(const ValueKey('body-calendar-2025-12-10')));
    await choose(tester, 'body-calendar-year-picker', '2026', delta: -120);
    final month = tester.widget<DropdownButton<int>>(
        find.byKey(const ValueKey('body-calendar-month-picker')));
    expect(month.value, 11,
        reason: 'Returning to this year clamps a future month to this month');
    expect(
        month.items!.singleWhere((item) => item.value == 12).enabled, isFalse);
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('body-calendar-2026-11-03')))
            .onPressed,
        isNull);
    await tap(tester, find.byKey(const ValueKey('body-calendar-2026-11-02')));
    expect(find.byKey(const ValueKey('body-calendar-apply')).hitTestable(),
        findsOneWidget);
    await capture(tester, 'body-calendar-trained-month-year');
    await tap(tester, find.byKey(const ValueKey('body-calendar-apply')));
    expect(result!.dates, [DateTime(2025, 12, 10), today]);
    expect(result!.query, {'dates': '2025-12-10,2026-11-02'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Planned and Trained keep independent applied date filters',
      (tester) async {
    final repo = fixtures.Repository();
    await tester.pumpWidget(app(BodyView(onTrain: () {}, repository: repo)));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('body-map-plan')));
    await tap(tester, find.byKey(const ValueKey('body-calendar-button')));
    await choose(tester, 'body-calendar-year-picker', '2024');
    await choose(tester, 'body-calendar-month-picker', 'December');
    await tap(tester, find.byKey(const ValueKey('body-calendar-2024-12-31')));
    await tap(tester, find.byKey(const ValueKey('body-calendar-apply')));
    var card = tester.widget<BodyMuscleMapCard>(find.byType(BodyMuscleMapCard));
    expect(card.week, DateTime(2024, 12, 30));
    expect(repo.weeks, contains(DateTime(2024, 12, 30)));
    final plannedCall = repo.weeks.indexOf(DateTime(2024, 12, 30));
    expect(repo.selections[plannedCall], isNull);
    await tap(tester, find.byKey(const ValueKey('body-map-trained')));
    await tap(tester, find.byKey(const ValueKey('body-calendar-button')));
    await tap(tester, find.text('Single day'));
    await choose(tester, 'body-calendar-year-picker', '2025');
    await choose(tester, 'body-calendar-month-picker', 'January', delta: -120);
    await tap(tester, find.byKey(const ValueKey('body-calendar-2025-01-04')));
    await tap(tester, find.byKey(const ValueKey('body-calendar-apply')));
    card = tester.widget<BodyMuscleMapCard>(find.byType(BodyMuscleMapCard));
    expect(card.selection!.query, {'dates': '2025-01-04'});
    expect(repo.selections.whereType<BodyDateSelection>().last.query,
        {'dates': '2025-01-04'});
    await tap(tester, find.byKey(const ValueKey('body-map-plan')));
    card = tester.widget<BodyMuscleMapCard>(find.byType(BodyMuscleMapCard));
    expect(card.week, DateTime(2024, 12, 30));
    expect(card.selection!.end, DateTime(2025, 1, 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Month and year pickers fit a narrow phone with large German text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final planned in [true, false]) {
      await tester.pumpWidget(
          picker(planned: planned, scale: 2, locale: 'de', onResult: (_) {}));
      await tap(tester, find.text('Open calendar'));
      expect(find.text('Monat'), findsOneWidget);
      expect(find.text('Jahr'), findsOneWidget);
      expect(find.byKey(const ValueKey('body-calendar-apply')).hitTestable(),
          findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('body-calendar-apply')));
      expect(tester.takeException(), isNull);
    }
  });
}
