import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';
import 'package:fitai_mobile/core/theme/fitness_theme.dart';
import 'package:fitai_mobile/features/body_scan/models/training_map_models.dart';
import 'package:fitai_mobile/features/body_scan/views/body_training_view.dart';
import 'package:fitai_mobile/features/body_scan/views/widgets/anatomical_training_map.dart';
import 'package:fitai_mobile/features/onboarding/views/training_preferences_view.dart';
import 'package:fitai_mobile/features/onboarding/views/onboarding_view.dart';
import 'package:fitai_mobile/features/onboarding/views/goal_selection_view.dart';
import 'package:fitai_mobile/features/onboarding/views/about_you_experience_view.dart';
import 'package:fitai_mobile/features/onboarding/views/schedule_location_view.dart';
import 'package:fitai_mobile/features/onboarding/views/equipment_selection_view.dart';
import 'package:fitai_mobile/features/onboarding/views/lifestyle_nutrition_limitations_view.dart';
import 'package:fitai_mobile/features/auth/views/auth_view.dart';

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
        {Future<void> Function(String, int)? checkIn}) =>
    TrainingMapDashboard(
        data: _data,
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

Future<void> _snapshot(WidgetTester tester, String name) async {
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_preview));
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
    expect(trainingMap.colors['quads'], const Color(0xFF606060),
        reason: 'Unlogged scheduled work is not training volume');
    expect(find.text('Plan'), findsNothing);
    expect(find.text('Check-in'), findsNothing);
    expect(find.text('No direct sets'), findsOneWidget);
    await tester.tap(find.text('Back'));
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
  testWidgets('muscle tapping opens real details and saves a soreness check-in',
      (tester) async {
    await _size(tester);
    String? muscle;
    int? soreness;
    await tester.pumpWidget(_app(_dashboard(checkIn: (id, value) async {
      muscle = id;
      soreness = value;
    })));
    await tester.pump();
    final rect = tester.getRect(find.byType(AnatomicalTrainingMap));
    final point = _interior(musclePaths(back: false)['chest']!.first);
    await tester.tapAt(Offset(rect.left + rect.width * point.dx / 220,
        rect.top + rect.height * point.dy / 440));
    await tester.pumpAndSettle();
    expect(find.text('Chest'), findsWidgets);
    expect(find.text('Direct sets'), findsOneWidget);
    await tester.tap(find.text('Sore'));
    await tester.pumpAndSettle();
    expect(muscle, 'chest');
    expect(soreness, 2);
    await _snapshot(tester, 'body-muscle-detail-preview');
    expect(find.text('6 of 10 direct sets · weekly plan'), findsOneWidget);
    Navigator.of(tester.element(find.text('Direct sets'))).pop();
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
    await tester.pumpWidget(_app(_dashboard(), scale: 1.3));
    await tester.pump();
    expect(find.text('Muscles trained'), findsOneWidget);
    expect(find.text('Plan'), findsNothing);
    expect(find.text('Check-in'), findsNothing);
    expect(
        tester
            .widget<AnatomicalTrainingMap>(find.byType(AnatomicalTrainingMap))
            .colors['quads'],
        const Color(0xFF606060),
        reason: 'Planned sets and soreness do not replace logged volume');
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
    await tester.pumpWidget(
        _app(TrainingPreferencesView(onContinue: () => continued = true)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Quads'));
    await tester.pump(const Duration(milliseconds: 250));
    await _snapshot(tester, 'onboarding-preferences-preview');
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 100));
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
