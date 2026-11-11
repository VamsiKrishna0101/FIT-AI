import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:setcraft/core/network/api_client.dart';
import 'package:setcraft/core/storage/secure_session_store.dart';
import 'package:setcraft/features/train/models/training_session.dart';
import 'package:setcraft/features/train/views/workout_session_view.dart';
import 'training_session_test.dart' as fixture;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureSessionStore.shared.saveTokens(
        accessToken: fixture.token('warmup-gate-test'),
        refreshToken: 'synthetic');
    ApiClient.shared.client.httpClientAdapter = fixture.Adapter();
  });

  Widget app(Widget child) => MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: child,
      );

  testWidgets(
      'Without completing warm-up, sets and other exercises are disabled saying complete warm up first',
      (tester) async {
    final raw = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(fixture.fixture('2026-10-27', sets: 0))) as Map);
    raw['name'] = 'Chest Day';
    raw['warmup'] = {
      'durationMinutes': 5,
      'note': 'Preparation only.',
      'steps': [
        {
          'name': 'Easy Movement & Pulse Raiser',
          'seconds': 60,
          'instruction': 'Walk or cycle gently.',
        },
        {
          'name': 'Dumbbell bench press',
          'exerciseId': 'ex-1',
          'seconds': 90,
          'reps': 8,
          'instruction': 'Practise with very light load.',
        },
        {
          'name': 'Close-grip Push-up (on Knees) & Bench Dips',
          'seconds': 75,
          'reps': 8,
          'instruction': 'Focus on controlled tempo and core engagement.',
        },
      ]
    };

    final day = TrainingDay(raw);
    await tester.pumpWidget(app(WorkoutSessionView(initial: day)));
    await tester.pumpAndSettle();

    // 1. Verify Warm-up header is visible
    expect(find.text('Warm-up'), findsOneWidget);

    // 2. Verify the primary footer button says "Complete warm-up"
    final footerButton = find.widgetWithText(FilledButton, 'Complete warm-up');
    expect(footerButton, findsOneWidget);

    // 3. Scroll to sets section and verify lock banner "Complete warm-up first" is displayed
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Complete warm-up first'), findsOneWidget);

    // 4. Tap the "Complete warm-up" button
    await tester.tap(footerButton);
    await tester.pumpAndSettle();

    // 5. Once warm-up is completed:
    // - Lock banner disappears
    expect(find.text('Complete warm-up first'), findsNothing);
    // - "Completed" indicator appears
    expect(find.text('Completed'), findsOneWidget);
    // - Primary action button becomes ready for logging working set
    expect(find.text('Log set 1'), findsOneWidget);
  });
}
