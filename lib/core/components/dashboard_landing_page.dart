import 'package:flutter/material.dart';

import '../theme/ds_colors.dart';
import 'liquid_glass.dart';

/// Consistent empty/feature page for dashboard areas without saved data yet.
class DashboardLandingPage extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final String cardTitle;
  final String cardMessage;
  final String statusLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DashboardLandingPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cardTitle,
    required this.cardMessage,
    required this.statusLabel,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                112 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              sliver: SliverList.list(
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: DSColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: DSColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: DSColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  LiquidGlass(
                    radius: 22,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: DSColors.bgRaised,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: DSColors.border),
                              ),
                              child: Icon(
                                icon,
                                color: DSColors.textPrimary,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cardTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: DSColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          cardMessage,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: DSColors.textSecondary),
                        ),
                        if (actionLabel != null && onAction != null) ...[
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onAction,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(actionLabel!),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: DSColors.textTertiary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              statusLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: DSColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
