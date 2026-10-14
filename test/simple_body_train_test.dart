import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/cache/cache_scope.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/body_scan/models/body_assessment_models.dart';
import 'package:fitai_mobile/features/body_scan/models/body_progress_summary.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/body_progress_cards.dart';
import 'package:fitai_mobile/features/train/components/workout_set_entry.dart';
import 'package:fitai_mobile/features/train/repositories/training_repository.dart';
import 'package:fitai_mobile/features/train/repositories/workout_offline_store.dart';
import 'training_session_test.dart' as training;

class OfflineAdapter extends training.Adapter {
  bool offline = false;
  int? reject;
  final writes = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (options.method != 'GET') {
      writes.add('${options.method} ${Uri.parse(options.path).path}');
      if (offline) {
        throw DioException(
            requestOptions: options, type: DioExceptionType.connectionError);
      }
      if (reject != null) {
        return ResponseBody.fromString('{"error":"Rejected"}', reject!,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            });
      }
    }
    return super.fetch(options, stream, cancel);
  }
}

Map<String, dynamic> entry(String date, Map<String, dynamic> metrics) => {
      'id': date,
      'recordedDate': date,
      'createdAt': '${date}T12:00:00Z',
      'status': 'SAVED',
      'method': 'entered',
      'metrics': metrics,
      'updatedAt': date,
    };
Map<String, dynamic> metric(double value, [String source = 'tape']) =>
    {'value': value, 'source': source};

