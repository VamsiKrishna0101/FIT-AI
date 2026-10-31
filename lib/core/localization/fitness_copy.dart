import 'body_measurements_copy.dart';
import 'package:flutter/widgets.dart';
import 'fitness_copy_data.dart';
import 'food_names.dart';
import 'language_manager.dart';
import 'membership_copy.dart';
import 'training_experience_copy.dart';
import 'plan_reveal_copy.dart';
import 'workout_session_copy.dart';
import 'weekly_rhythm_copy.dart';
import 'readiness_copy.dart';
import 'nutrition_presentation_copy.dart';
import 'training_hub_copy.dart';
import 'progress_presentation_copy.dart';

String foodDisplayName(String id, String fallback) {
  final language = LanguageManager.shared.currentLanguage.code.split('-').first;
  final translations = foodNames[id];
  if (translations?['en'] != fallback) return fallback;
  return translations?[language] ?? fallback;
}

final _displayTerms = {
  for (final locale in fitnessCopyData.entries)
    locale.key: {
      for (final term in locale.value.entries)
        term.key.toLowerCase(): term.value
    }
};

/// Shared display terms. Canonical catalogue IDs and filter values stay stable.
String fitnessText(BuildContext context, String text,
    {Map<String, Object> values = const {}}) {
  final locale = Localizations.localeOf(context).languageCode;
  var translated = bodyMeasurementsTranslation(locale, text) ??
      progressPresentationTranslation(locale, text) ??
      trainingHubTranslation(locale, text) ??
      nutritionPresentationTranslation(locale, text) ??
      readinessTranslation(locale, text) ??
      weeklyRhythmTranslation(locale, text) ??
      workoutSessionTranslation(locale, text) ??
      planRevealTranslation(locale, text) ??
      trainingExperienceTranslation(locale, text) ??
      membershipTranslation(locale, text) ??
      fitnessCopyData[locale]?[text] ??
      (locale == 'en' ? text : _displayTerms[locale]?[text.toLowerCase()]) ??
      text;
  // Composite metadata uses the same short labels as standalone controls.
  if (translated == text && text.contains(' · ')) {
    translated = text
        .split(' · ')
        .map((part) =>
            fitnessCopyData[locale]?[part] ??
            (locale == 'en'
                ? part
                : _displayTerms[locale]?[part.toLowerCase()]) ??
            part)
        .join(' · ');
  }
  for (final item in values.entries) {
    translated = translated.replaceAll('{${item.key}}', item.value.toString());
  }
  return translated;
}
