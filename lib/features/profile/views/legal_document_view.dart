import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../legal/legal_content.dart';
import 'ai_sharing_consent.dart';
import 'settings_components.dart';

/// In-app Privacy Policy / Terms: a plain list of sections, each opening
/// its full text. Content is bundled, so it works offline.
class LegalDocumentView extends StatelessWidget {
  final LegalDocument document;
  const LegalDocumentView({super.key, required this.document});

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: document.title,
        subtitle: document.updated,
        children: [
          SettingsGroup(dividerIndent: 16, children: [
            for (final section in document.sections)
              SettingsRow(
                  title: section.title,
                  onTap: () => Navigator.push(
                      context,
                      AppPageRoute<void>(
                          page: LegalSectionView(
                              document: document, section: section)))),
          ]),
        ],
      );
}

class LegalSectionView extends StatelessWidget {
  final LegalDocument document;
  final LegalSection section;
  const LegalSectionView(
      {super.key, required this.document, required this.section});

  static const _body =
      TextStyle(fontSize: 15, height: 1.6, color: FitnessTheme.silver);

  Widget _block(BuildContext context, LegalBlock block) =>
      switch (block.kind) {
        LegalBlockKind.paragraph => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FitnessText(block.text, style: _body)),
        LegalBlockKind.bullet => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Text('•', style: _body)),
              Expanded(child: FitnessText(block.text, style: _body)),
            ])),
        LegalBlockKind.link => Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4)),
                onPressed: () => openSettingsLink(block.url!).catchError((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('This link could not be opened.')));
                      }
                    }),
                child: FitnessText(block.text,
                    style: const TextStyle(
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                        color: FitnessTheme.silver)))),
      };

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: section.title,
        subtitle: '',
        children: [
          for (final block in section.blocks) _block(context, block),
          const SizedBox(height: 16),
          FitnessText('${document.title} · ${document.updated}',
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
        ],
      );
}
