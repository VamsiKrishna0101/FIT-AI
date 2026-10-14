import 'package:flutter/widgets.dart';
import 'fitness_copy_data.dart';
import 'food_names.dart';
import 'language_manager.dart';

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
  var translated = fitnessCopyData[locale]?[text] ??
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
