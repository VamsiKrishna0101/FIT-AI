import 'package:flutter/material.dart';

import '../../../core/components/premium_surface.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/fitai_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../today/repositories/today_repository.dart';
import '../../health/views/health_connection_view.dart';
import '../../onboarding/views/training_preferences_view.dart';
import '../../onboarding/views/equipment_selection_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = FitAiCopy.of(context);
    final user = TodayRepository.shared.current?.user;
    final displayName = user?.name.trim().isNotEmpty == true
        ? user!.name
        : copy.text('profile');
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: FitnessTheme.canvas,
      appBar: AppBar(
          title: Text(copy.text('profileSettings')),
          leading: IconButton(
              tooltip: copy.text('close'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded))),
      body: SafeArea(
        top: false,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              PremiumSurface(
                  padding: const EdgeInsets.all(17),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            FitnessTheme.silver.withValues(alpha: .13),
                        child: Text(initials.isEmpty ? 'F' : initials,
                            style: const TextStyle(
                                color: FitnessTheme.silver,
                                fontWeight: FontWeight.w700,
                                fontSize: 16))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                          if (user?.email?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(user!.email!,
                                style: const TextStyle(
                                    color: DSColors.textSecondary,
                                    fontSize: 12))
                          ]
                        ])),
                  ])),
              const SizedBox(height: 25),
              PremiumSurface(
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.favorite_outline_rounded),
                      title: Text(fitnessText(context, 'Health connection')),
                      subtitle: Text(fitnessText(context,
                          'Permissions, syncing and connected readings')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const HealthConnectionView())))),
              const SizedBox(height: 10),
              PremiumSurface(
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(fitnessText(context, 'Training preferences')),
                      subtitle: Text(fitnessText(
                          context, 'Priorities, schedule and movement notes')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const TrainingPreferencesView(
                                  editProfile: true))))),
              const SizedBox(height: 10),
              PremiumSurface(
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(fitnessText(context, 'Equipment')),
                      subtitle: Text(fitnessText(
                          context, 'Update what you can train with')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<bool>(
                              builder: (_) => const EquipmentSelectionView(
                                  editProfile: true))))),
              const SizedBox(height: 20),
              Text(copy.text('appPreferences').toUpperCase(),
                  style: const TextStyle(
                      color: FitnessTheme.silver,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.35)),
              const SizedBox(height: 8),
              Text(copy.text('language'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.3)),
              const SizedBox(height: 5),
              Text(copy.text('languageDescription'),
                  style: const TextStyle(
                      color: DSColors.textSecondary,
                      fontSize: 13,
                      height: 1.4)),
              const SizedBox(height: 14),
              for (final language in AppLanguage.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LanguageTile(language: language),
                ),
            ]),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  const _LanguageTile({required this.language});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: LanguageManager.shared,
        builder: (context, _) {
          final selected = LanguageManager.shared.currentLanguage == language;
          return PremiumSurface(
            onTap: selected || LanguageManager.shared.saving
                ? null
                : () async {
                    try {
                      await LanguageManager.shared
                          .selectLanguage(language, persistAccount: true);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(fitnessText(context,
                                'Could not save your language. Please try again.'))));
                      }
                    }
                  },
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: selected ? const Color(0xFF303030) : null,
            child: Row(children: [
              const Icon(Icons.language_rounded,
                  color: FitnessTheme.silver, size: 22),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(language.nativeName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                        language == AppLanguage.switzerland
                            ? fitnessText(context,
                                'Translations use German for Swiss German.')
                            : language.countryName,
                        style: const TextStyle(
                            color: DSColors.textSecondary, fontSize: 11))
                  ])),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: FitnessTheme.silver, size: 21)
              else
                const Icon(Icons.circle_outlined,
                    color: Colors.white24, size: 20),
            ]),
          );
        },
      );
}
