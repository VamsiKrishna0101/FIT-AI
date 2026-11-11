import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../legal/legal_content.dart';
import '../repositories/privacy_repository.dart';
import 'legal_document_view.dart';

Future<void> openSettingsLink(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !['https', 'mailto'].contains(uri.scheme) ||
      uri.userInfo.isNotEmpty ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw StateError('This link could not be opened. Please try again.');
  }
}

/// App Store Guideline 5.1.2(i): personal data is sent to a third-party AI
/// only after the person sees what is shared, with whom, and agrees.
/// Consent is asked once per policy version (the backend changes the version
/// when the provider changes) and is rechecked server-side before each request.
Future<bool> ensureAiSharingConsent(BuildContext context,
    {PrivacyRepository? repository, bool review = false}) async {
  final repo = repository ?? PrivacyRepository();
  final config = await repo.configuration(), consent = await repo.consent();
  final version = config['aiPolicyVersion'] as String;
  final active = consent['aiPlanningConsent'] == true &&
      consent['aiPlanningPolicyVersion'] == version;
  if (active) return true;
  if (!context.mounted) return false;
  final provider = (config['aiProvider'] as String?)?.trim();
  final agreed = await showAiSharingNotice(context,
      provider: provider == null || provider.isEmpty ? null : provider,
      privacyPolicyUrl: config['privacyPolicyUrl'] as String?);
  if (!agreed) return false;
  await repo.setAiConsent(true, version);
  return true;
}

Future<bool> showAiSharingNotice(BuildContext context,
    {String? provider, String? privacyPolicyUrl}) async {
  final recipient = provider == null
      ? 'a third-party AI service'
      : '$provider, a third-party AI service';
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        animationStyle: DSMotion.dialogStyle(context),
        builder: (context) => AlertDialog(
          key: const ValueKey('ai-sharing-notice'),
          backgroundColor: FitnessTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const FitnessText('AI plan generation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FitnessText(
                    'To create your plan, Setcraft sends your goals, training preferences, equipment, food preferences and recent workout and meal logs to $recipient.',
                    style: const TextStyle(
                        color: FitnessTheme.silver, height: 1.5)),
                const SizedBox(height: 12),
                const FitnessText(
                    'Photos and Apple Health or Health Connect data are never sent.',
                    style: TextStyle(color: FitnessTheme.muted, height: 1.5)),
                const SizedBox(height: 12),
                const FitnessText(
                    'You can turn this off anytime in Settings → Privacy & Data.',
                    style: TextStyle(color: FitnessTheme.muted, height: 1.5)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => Navigator.push(
                          context,
                          AppPageRoute<void>(
                              page: const LegalDocumentView(
                                  document: privacyPolicy))),
                      child: const FitnessText('Read the Privacy Policy')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                key: const ValueKey('ai-sharing-decline'),
                onPressed: () => Navigator.pop(context, false),
                child: const FitnessText('Not now')),
            TextButton(
                key: const ValueKey('ai-sharing-agree'),
                onPressed: () => Navigator.pop(context, true),
                child: const FitnessText('Agree',
                    style: TextStyle(
                        color: FitnessTheme.silver,
                        fontWeight: FontWeight.w600))),
          ],
        ),
      ) ??
      false;
}
