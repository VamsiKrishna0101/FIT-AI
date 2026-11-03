// Deterministic marketing captures of production widgets, using fictional data.
// Run: flutter test tool/store_screenshots_capture_test.dart --reporter expanded
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/planner/views/widgets/weekly_plan_schedule.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';
import 'package:setcraft/features/train/views/exercise_detail_screen.dart';
import 'package:setcraft/features/nutrition/views/nutrition_view.dart';
import 'package:setcraft/features/nutrition/models/nutrition_diet_models.dart';
import 'package:setcraft/features/today/views/readiness_detail_view.dart';
import 'package:setcraft/models/home_models.dart';
import 'package:setcraft/features/body_scan/models/body_map_models.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_muscle_map_card.dart';
import '../test/exercise_thumbnail_test.dart' show LocalPosterCache;

const captureKey = ValueKey('store-capture');
final day = DateTime(2026, 11, 3);
String key(DateTime d) => d.toIso8601String().substring(0, 10);

Map<String, dynamic> prescription(String id, String name, int sets, int reps,
        double load, String reason, String progression) =>
    {
      'exerciseId': id, 'name': name, 'sets': sets, 'repsMin': reps,
      'repsMax': reps, 'weightKg': load, 'weightBasis': 'recorded',
      'weightUnit': 'per_hand', 'targetRpe': 7, 'restSeconds': 90,
      'reason': reason, 'progression': progression,
      'setPrescriptions': [for (var i = 1; i <= sets; i++)
        {'setNumber': i, 'repsMin': reps, 'repsMax': reps, 'weightKg': load}],
    };
final exercises = [
  prescription('bench', 'Dumbbell bench press', 3, 10, 18,
      'Keep a familiar chest movement that fits your gym equipment.',
      'You completed 3 × 10 at 18 kg. Keep this load and aim for 11 controlled reps.'),
  prescription('row', 'Dumbbell bent-over row', 3, 10, 20,
      'Balance your pressing work with a familiar pulling movement.',
      'Keep your reps controlled before adding load.'),
  prescription('shoulder', 'Dumbbell shoulder press', 3, 10, 12,
      'Train your shoulders within your available session time.',
      'Keep this load until all working sets feel manageable.'),
  prescription('curl', 'Dumbbell curl', 2, 12, 10,
      'Finish with direct arm work for your selected priorities.',
      'Build your reps before increasing the weight.'),
];
final plan = <String, dynamic>{
  'workouts': [for (var i = 0; i < 7; i++)
    {
      'date': key(DateTime(2026, 11, 2 + i)),
      'name': switch (i) {0 || 3 => 'Lower body', 1 || 5 => 'Upper body', _ => 'Rest day'},
      'restDay': ![0, 1, 3, 5].contains(i),
      'estimatedMinutes': [0, 1, 3, 5].contains(i) ? 45 : 0,
      'status': i == 0 ? 'COMPLETED' : 'SCHEDULED',
      'exercises': [0, 1, 3, 5].contains(i) ? exercises : [],
    }],
};

Widget app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark().copyWith(platform: TargetPlatform.iOS,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
  locale: const Locale('en', 'GB'),
  supportedLocales: const [Locale('en', 'GB')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true,
        padding: const EdgeInsets.only(top: 52, bottom: 24),
        viewPadding: const EdgeInsets.only(top: 52, bottom: 24)),
    child: RepaintBoundary(key: captureKey, child: FitnessTheme(child: child!))),
  home: child,
);

