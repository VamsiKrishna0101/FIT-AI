import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import 'settings_components.dart';

class SettingsPreferencesView extends StatelessWidget {
  const SettingsPreferencesView({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: LanguageManager.shared,
        builder: (context, _) => SettingsPage(
          title: 'App preferences',
          subtitle: 'Small details. A more familiar experience.',
          children: [
            SettingsGroup(children: [
              SettingsRow(
                  icon: CupertinoIcons.globe,
                  title: 'Language',
                  value: LanguageManager.shared.currentLanguage.nativeName,
                  onTap: () => Navigator.push(context,
                      AppPageRoute<void>(page: const SettingsLanguageView()))),
              const SettingsRow(
                  icon: CupertinoIcons.circle_lefthalf_fill,
                  title: 'Appearance',
                  value: 'Dark'),
              const SettingsRow(
                  icon: CupertinoIcons.number,
                  title: 'Workout units',
                  value: 'kg'),
              const SettingsRow(
                  icon: CupertinoIcons.resize,
                  title: 'Body measurements',
                  value: 'cm'),
            ]),
            const SettingsNotice(
                'Workout loads currently use kilograms and body measurements use centimetres.'),
          ],
        ),
      );
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
          subtitle: 'Choose the language you feel at home in.',
          children: [
            SettingsGroup(children: [
              for (final language in AppLanguage.values)
                SettingsRow(
                  icon: LanguageManager.shared.currentLanguage == language
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.globe,
                  title: language.nativeName,
                  subtitle: language == AppLanguage.switzerland
                      ? 'Translations use German for Swiss German.'
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
  Widget build(BuildContext context) => const SettingsPage(
        title: 'Help & about',
        subtitle: 'A little more about your Setcraft experience.',
        children: [
          SettingsGroup(title: 'Setcraft', children: [
            SettingsRow(
                icon: CupertinoIcons.info_circle,
                title: 'Version',
                value: '1.0.0 (1)'),
            SettingsRow(
                icon: CupertinoIcons.sparkles,
                title: 'Personal plans',
                subtitle:
                    'Preferences and logged training guide your next weekly plan.'),
          ]),
          SettingsGroup(title: 'Quick answers', children: [
            SettingsRow(
                icon: CupertinoIcons.heart,
                title: 'Missing health readings?',
                subtitle:
                    'Check Health & sleep → Health connection. A connected app can only read data that your health provider has saved.'),
            SettingsRow(
                icon: CupertinoIcons.calendar,
                title: 'When can I generate again?',
                subtitle:
                    'Seven days after your last generated plan. Your saved plan remains available in Weekly plan.'),
            SettingsRow(
                icon: CupertinoIcons.camera,
                title: 'Are body photos required?',
                subtitle:
                    'No. You can generate without a scan. Saving photos is an optional choice during each scan.'),
          ]),
        ],
      );
}
