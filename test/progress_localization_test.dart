import 'package:fitai_mobile/core/localization/app_language.dart';
import 'package:fitai_mobile/core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_copy_data.dart';
import 'package:fitai_mobile/features/progress/components/progress_date_filter.dart';
import 'package:fitai_mobile/features/progress/models/progress_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in AppLanguage.values) {
    testWidgets('Progress labels, dates and numbers use ${language.code}',
        (tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(
        locale: language.locale,
        supportedLocales: AppLanguage.values.map((item) => item.locale),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(builder: (value) {
          context = value;
          return Scaffold(
              body: ProgressDateFilter(period: '4w', onChanged: (_, __) {}));
        }),
      ));
      await tester.pumpAndSettle();
      final locale = language.locale.languageCode;
      for (final key in [
        'Exercises',
        'Retry',
        'Sets',
        'Completed',
        'No activity',
        'Full-body strength'
      ]) {
        expect(fitnessText(context, key), fitnessCopyData[locale]![key]);
      }
      expect(find.text(fitnessCopyData[locale]!['4 weeks']!), findsOneWidget);
      final value = progressValue(context, 72.5, unit: 'kg');
      expect(
          value,
          language == AppLanguage.uk || language == AppLanguage.switzerland
              ? '72.5 kg'
              : '72,5 kg');
      expect(
          progressMuscleLabel(
              context, {'id': 'chest', 'label': 'STALE LANGUAGE'}),
          fitnessCopyData[locale]!['Chest']);
      expect(progressDate('2026-10-09', language.locale.toLanguageTag()),
          isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  test('Dutch and Italian common controls retain reviewed translations', () {
    expect(fitnessCopyData['nl']!['Exercises'], 'Oefeningen');
    expect(fitnessCopyData['it']!['Exercises'], 'Esercizi');
    expect(fitnessCopyData['it']!['Retry'], 'Riprova');
    expect(fitnessCopyData['it']!['Sets'], 'Serie');
    expect(fitnessCopyData['it']!['Chest'], 'Petto');
    expect(fitnessCopyData['it']!['Shoulders'], 'Spalle');
    expect(fitnessCopyData['it']!['Core'], 'Addome');
  });
}
