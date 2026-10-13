import 'package:fitai_mobile/features/onboarding/views/training_preferences_view.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitai_mobile/core/localization/app_language.dart';
import 'package:fitai_mobile/core/localization/language_manager.dart';
import 'package:fitai_mobile/core/localization/fitness_copy_data.dart';
import 'package:fitai_mobile/features/body_scan/models/body_assessment_models.dart';
import 'package:fitai_mobile/features/body_scan/models/training_map_models.dart';
import 'package:fitai_mobile/features/body_scan/repositories/body_assessment_repository.dart';
import 'package:fitai_mobile/features/body_scan/views/body_view.dart';

class _BodyRepository extends BodyAssessmentRepository {
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
      'Body changes language in place while preserving the selected view',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final repository = _BodyRepository();
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    await tester.pumpWidget(_app(
        BodyView(repository: repository, onTrain: () {}), AppLanguage.germany));
    await tester.pumpAndSettle();
    expect(find.text(fitnessCopyData['de']!['Your body']!), findsOneWidget);
    expect(find.text('Your body'), findsNothing);
    await tester.tap(find.text(fitnessCopyData['de']!['Physique']!));
    await tester.pumpAndSettle();
    expect(find.text(fitnessCopyData['de']!['Estimate from photos']!),
        findsOneWidget);
    await LanguageManager.shared.selectLanguage(AppLanguage.france);
    await tester.pumpWidget(_app(
        BodyView(repository: repository, onTrain: () {}), AppLanguage.france));
    await tester.pumpAndSettle();
    expect(find.text(fitnessCopyData['fr']!['Your body']!), findsOneWidget);
    expect(find.text(fitnessCopyData['fr']!['Estimate from photos']!),
        findsOneWidget);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(tester.takeException(), isNull);
  });
}
