import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitai_mobile/core/health/phone_sleep_service.dart';
import 'package:fitai_mobile/features/wellness/repositories/wellness_repository.dart';
import 'package:fitai_mobile/features/wellness/views/sleep_entry_view.dart';
import 'package:fitai_mobile/features/today/components/today_dashboard.dart';
import 'package:fitai_mobile/models/home_models.dart';

class _Repo extends WellnessRepository {
  String usage;
  _Repo(this.usage);
  Map<String, dynamic>? saved;
  @override
  Future<String> wearableUsage() async => usage;
  @override
  Future<void> setWearableUsage(String value) async {
    usage = value;
  }

  @override
  Future<Map<String, dynamic>?> load(String date) async => null;
  @override
  Future<void> save(String date, int minutes, int? energy,
      {int? rested, int? soreness, PhoneSleepEstimate? estimate}) async {
    saved = {
      'date': date,
      'minutes': minutes,
      'rested': rested,
      'soreness': soreness,
      'estimate': estimate
    };
  }
}

class _Phone extends PhoneSleepService {
  final bool android;
  _Phone({this.android = true});
  int starts = 0, stops = 0;
  bool tracking = false;
  PhoneSleepEstimate? suggested;
  @override
  bool get supported => android;
  @override
  Future<bool> enabled() async => tracking;
  @override
  Future<bool> start() async {
    starts++;
    return tracking = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    tracking = false;
  }

  @override
  Future<PhoneSleepEstimate?> estimate(String date) async => suggested;
}

class _FailingRepo extends _Repo {
  _FailingRepo() : super('NONE');

  @override
  Future<void> save(String date, int minutes, int? energy,
      {int? rested, int? soreness, PhoneSleepEstimate? estimate}) async {
    final request = RequestOptions(path: '/api/wellness/check-in/$date');
    throw DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 400, data: {
          'error': 'Confirm your wearable preference before saving.'
        }));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => initializeDateFormatting());
  setUp(() => FlutterSecureStorage.setMockInitialValues(
      {'fitai_access_token': 'opaque', 'fitai_user_id': 'phone-test-owner'}));
  Future<void> open(WidgetTester tester, _Repo repo, _Phone phone,
      {double scale = 1}) async {
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
            data: MediaQueryData(
                size: const Size(390, 844),
                textScaler: TextScaler.linear(scale)),
            child: SleepEntryView(
                initialDate: DateTime(2026, 10, 11),
                repository: repo,
                phoneSleep: phone))));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final usage in ['UNKNOWN', 'WEARABLE']) {
    testWidgets(
        '$usage does not enable fallback just because readings are missing',
        (tester) async {
      final repo = _Repo(usage), phone = _Phone();
      await open(tester, repo, phone);
      expect(find.text('Estimate my sleep'), findsNothing);
      expect(find.text('How rested do you feel?'), findsNothing);
      expect(find.text('How sore are you?'), findsNothing);
      expect(phone.starts, 0);
    });
  }
  testWidgets(
      'No wearable is an explicit choice; tracking remains opt-in and stops on wearable selection',
      (tester) async {
    final repo = _Repo('UNKNOWN'), phone = _Phone();
    await open(tester, repo, phone);
    await tap(tester, find.text('I don’t use a wearable'));
    expect(repo.usage, 'NONE');
    expect(find.text('Estimate my sleep'), findsOneWidget);
    expect(phone.starts, 0);
    await tap(tester, find.byType(Switch));
    expect(phone.starts, 1);
    await tap(tester, find.text('I use a wearable'));
    expect(repo.usage, 'WEARABLE');
    expect(phone.stops, 1);
    expect(find.text('Estimate my sleep'), findsNothing);
    expect(find.text('How sore are you?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'iPhone check-in uses manual entry without Android tracking controls',
      (tester) async {
    final repo = _Repo('NONE'), phone = _Phone(android: false);
    await open(tester, repo, phone);
    expect(find.text('How rested do you feel?'), findsOneWidget);
    expect(find.text('How sore are you?'), findsOneWidget);
    expect(find.text('Set bedtime'), findsOneWidget);
    expect(find.text('Estimate my sleep'), findsNothing);
    expect(phone.starts, 0);
  });
  testWidgets(
      'A suggested estimate is not saved until confirmed; edits remove estimate provenance',
      (tester) async {
    final repo = _Repo('NONE'), phone = _Phone();
    phone.suggested = PhoneSleepEstimate(
        DateTime(2026, 10, 10, 23), DateTime(2026, 10, 11, 7));
    await open(tester, repo, phone);
    expect(repo.saved, isNull);
    await tap(tester, find.text('Confirm estimated sleep'));
    expect(find.text('Phone estimate · confirmed'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '7');
    await tester.pumpAndSettle();
    expect(find.text('Phone estimate · confirmed'), findsNothing);
    await tap(tester, find.text('Save check-in'));
    expect(repo.saved?['minutes'], 420);
    expect(repo.saved?['estimate'], isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Check-in remains scrollable at large text size without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester, _Repo('NONE'), _Phone(), scale: 1.8);
    await tester.ensureVisible(find.text('Save check-in'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test('Malformed phone estimates are discarded', () {
    expect(PhoneSleepEstimate.parse({'start': 12, 'end': 10}), isNull);
    expect(PhoneSleepEstimate.parse({'start': 0, 'end': 86400001}), isNull);
    expect(PhoneSleepEstimate.parse({'start': 'bad', 'end': 10}), isNull);
    expect(PhoneSleepEstimate.parse({'start': double.nan, 'end': 10}), isNull);
  });
  testWidgets('Save shows validation immediately when sleep was not entered',
      (tester) async {
    final repo = _Repo('NONE');
    await open(tester, repo, _Phone());
    await tester.tap(find.text('Save check-in'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(repo.saved, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Blank minutes save as zero and the button stays reachable',
      (tester) async {
    final repo = _Repo('NONE');
    await open(tester, repo, _Phone());
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '7');
    await tester.enterText(find.byType(TextField).last, '');
    await tester.tap(find.text('Save check-in'));
    await tester.pumpAndSettle();
    expect(repo.saved?['minutes'], 420);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'A failed save shows the server reason and keeps the entered sleep',
      (tester) async {
    await open(tester, _FailingRepo(), _Phone());
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '8');
    await tester.tap(find.text('Save check-in'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Confirm your wearable preference before saving.'),
        findsWidgets);
    expect(find.text('8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'No-wearable Home opens the check-in without asking for missing heart readings',
      (tester) async {
    var opened = 0;
    final data = HomeData.fromJson({
      'wearableUsage': 'NONE',
      'calendarDate': '2026-10-11',
      'user': <String, dynamic>{},
      'nutrition': <String, dynamic>{},
      'weeklyStreak': <dynamic>[]
    });
    expect(HomeData.fromJson(data.toJson()).wearableUsage, 'NONE');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TodayDashboard(
                data: data,
                now: DateTime(2026, 10, 11),
                onRefresh: () async {},
                onProfile: () {},
                onSession: () {},
                onTrain: () {},
                onNutrition: () {},
                onBody: () {},
                onSleep: () => opened++))));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('today-readiness-card')));
    expect(opened, 1);
    expect(find.text('Resting heart rate or HRV'), findsNothing);
    expect(find.text('Daily check-in estimate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
