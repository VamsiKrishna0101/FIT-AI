import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/network/api_client.dart';
import 'package:fitai_mobile/core/storage/secure_session_store.dart';
import 'package:fitai_mobile/features/train/views/saved_routines_view.dart';
import 'package:fitai_mobile/features/train/views/train_view.dart';
import 'training_session_test.dart' as training;

class RoutineAdapter extends training.Adapter {
  final targets = {
    'weightBasis': 'estimated_start',
    'weightUnit': 'per_hand',
    'sets': [
      {
        'setNumber': 1,
        'repsMin': 10,
        'repsMax': 10,
        'weightKg': 2,
        'targetRpe': 6
      },
      {
        'setNumber': 2,
        'repsMin': 10,
        'repsMax': 10,
        'weightKg': 3,
        'targetRpe': 6
      },
      {
        'setNumber': 3,
        'repsMin': 10,
        'repsMax': 10,
        'weightKg': 3,
        'targetRpe': 6
      },
    ],
  };
  final writes = <Map>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    final uri = Uri.parse(options.path);
    if (!uri.path.contains('/training') || uri.path.contains('/previous')) {
      return super.fetch(options, stream, cancel);
    }
    final date = uri.queryParameters['date'] ?? '2026-10-13';
    final day = training.fixture(date)..['session'] = null;
    day['routines'] = List.generate(
        5,
        (index) => {
              'id': 'routine-$index',
              'name': 'Saved workout $index',
              'count': 1
            });
    dynamic data = day;
    if (options.method == 'GET' && uri.path.contains('/routines/')) {
      data = {
        'id': 'routine-0',
        'name': 'Saved workout 0',
        'items': [
          {...(day['items'] as List).first as Map, 'setTargets': targets},
        ]
      };
    } else if (options.method != 'GET') {
      writes.add(
          {'path': uri.path, 'method': options.method, 'data': options.data});
    }
    return ResponseBody.fromString(jsonEncode({'data': data}), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }
}

void main() {
  late RoutineAdapter adapter;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: training.token('routine-ui-test'), refreshToken: 'test');
    adapter = RoutineAdapter();
    final client = ApiClient.shared.client;
    final original = client.httpClientAdapter;
    client.httpClientAdapter = adapter;
    addTearDown(() => client.httpClientAdapter = original);
  });
  testWidgets(
      'Train shows three routines; View all opens previews and preserves targets when renamed',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(training.app(const TrainView(initialDate: '2026-10-13')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('View all'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Saved workout 0'), findsOneWidget);
    expect(find.text('Saved workout 3'), findsNothing);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedRoutinesView), findsOneWidget);
    expect(find.text('Saved workout 4'), findsOneWidget);
    await tester.tap(find.text('Saved workout 0'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailView), findsOneWidget);
    expect(find.text('Set 2: 10 reps · 3 kg · Per hand'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Renamed routine');
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(adapter.writes.length, 1);
    final data = adapter.writes.single['data'] as Map;
    expect(data['name'], 'Renamed routine');
    expect((data['items'] as List).first['setTargets'], adapter.targets);
    await tester.tap(find.text('Use routine'));
    await tester.pumpAndSettle();
    expect(find.text('Replace this workout?'), findsOneWidget);
    expect(adapter.writes.length, 1,
        reason: 'Preview and confirmation must precede replacing a workout');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(adapter.writes.length, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
