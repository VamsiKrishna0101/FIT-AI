import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/privacy_repository.dart';

Future<void> openSettingsLink(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !['https', 'mailto'].contains(uri.scheme) ||
      uri.userInfo.isNotEmpty ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw StateError('This link could not be opened. Please try again.');
  }
}

Future<bool> ensureAiSharingConsent(BuildContext context,
    {PrivacyRepository? repository, bool review = false}) async {
  final repo = repository ?? PrivacyRepository();
  final config = await repo.configuration(), consent = await repo.consent();
  final active = consent['aiPlanningConsent'] == true &&
      consent['aiPlanningPolicyVersion'] == config['aiPolicyVersion'];
  if (active && !review) return true;
  if (!context.mounted) return false;
  final policy = config['privacyPolicyUrl'] as String?;
  final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              backgroundColor: FitnessTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const FitnessText('AI plan data sharing'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    FitnessText(
                        'To create a personal plan, Setcraft sends ${config['aiProvider'] ?? 'the AI provider'} your profile, goals, training and food preferences, entered measurements, logged workouts, meals and recovery check-ins.',
                        style: const TextStyle(height: 1.5, fontSize: 14)),
                    const SizedBox(height: 14),
                    const FitnessText(
                        'Photos and imported Apple Health or Health Connect readings are excluded. You can stop future sharing in Privacy & Data. Existing plans remain saved.',
                        style: TextStyle(
                            color: FitnessTheme.muted,
                            height: 1.5,
                            fontSize: 13)),
                    if (policy != null)
                      TextButton(
                          onPressed: () async {
                            try {
                              await openSettingsLink(policy);
                            } catch (_) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(const SnackBar(
                                        content: FitnessText(
                                            'Could not open the privacy policy.')));
                              }
                            }
                          },
                          child: const FitnessText('Read privacy policy'))
                    else
                      const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: FitnessText(
                              'AI sharing is unavailable until Setcraft publishes its privacy policy.',
                              style: TextStyle(
                                  color: FitnessTheme.muted,
                                  fontSize: 13,
                                  height: 1.5))),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const FitnessText('Not now')),
                FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black),
                    onPressed: policy == null
                        ? null
                        : () => Navigator.pop(dialogContext, true),
                    child: const FitnessText('Agree & continue'))
              ]));
  if (accepted != true) return false;
  await repo.setAiConsent(true, config['aiPolicyVersion'] as String);
  return true;
}
