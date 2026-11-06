import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/localization/manual_entries_copy.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/body_scan/repositories/body_assessment_repository.dart';
import 'package:setcraft/features/body_scan/views/body_entry_view.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/features/today/views/update_stats_view.dart';
import 'package:setcraft/features/wellness/views/daily_check_in_sheet.dart';
import 'today_date_filter_test.dart' show DateAdapter;

class StatsAdapter extends DateAdapter {
  bool failBody = false;
  final record = <String, dynamic>{
    'id': 'measurement',
    'recordedDate': '2026-11-04',
    'status': 'SAVED',
    'method': 'entered',
    'createdAt': '2026-11-04T08:00:00Z',
    'updatedAt': '2026-11-04T08:00:00Z',
    'metrics': {
      'weightKg': {'value': 77, 'source': 'scale'}
    },
  };
  Map<String, dynamic>? savedSleep;
  ResponseBody response(Object data, [int status = 200]) =>
      ResponseBody.fromString(jsonEncode(data), status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (options.path == '/api/body') {
      requests.add(options);
      return failBody
          ? response({'error': 'Unavailable'}, 503)
          : response({
              'records': [record]
            });
    }
    if (options.path == '/api/body/entries/measurement' &&
        options.method == 'PATCH') {
      requests.add(options);
      record['metrics'] = options.data['metrics'];
      return response(record);
    }
    if (options.path == '/api/wellness/check-in/2026-11-04' &&
        options.method == 'PUT') {
      requests.add(options);
      savedSleep = {
        ...Map<String, dynamic>.from(options.data as Map),
        'date': '2026-11-04',
        'updatedAt': '2026-11-05T06:00:00Z'
      };
      return response({'data': savedSleep});
    }
    final result = await super.fetch(options, stream, cancel);
    if (options.path == '/api/home' && savedSleep != null) {
      final data = jsonDecode(await utf8.decoder.bind(result.stream).join())
          as Map<String, dynamic>;
      data['sleepLog'] = savedSleep;
      return response(data);
    }
    return result;
  }
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Manual entry navigation is translated in every supported non-English locale',
      () {
    for (final locale in [
      'de',
      'de-CH',
      'fr',
      'sv',
      'no',
      'da',
      'nl',
      'es',
      'it'
    ]) {
      for (final label in [
        'Update your stats',
        'Sleep & recovery',
        'Body measurements',
        'Water intake',
        'Progress photos',
        'Take a photo',
        'Read only'
      ]) {
        expect(manualEntriesTranslation(locale, label), isNotNull,
            reason: '$locale: $label');
        expect(manualEntriesTranslation(locale, label), isNot(label),
            reason: '$locale: $label');
      }
    }
  });
  late StatsAdapter adapter;
  var account = 0;
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'userId': 'stats-${account++}'})));
    await SecureSessionStore.shared
        .saveTokens(accessToken: 'e30.$payload.test', refreshToken: 'test');
    adapter = StatsAdapter();
    ApiClient.shared.client.httpClientAdapter = adapter;
    await BodyAssessmentRepository.shared.invalidate();
  });
  Widget page({DateTime? date, double scale = 1}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => RepaintBoundary(
          key: const ValueKey('stats-preview'),
          child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!)),
      home: UpdateStatsView(
          date: date ?? DateTime(2026, 11, 4),
          clock: () => DateTime(2026, 11, 5)));

  testWidgets('Today footer exposes the stats screen action', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: TodayDashboard(
                data: null,
                onRefresh: () async {},
                onProfile: () {},
                onSession: () {},
                onTrain: () {},
                onNutrition: () {},
                onUpdateStats: () => opened = true))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('today-update-stats-button')), 250);
    await tester.tap(find.byKey(const ValueKey('today-update-stats-button')));
    expect(opened, isTrue);
  });
  testWidgets('Today hides the stats button while loading', (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: TodayDashboard(
                data: null,
                loading: true,
                onRefresh: () async {},
                onProfile: () {},
                onSession: () {},
                onTrain: () {},
                onNutrition: () {},
                onUpdateStats: () {}))));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('today-update-stats-button')), findsNothing);
    expect(find.byKey(const ValueKey('today-update-stats-card')), findsNothing);
  });
  testWidgets('Hub fits a phone, shows saved values and stays monochrome',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(page());
    await settle(tester);
    expect(find.text('Update your stats'), findsOneWidget);
    expect(find.textContaining('77 kg'), findsOneWidget);
    expect(find.text('Sleep & recovery'), findsOneWidget);
    expect(find.text('Body measurements'), findsOneWidget);
    expect(find.text('Water intake'), findsOneWidget);
    expect(find.text('Progress photos'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('stats-preview')))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/update-stats.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
  testWidgets('Sleep opens a full page and saves to the selected day API',
      (tester) async {
    await tester.pumpWidget(page());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('update-stats-sleep')));
    await settle(tester);
    expect(
        tester
            .widget<DailyCheckInSheet>(find.byType(DailyCheckInSheet))
            .fullScreen,
        isTrue);
    expect(find.byKey(const ValueKey('daily-check-in-close')), findsNothing);
    await tester.enterText(find.byType(TextField).first, '8');
    await tester.enterText(find.byType(TextField).at(1), '15');
    await tester
        .ensureVisible(find.byKey(const ValueKey('daily-check-in-save')));
    await tester.tap(find.byKey(const ValueKey('daily-check-in-save')));
    await settle(tester);
    expect(adapter.savedSleep?['sleepMinutes'], 495);
    expect(find.text('8h 15m'), findsOneWidget);
  });
  testWidgets('Closing an editor without saving keeps the cached overview',
      (tester) async {
    await tester.pumpWidget(page());
    await settle(tester);
    final reads = adapter.requests.where((r) => r.path == '/api/home').length;
    await tester.tap(find.byKey(const ValueKey('update-stats-sleep')));
    await settle(tester);
    await tester.pageBack();
    await settle(tester);
    expect(
        adapter.requests.where((r) => r.path == '/api/home'), hasLength(reads));
    expect(
        adapter.requests.where((r) =>
            r.path == '/api/home' && r.queryParameters['refresh'] == 'true'),
        isEmpty);
  });
  testWidgets('Measurements edit the selected day without creating a duplicate',
      (tester) async {
    await tester.pumpWidget(page());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('update-stats-measurements')));
    await settle(tester);
    final editor = tester.widget<BodyEntryView>(find.byType(BodyEntryView));
    expect(editor.existing?.id, 'measurement');
    expect(editor.initialDate, DateTime(2026, 11, 4));
    await tester.enterText(
        find.byKey(const ValueKey('body-input-weightKg')), '78');
    await tester.ensureVisible(find.text('Save measurements'));
    await tester.tap(find.text('Save measurements'));
    await settle(tester);
    expect(
        adapter.requests.where((r) =>
            r.method == 'PATCH' && r.path == '/api/body/entries/measurement'),
        hasLength(1));
    expect(adapter.record['metrics']['weightKg']['value'], 78);
  });
  testWidgets('Old sleep entries remain read-only and large text fits',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(page(date: DateTime(2026, 10, 1), scale: 1.8));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('update-stats-sleep')));
    await settle(tester);
    expect(find.byType(DailyCheckInSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