Widget page(String title, Widget child) => Scaffold(
  backgroundColor: Colors.black,
  appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 20,
      fontWeight: FontWeight.w600)), backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent),
  body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), child: child),
);

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 600));
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('../store-screenshots/public/screenshots/apple/iphone/en/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

final history = <String, dynamic>{
  'series': [for (var i = 0; i < 8; i++)
    {'date': key(day.subtract(Duration(days: (7 - i) * 7))),
      'load': [14, 14, 15, 15, 16, 16, 18, 18][i], 'reps': 10,
      'volume': [14, 14, 15, 15, 16, 16, 18, 18][i] * 30,
      'estimatedStrength': [14, 14, 15, 15, 16, 16, 18, 18][i] * 4 / 3,
      'bestSet': {'weight': [14, 14, 15, 15, 16, 16, 18, 18][i], 'reps': 10}}],
  'records': {'bestLoad': {'weight': 18, 'reps': 10, 'date': key(day)}},
  'history': [for (var i = 0; i < 3; i++)
    {'date': key(day.subtract(Duration(days: i * 7))),
      'entries': [for (var s = 1; s <= 3; s++)
        {'setNumber': s, 'weight': i < 2 ? 18 : 16, 'reps': 10}]}],
};

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'fictional-marketing-account', 'fitai_user_id': 'marketing-demo'});
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'CupertinoSystemText': 'assets/fonts/Inter.ttf',
      'Roboto': 'assets/fonts/Inter.ttf',
      '.SF UI Text': 'assets/fonts/Inter.ttf',
      '.SF UI Display': 'assets/fonts/Inter.ttf',
      '.SF Pro Text': 'assets/fonts/Inter.ttf',
      '.SF Pro Display': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons': 'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  testWidgets('Capture real Setcraft screens with coherent fictional data', (tester) async {
    final cacheDirectory = Directory('build/previews/poster-cache')..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => cacheDirectory.absolute.path);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(440, 956);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(page('Your plan', WeeklyPlanSchedule(
        payload: plan, initialDate: key(day)))));
    await tester.pumpAndSettle();
    await capture(tester, '01-plan');
    await tester.tap(find.text('Dumbbell bench press').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Why this fits').first);
    await tester.pumpAndSettle();
    await capture(tester, '03-progression');

    // Use the real local exercise poster through the app's normal image loader.
    const posterUrl = 'https://marketing.invalid/dumbbell-bench-press.jpg';
    final previous = CachedNetworkImageProvider.defaultCacheManager;
    CachedNetworkImageProvider.defaultCacheManager = LocalPosterCache({
      posterUrl: File('test/fixtures/exercise-posters/dumbbell-bench-press.jpg').absolute.path});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory('build/previews/poster-cache').absolute.path);
    addTearDown(() => CachedNetworkImageProvider.defaultCacheManager = previous);
    await tester.pumpWidget(app(const Scaffold(body: SizedBox())));
    await tester.runAsync(() => precacheImage(CachedNetworkImageProvider(posterUrl),
        tester.element(find.byType(SizedBox).first)));
    final exercise = WorkoutExerciseModel.fromJson({
      'id': 'bench', 'name': 'Dumbbell bench press', 'bodyPart': 'chest',
      'target': 'pectorals', 'equipment': 'dumbbells',
      'secondaryMuscles': ['triceps', 'deltoids'], 'thumbnailUrl': posterUrl,
      'mediaAspectRatio': 16 / 9, 'instructions': [
        'Lie back on a flat bench with a dumbbell in each hand.',
        'Press the dumbbells up, then lower with control.',
      ],
    });
    await tester.pumpWidget(app(ExerciseDetailView(exercise: exercise,
        loadDetail: false, female: false,
        historyLoader: ({String? cursor, bool refresh = false}) async => history)));
    await tester.pumpAndSettle();
    await capture(tester, '04-exercise');
    await tester.tap(find.text('Progress').first);
    await tester.pumpAndSettle();
    await capture(tester, '07-progress');

    const yogurt = NutritionFoodItemModel(id: 'yogurt', name: 'Greek yogurt',
        category: 'DAIRY', caloriesPerServing: 120, proteinPerServing: 10,
        carbsPerServing: 12, fatPerServing: 4);
    const chicken = NutritionFoodItemModel(id: 'chicken', name: 'Chicken breast',
        category: 'PROTEIN', caloriesPerServing: 165, proteinPerServing: 31,
        carbsPerServing: 0, fatPerServing: 3.6);
    const rice = NutritionFoodItemModel(id: 'rice', name: 'Brown rice',
        category: 'GRAINS', caloriesPerServing: 123, proteinPerServing: 2.7,
        carbsPerServing: 25.6, fatPerServing: 1);
    const diet = TodayDietPlanModel(caloriesConsumed: 876, caloriesTarget: 2400,
        proteinConsumed: 92.4, proteinTarget: 150, carbsConsumed: 81.2,
        carbsTarget: 280, fatConsumed: 19.2, fatTarget: 75,
        waterConsumed: 1750, waterTarget: 2800, logs: [
      UserMealLogItemModel(id: 'breakfast', mealType: 'BREAKFAST', calories: 300,
          protein: 25, carbs: 30, fat: 10, status: 'LOGGED', servings: 2.5, food: yogurt),
      UserMealLogItemModel(id: 'lunch-protein', mealType: 'LUNCH', calories: 330,
          protein: 62, carbs: 0, fat: 7.2, status: 'LOGGED', servings: 2, food: chicken),
      UserMealLogItemModel(id: 'lunch-rice', mealType: 'LUNCH', calories: 246,
          protein: 5.4, carbs: 51.2, fat: 2, status: 'LOGGED', servings: 2, food: rice),
    ]);
    await tester.pumpWidget(app(NutritionView(initial: diet, date: day,
        plannedMealsLoader: () async => {'settings': {'mode': 'TRACK'}, 'meals': []})));
    await tester.pumpAndSettle();
    await capture(tester, '05-nutrition');

    await tester.pumpWidget(app(ReadinessDetailView(
        date: day, readiness: const HomeReadiness(score: 8.3,
          source: 'check_in_estimate', date: '2026-11-03',
          label: 'Daily check-in estimate', aiTarget: '', sleepMinutes: 450),
        sleepLog: const {'sleepMinutes': 450, 'energy': 4, 'rested': 4, 'soreness': 1})));
    await tester.pumpAndSettle();
    await capture(tester, '06-readiness');

    final map = BodyMapData.fromJson({
      'date': key(day), 'weekStart': '2026-11-02', 'weekEnd': '2026-11-08',
      'gender': 'MALE', 'planId': 'demo-plan', 'summary': {'loggedSets': 24,
        'plannedSets': 44, 'sessions': 2, 'trainedMuscles': 8},
      'regions': [for (final entry in {'chest': 6, 'lats': 6, 'shoulders': 3,
        'biceps': 2, 'triceps': 3, 'quads': 6, 'hamstrings': 4, 'glutes': 4}.entries)
        {'id': entry.key, 'completedSets': entry.value,
         'plannedSets': entry.value * 2, 'status': 'in_progress'}],
      'workouts': [],
    });
    await tester.pumpWidget(app(page('Body', BodyMuscleMapCard(data: map,
        female: false, week: DateTime(2026, 11, 2),
        selection: BodyDateSelection.thisWeek(day), onWeekChanged: (_) {},
        onExercise: (_) {}, onPreparePlan: () {}, onRetry: () {}, onTrain: () {}))));
    await tester.pumpAndSettle();
    await capture(tester, '08-body');
    await tester.pumpWidget(const SizedBox());
  });
}
