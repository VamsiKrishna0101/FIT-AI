import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/body_scan/models/training_map_models.dart';
import 'package:setcraft/features/body_scan/views/body_training_view.dart';
import 'package:setcraft/features/body_scan/views/widgets/anatomical_training_map.dart';
import 'package:setcraft/features/onboarding/views/training_preferences_view.dart';
import 'package:setcraft/features/onboarding/views/onboarding_view.dart';
import 'package:setcraft/features/onboarding/views/goal_selection_view.dart';
import 'package:setcraft/features/onboarding/views/about_you_experience_view.dart';
import 'package:setcraft/features/onboarding/views/schedule_location_view.dart';
import 'package:setcraft/features/onboarding/views/equipment_selection_view.dart';
import 'package:setcraft/features/onboarding/views/lifestyle_nutrition_limitations_view.dart';
import 'package:setcraft/features/auth/views/auth_view.dart';

final _data = TrainingMapData.fromJson(
    jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
        as Map<String, dynamic>);
const _preview = ValueKey('training-preview');

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
    home: Builder(
        builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
                key: _preview,
                child: FitnessTheme(
                    child: Scaffold(body: SafeArea(child: child)))))));

TrainingMapDashboard _dashboard(
        {Future<void> Function(String, int)? checkIn, TrainingMapData? data}) =>
    TrainingMapDashboard(
        data: data ?? _data,
        onRefresh: () async {},
        onCheckIn: checkIn ?? (_, __) async {},
        onTrain: () {},
        onPreferences: () {},
        onProfile: () {});