void main() {
  var account = 0;
  late String owner;
  late OfflineAdapter adapter;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    owner = 'simple-body-train-${account++}';
    await SecureSessionStore.shared
        .saveTokens(accessToken: training.token(owner), refreshToken: 'test');
    adapter = OfflineAdapter();
    final client = ApiClient.shared.client;
    final original = client.httpClientAdapter;
    client.httpClientAdapter = adapter;
    addTearDown(() => client.httpClientAdapter = original);
  });

  test(
      'Body changes exclude estimates and compare the same source across dates',
      () {
    final summary = BodyProgressSummary(BodyOverview.fromJson({
      'records': [
        entry('2026-10-13', {
          'weightKg': metric(80, 'profile'),
          'waistCm': metric(84, 'photo_estimate')
        }),
        entry('2026-10-12',
            {'weightKg': metric(75, 'scale'), 'waistCm': metric(83)}),
        entry('2026-10-11',
            {'weightKg': metric(78, 'smart_scale'), 'waistCm': metric(84)}),
        entry('2026-10-10', {'weightKg': metric(76, 'scale')}),
        entry('2026-10-14', {'waistCm': metric(10, 'preview')}),
      ]
    }));
    expect(summary.changes.map((change) => change.current.key),
        ['weightKg', 'waistCm']);
    expect(summary.changes.map((change) => change.delta), [-1, -1]);
    expect(summary.changes.first.previous.date, '2026-10-10');
  });

  test(
      'Left/right pairs require both measurements in the same entry and source',
      () {
    final summary = BodyProgressSummary(BodyOverview.fromJson({
      'records': [
        entry('2026-10-13', {
          'leftArmCm': metric(35),
          'rightArmCm': metric(36, 'photo_estimate')
        }),
        entry('2026-10-12', {'leftArmCm': metric(34)}),
        entry('2026-10-11', {'rightArmCm': metric(35)}),
        entry(
            '2026-10-10', {'leftArmCm': metric(33), 'rightArmCm': metric(34)}),
      ]
    }));
    expect(summary.pairs.length, 1);
    expect(summary.pairs.single.entry.recordedDate, '2026-10-10');
    expect(summary.pairs.single.difference, 1);
  });

  testWidgets('Suggestions need confirmation; previous sets match by number',
      (tester) async {
    final key = GlobalKey<WorkoutSetEntryState>();
    var saves = 0;
    await tester.pumpWidget(training.app(Scaffold(
        body: WorkoutSetEntry(
      key: key,
      date: '2026-10-13',
      itemId: 'item',
      number: 1,
      suggestedReps: 10,
      suggestedWeight: 2.5,
      previous: Future.value({
        'sets': [
          {'setNumber': 2, 'reps': 12, 'weight': 9},
          {'setNumber': 1, 'reps': 10, 'weight': 2},
        ]
      }),
      disabled: false,
      onSave: (reps, weight, effort) async {
        saves++;
        expect(reps, 10);
        expect(weight, 2.5);
      },
      onDelete: () async {},
    ))));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '2.5');
    expect(find.text('Last: 2 kg × 10'), findsOneWidget);
    expect(key.currentState!.pendingSet(), isNull);
    await key.currentState!.savePending();
    expect(saves, 0);
    await tester.tap(find.byTooltip('Save set'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(key.currentState!.pendingSet(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test(
      'Offline workout survives cache clearing and account switches, then syncs in order',
      () async {
    const date = '2026-10-13';
    final repo = TrainingRepository.shared;
    await repo.load(date, refresh: true);
    adapter.offline = true;
    var day = await repo.mutate(date, 'PUT', '/items/item/sets',
        data: {'setNumber': 1, 'reps': 10, 'weight': 20.0, 'rpe': null});
    expect(day.pendingSync, true);
    expect(day.loggedSets, 1);
    day = await repo
        .mutate(date, 'POST', '/items/item/complete', data: {'sets': []});
    day = await repo.mutate(date, 'POST', '/finish');
    expect(day.finished, true);
    expect(day.volume, 200);
    await CacheScope.clearAllUserData();
    final store = WorkoutOfflineStore();
    expect((await store.read(owner))[date]['actions'].length, 3);
    expect((await repo.cached(date))!.pendingSync, true);
    await SecureSessionStore.shared.clear();
    await SecureSessionStore.shared.saveTokens(
        accessToken: training.token('another-account'), refreshToken: 'test');
    final writes = adapter.writes.length;
    await repo.syncPending(retry: true);
    expect(adapter.writes.length, writes);
    expect(await repo.cached(date), isNull);
    await SecureSessionStore.shared
        .saveTokens(accessToken: training.token(owner), refreshToken: 'test');
    adapter.offline = false;
    adapter.writes.clear();
    await repo.syncPending(retry: true);
    expect(adapter.writes, [
      'PUT /api/workout/training/items/item/sets',
      'POST /api/workout/training/items/item/complete',
      'POST /api/workout/training/finish',
    ]);
    expect(await store.read(owner), isEmpty);
    final saved = await repo.cached(date);
    expect(saved!.pendingSync, false);
    expect(saved.finished, true);
    expect(saved.loggedSets, 1);
    expect(saved.volume, 200);
  });

  test(
      'Server rejection is not an offline success; sync conflicts retain pending work',
      () async {
    const date = '2026-10-13';
    final repo = TrainingRepository.shared;
    await repo.load(date, refresh: true);
    adapter.reject = 400;
    await expectLater(
        repo.mutate(date, 'PUT', '/items/item/sets',
            data: {'setNumber': 1, 'reps': 10}),
        throwsA(isA<DioException>()));
    expect(await WorkoutOfflineStore().read(owner), isEmpty);
    expect((await repo.cached(date))!.loggedSets, 0);
    adapter.reject = null;
    adapter.offline = true;
    await repo.mutate(date, 'PUT', '/items/item/sets',
        data: {'setNumber': 1, 'reps': 10, 'weight': 20.0, 'rpe': null});
    adapter.offline = false;
    adapter.reject = 409;
    await expectLater(
        repo.syncPending(retry: true), throwsA(isA<DioException>()));
    expect((await repo.cached(date))!.syncBlocked, true);
    expect(
        (await WorkoutOfflineStore().read(owner))[date]['actions'].length, 1);
  });

  testWidgets('Body cards fit a small phone with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final summary = BodyProgressSummary(BodyOverview.fromJson({
      'records': [
        entry('2026-10-13', {
          'waistCm': metric(83),
          'leftArmCm': metric(34),
          'rightArmCm': metric(34.5)
        }),
        entry('2026-10-06', {'waistCm': metric(84)}),
      ]
    }));
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!),
        home: Scaffold(
            body: ListView(children: [
          BodyChangesCard(
              summary: summary, onMeasurements: () {}, onCompare: () {}),
          BodyBalanceCard(summary: summary, onAdd: () {}),
        ]))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
