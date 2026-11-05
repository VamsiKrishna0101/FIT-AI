import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/language_manager.dart';
import 'support_views.dart';
import 'settings_components.dart';

class SettingsPreferencesView extends StatelessWidget {
  const SettingsPreferencesView({super.key});

  @override
  Widget build(BuildContext context) => const SettingsLanguageView();
}

class SettingsLanguageView extends StatelessWidget {
  const SettingsLanguageView({super.key});

  Future<void> _select(BuildContext context, AppLanguage language) async {
    try {
      await LanguageManager.shared
          .selectLanguage(language, persistAccount: true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: FitnessText(
                'Could not save your language. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: LanguageManager.shared,
        builder: (context, _) => SettingsPage(
          title: 'Language',
          subtitle: '',
          children: [
            SettingsGroup(dividerIndent: 16, children: [
              for (final language in AppLanguage.values)
                SettingsRow(
                  trailingWidget:
                      LanguageManager.shared.currentLanguage == language
                          ? const Icon(CupertinoIcons.checkmark,
                              size: 18, color: Colors.white)
                          : null,
                  title: language.nativeName,
                  subtitle: language == AppLanguage.switzerland
                      ? 'German translations'
                      : language.countryName,
                  onTap: LanguageManager.shared.saving ||
                          LanguageManager.shared.currentLanguage == language
                      ? null
                      : () => _select(context, language),
                ),
            ]),
          ],
        ),
      );
}

class SettingsAboutView extends StatelessWidget {
  const SettingsAboutView({super.key});
  @override
  Widget build(BuildContext context) => const HelpSupportView();
}