Future<void> _size(WidgetTester tester, [double width = 393]) async {
  tester.view.physicalSize = Size(width, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _snapshot(WidgetTester tester, String name,
    {Key capture = _preview}) async {
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build').createSync(recursive: true);
    File('build/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Offset _interior(Path path) {
  final bounds = path.getBounds();
  for (var y = 1; y < 20; y++) {
    for (var x = 1; x < 20; x++) {
      final point = Offset(bounds.left + bounds.width * x / 20,
          bounds.top + bounds.height * y / 20);
      if (path.contains(point)) return point;
    }
  }
  throw StateError('No selectable interior');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('anatomical hit regions match painted paths, including the back', () {
    final front = musclePaths(back: false),
        back = musclePaths(back: true, female: true);
    expect(front['chest']!.first.contains(_interior(front['chest']!.first)),
        isTrue);
    expect(
        front['chest']!.last.contains(_interior(front['chest']!.last)), isTrue);
    expect(
        front['chest']!.any((p) => p.contains(const Offset(30, 180))), isFalse);
    expect(back['glutes']!.first.contains(_interior(back['glutes']!.first)),
        isTrue);
    expect(
        back.keys,
        containsAll(
            ['upper_back', 'lats', 'lower_back', 'triceps', 'hamstrings']));
  });
  test('new personalization fields survive draft and API round trips', () {
    final draft = OnboardingDraft(
        trainingDays: ['MONDAY', 'THURSDAY'],
        focusMuscles: ['chest', 'quads'],
        preferredTime: 'EVENING',
        foodAllergies: ['peanuts'],
        dislikedFoods: ['mushrooms'],
        customLimitations: 'Avoid movements my clinician advised against',
        customWeeklyFoodBudget: 120,
        foodBudgetCurrency: 'EUR');
    final restored = OnboardingDraft.fromJson(draft.toJson());
    expect(restored.personalizationPayload(), draft.personalizationPayload());
    expect(restored.foodAllergies, ['peanuts']);
    expect(restored.focusMuscles, ['chest', 'quads']);
  });
  testWidgets('phone layout, fixed header and front/back controls',
      (tester) async {
    await _size(tester);
    await tester.pumpWidget(_app(_dashboard()));
    await tester.pump();
    expect(find.text('Your body'), findsOneWidget);
    expect(find.text('Logged sets'), findsOneWidget);
    await _snapshot(tester, 'body-2d-preview');
    expect(find.text('Target met'), findsNothing);
    final trainingMap = tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
    expect(trainingMap.colors['chest'], const Color(0xFFE5B85E));
    expect(trainingMap.colors['quads'], const Color(0xFF606060),
        reason:
            'A plan without eligible performance does not earn a strength level');
    expect(find.text('Plan'), findsNothing);
    expect(find.text('Check-in'), findsNothing);
    expect(find.text('Not ranked yet'), findsOneWidget);
    expect(find.text('Strength map'), findsOneWidget);
    expect(find.text('1–3 sets'), findsNothing);
    await tester.tap(find.text('Back').hitTestable());
    await tester.pump();
    expect(
        tester
            .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
            .back,
        isTrue);
    await _snapshot(tester, 'body-2d-back-preview');
    final header =
        tester.getTopLeft(find.byKey(const ValueKey('body-fixed-header')));
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('body-fixed-header'))),
        header);
    expect(tester.takeException(), isNull);
  });
  for (final gender in ['MALE', 'FEMALE']) {
    testWidgets(
        '$gender first-session estimates keep the strength colour bands',
        (tester) async {
      await _size(tester);
      final json =
          jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
              as Map<String, dynamic>;
      json['gender'] = gender;
      for (final region in json['regions'] as List) {
        if (region['id'] == 'biceps') region['completedSets'] = 1;
        region['strength'] = {
          'tier': region['id'] == 'chest'
              ? 1
              : region['id'] == 'biceps'
                  ? 5
                  : 0,
          'title': region['id'] == 'chest'
              ? 'Beginner'
              : region['id'] == 'biceps'
                  ? 'Elite'
                  : 'Not ranked yet',
          'provisional': region['id'] == 'chest',
          'exercises': [],
        };
      }
      await tester
          .pumpWidget(_app(_dashboard(data: TrainingMapData.fromJson(json))));
      await tester.pump();
      final map = tester
          .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap));
      expect(map.female, gender == 'FEMALE');
      expect(map.colors['chest'], const Color(0xFFD89A72));
      expect(map.colors['biceps'], const Color(0xFFAC8BEA));
      expect(map.colors['quads'], const Color(0xFF606060));
      expect(find.text('Strength map'), findsOneWidget);
      expect(find.byKey(const ValueKey('body-strength-provisional')),
          findsOneWidget);
      expect(find.text('Elite'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('muscle tapping opens real details and saves a soreness check-in',
      (tester) async {
    await _size(tester);
    String? muscle;
    int? soreness;
    final current =
        jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
            as Map<String, dynamic>;
    final now = DateTime.now();
    current['date'] = DateTime(now.year, now.month, now.day)
        .toIso8601String()
        .substring(0, 10);
    const capture = ValueKey('muscle-sheet-preview');
    await tester.pumpWidget(RepaintBoundary(
        key: capture,
        child: _app(_dashboard(
            data: TrainingMapData.fromJson(current),
            checkIn: (id, value) async {
              muscle = id;
              soreness = value;
            }))));
    await tester.pump();
    final rect = tester.getRect(find.byType(AnatomicalTrainingMap));
    final point = _interior(musclePaths(back: false)['chest']!.first);
    await tester.tapAt(Offset(rect.left + rect.width * point.dx / 220,
        rect.top + rect.height * point.dy / 440));
    await tester.pumpAndSettle();
    expect(find.text('Chest'), findsWidgets);
    expect(find.text('Direct sets'), findsOneWidget);
    expect(find.text('6 of 10 direct sets · weekly plan'), findsOneWidget);
    expect(find.text('Novice'), findsWidgets);
    expect(
        find.text(
            'Based on the lower median of supported exercise levels, not an isolated muscle test.'),
        findsNothing);
    expect(find.text('Workout history'), findsOneWidget);
    expect(find.text('Open Train'), findsWidgets);
    await tester.tap(find.text('Sore'));
    await tester.pumpAndSettle();
    expect(muscle, 'chest');
    expect(soreness, 2);
    await _snapshot(tester, 'body-muscle-detail-preview', capture: capture);
    await tester.tap(find.byKey(const ValueKey('muscle-strength-chest')));
    await tester.pumpAndSettle();
    expect(find.text('Barbell Bench Press'), findsWidgets);
    final history = find.byKey(const ValueKey('muscle-history-chest'));
    await tester.scrollUntilVisible(history, 140,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('muscle-detail-scroll')),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(history);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load trend'), 120,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('muscle-detail-scroll')),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('Load trend'), findsOneWidget);
    Navigator.of(
            tester.element(find.byKey(const ValueKey('muscle-detail-sheet'))))
        .pop();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
            .colors['chest'],
        isNot(const Color(0xFF606060)),
        reason: 'Reported soreness does not recolour the logged-volume map');
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact phones and larger text remain usable', (tester) async {
    await _size(tester, 320);
    const capture = ValueKey('large-muscle-sheet-preview');
    await tester.pumpWidget(
        RepaintBoundary(key: capture, child: _app(_dashboard(), scale: 1.3)));
    await tester.pump();
    expect(find.text('Strength map'), findsOneWidget);
    expect(find.text('Plan'), findsNothing);
    expect(find.text('Check-in'), findsNothing);
    expect(
        tester
            .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
            .colors['quads'],
        const Color(0xFF606060),
        reason: 'Planned sets and soreness do not replace logged volume');
    tester
        .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
        .onSelected('chest');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('muscle-detail-sheet')), findsOneWidget);
    final action = find.descendant(
        of: find.byKey(const ValueKey('muscle-detail-sheet')),
        matching: find.text('Open Train'));
    expect(tester.getBottomRight(action).dy,
        lessThan(tester.view.physicalSize.height));
    await _snapshot(tester, 'body-muscle-detail-large-text-preview',
        capture: capture);
    expect(tester.takeException(), isNull);
  });
  testWidgets('final onboarding step saves priorities without a scan',
      (tester) async {
    await _size(tester);
    await OnboardingDraft(
        focusMuscles: ['chest'],
        preferredTime: 'MORNING',
        foodAllergies: ['peanuts'],
        limitations: ['KNEE']).save();
    var continued = false;
    final controller = OnboardingController();
    await controller.initialize();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(TrainingPreferencesView(
        controller: controller, onContinue: () => continued = true)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Quads'));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'onboarding-preferences-preview');
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 100));
    await controller.flush();
    final stored = await OnboardingDraft.load();
    expect(stored.focusMuscles, ['chest', 'quads']);
    expect(stored.foodAllergies, ['peanuts']);
    expect(stored.limitations, ['KNEE']);
    expect(stored.completedStep, 7);
    expect(continued, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'all onboarding steps fit small phones, enlarged text and the keyboard',
      (tester) async {
    await _size(tester, 320);
    tester.view.physicalSize = const Size(320, 640);
    await OnboardingDraft(
            name: 'Vikram', heightCm: 178, weightKg: 82, targetWeightKg: 76)
        .save();
    final pages = <String, Widget>{
      'language': const OnboardingView(),
      'goal': const GoalSelectionView(),
      'about': const AboutYouExperienceView(),
      'schedule': const ScheduleLocationView(),
      'equipment': const EquipmentSelectionView(),
      'lifestyle': const LifestyleNutritionLimitationsView(),
      'preferences': const TrainingPreferencesView(),
      'account': const AuthView(),
    };
    for (final entry in pages.entries) {
      await tester.pumpWidget(_app(entry.value, scale: 1.3));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: entry.key);
      final scroll = find.byKey(const ValueKey('onboarding-scroll'));
      await tester.drag(scroll, const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${entry.key} scrolled');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '${entry.key} keyboard');
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'language names omit flags and onboarding previews use the shared theme',
      (tester) async {
    await _size(tester);
    for (final entry in <String, Widget>{
      'language': const OnboardingView(),
      'about': const AboutYouExperienceView(),
      'schedule': const ScheduleLocationView(),
      'lifestyle': const LifestyleNutritionLimitationsView(),
      'account': const AuthView()
    }.entries) {
      await tester.pumpWidget(_app(entry.value));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      if (entry.key == 'language') {
        expect(find.text('English'), findsOneWidget);
        expect(find.textContaining('🇬🇧'), findsNothing);
      }
      await _snapshot(tester, 'onboarding-${entry.key}-preview');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
