import 'fixtures/body_map_fixture.dart';
import 'package:setcraft/features/body_scan/models/body_map_models.dart';
import 'package:setcraft/core/localization/fitness_copy.dart';
import 'package:setcraft/features/body_scan/views/widgets/body_measurement_dashboard.dart';
import 'package:setcraft/features/onboarding/views/training_preferences_view.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/notifications/views/notification_settings_view.dart';
import 'notification_settings_test.dart' show FakeNotifications, FakePush;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/core/localization/fitness_copy_data.dart';
import 'package:setcraft/core/localization/notification_copy.dart';
import 'package:setcraft/features/body_scan/models/body_assessment_models.dart';
import 'package:setcraft/features/body_scan/models/training_map_models.dart';
import 'package:setcraft/features/body_scan/repositories/body_assessment_repository.dart';
import 'package:setcraft/features/body_scan/views/body_view.dart';

class _BodyRepository extends BodyAssessmentRepository {
  @override
  Future<BodyMapData> bodyMap(
          {DateTime? date, BodyDateSelection? selection}) async =>
      emptyBodyMap(date);

  @override
  Future<BodyOverview> load() async => BodyOverview.fromJson({
        'profile': {'weight': 80, 'gender': 'MALE'},
        'records': []
      });
  @override
  Future<TrainingMapData> trainingMap(
          {DateTime? date, bool daily = false}) async =>
      TrainingMapData.fromJson(
          jsonDecode(File('test/fixtures/training_map.json').readAsStringSync())
              as Map<String, dynamic>);
}

Widget _app(Widget home, AppLanguage language) => MaterialApp(
    theme: ThemeData.dark(),
    locale: language.locale,
    supportedLocales: AppLanguage.values.map((language) => language.locale),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: home);
void main() {
  setUpAll(() async => initializeDateFormatting());
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LanguageManager.shared.selectLanguage(AppLanguage.uk);
  });
  test(
      'all supported content languages cover the same UI terms and placeholders',
      () {
    final english = fitnessCopyData['en']!;
    final placeholder = RegExp(r'\{\w+\}');
    for (final locale in fitnessCopyData.entries) {
      expect(locale.value.keys.toSet(), english.keys.toSet(),
          reason: locale.key);
      for (final term in english.entries) {
        expect(locale.value[term.key], isNotEmpty);
        expect(
            placeholder
                .allMatches(locale.value[term.key]!)
                .map((m) => m[0])
                .toList()
              ..sort(),
            placeholder.allMatches(term.value).map((m) => m[0]).toList()
              ..sort(),
            reason: '${locale.key}: ${term.key}');
      }
    }
  });
  testWidgets(
      'notification settings render every offered language on a small phone',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);
    for (final language in AppLanguage.values) {
      await LanguageManager.shared.restoreAccountLanguage(language.code);
      final data = FakeNotifications();
      await tester.pumpWidget(_app(
          NotificationSettingsView(
              key: ValueKey(language.code),
              repository: data,
              service: FakePush(data)),
          language));
      await tester.pumpAndSettle();
      expect(
          find.text(fitnessCopyData[language.code.split('-').first]![
              'Notifications']!),
          findsOneWidget);
      expect(tester.takeException(), isNull, reason: language.code);
    }
    await tester.pumpWidget(const SizedBox());
    await LanguageManager.shared.restoreAccountLanguage('en');
  });

  test('notification copy covers every language with matching placeholders',
      () {
    final english = notificationCopyData['en']!;
    final placeholder = RegExp(r'\{\w+\}');
    List<String?> marks(String text) =>
        placeholder.allMatches(text).map((m) => m[0]).toList()..sort();
    for (final locale in notificationCopyData.entries) {
      expect(locale.value.keys.toSet(), english.keys.toSet(),
          reason: locale.key);
      for (final term in english.entries) {
        expect(locale.value[term.key], isNotEmpty);
        expect(marks(locale.value[term.key]!), marks(term.value),
            reason: '${locale.key}: ${term.key}');
      }
    }
  });

  testWidgets('notification settings show translated labels and headers',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 1600);
    addTearDown(tester.view.reset);
    await LanguageManager.shared.restoreAccountLanguage('de');
    final data = FakeNotifications()..values['enabled'] = true;
    await tester.pumpWidget(_app(
        NotificationSettingsView(repository: data, service: FakePush(data)),
        AppLanguage.values.firstWhere((l) => l.code.startsWith('de'))));
    await tester.pumpAndSettle();
    expect(find.text('Trainingserinnerungen'), findsOneWidget);
    expect(find.text('Trainingstage · 6:00 PM'), findsOneWidget);
    expect(find.text('Ruhezeiten'), findsOneWidget);
    expect(find.text('Workout reminders'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await LanguageManager.shared.restoreAccountLanguage('en');
  });

  testWidgets('focus selection keeps chip sizes and wrap positions stable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(_app(const TrainingPreferencesView(), AppLanguage.uk));
    await tester.pumpAndSettle();
    final chest = find.byKey(const ValueKey('training-choice-Chest'));
    final shoulders = find.byKey(const ValueKey('training-choice-Shoulders'));
    final first = tester.getRect(chest), second = tester.getRect(shoulders);
    await tester.tap(chest);
    await tester.pumpAndSettle();
    expect(tester.getRect(chest), first);
    expect(tester.getRect(shoulders), second);
    expect(tester.widget<Semantics>(chest).properties.selected, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Body changes language in place while keeping the measurement dashboard',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final repository = _BodyRepository();
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    await tester.pumpWidget(_app(
        BodyView(repository: repository, onTrain: () {}), AppLanguage.germany));
    await tester.pumpAndSettle();
    expect(find.text(fitnessCopyData['de']!['Body']!), findsOneWidget);
    expect(
        find.text(fitnessText(
            tester.element(find.byType(BodyMeasurementDashboard)),
            'Measurements')),
        findsOneWidget);
    expect(find.text('Photo review'), findsNothing);
    await LanguageManager.shared.selectLanguage(AppLanguage.france);
    await tester.pumpWidget(_app(
        BodyView(repository: repository, onTrain: () {}), AppLanguage.france));
    await tester.pumpAndSettle();
    expect(find.text(fitnessCopyData['fr']!['Body']!), findsOneWidget);
    expect(
        find.text(fitnessText(
            tester.element(find.byType(BodyMeasurementDashboard)),
            'Measurements')),
        findsOneWidget);
    expect(find.byType(BodyMeasurementDashboard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
