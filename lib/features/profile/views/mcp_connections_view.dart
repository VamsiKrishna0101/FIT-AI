import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/premium_surface.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import 'settings_components.dart';

class McpConnectionsView extends StatelessWidget {
  const McpConnectionsView({super.key});

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: 'MCP & integrations',
        subtitle: 'Your fitness context, connected on your terms.',
        children: [
          const PremiumSurface(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Icon(CupertinoIcons.link, size: 30, color: FitnessTheme.silver),
                SizedBox(height: 18),
                FitnessText('A connection you control',
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.5)),
                SizedBox(height: 10),
                FitnessText(
                    'Choose which AI apps can access your FitAI context. Review each connection before sharing.',
                    style: TextStyle(
                        color: FitnessTheme.muted, fontSize: 13, height: 1.5)),
              ])),
          const SizedBox(height: 26),
          SettingsGroup(title: 'AI apps', children: [
            SettingsRow(
                icon: CupertinoIcons.sparkles,
                title: 'Claude',
                subtitle: 'Explore the planned connection',
                value: 'Coming soon',
                onTap: () => Navigator.push(context,
                    AppPageRoute<void>(page: const ClaudeConnectionView()))),
          ]),
          const SettingsNotice(
              'No AI apps are connected. This feature is not available yet.'),
        ],
      );
}

class ClaudeConnectionView extends StatelessWidget {
  const ClaudeConnectionView({super.key});

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: 'Claude',
        subtitle: 'Bring your fitness context into your conversations.',
        children: [
          PremiumSurface(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(CupertinoIcons.sparkles,
                          size: 28, color: FitnessTheme.silver)),
                  const SizedBox(height: 20),
                  const FitnessText('FitAI × Claude',
                      style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.7)),
                  const SizedBox(height: 12),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          border: Border.all(color: FitnessTheme.line),
                          borderRadius: BorderRadius.circular(20)),
                      child: const FitnessText('Coming soon',
                          style: TextStyle(
                              color: FitnessTheme.muted, fontSize: 12))),
                ],
              )),
          const SizedBox(height: 28),
          const SettingsGroup(title: 'Planned access', children: [
            SettingsRow(
                icon: CupertinoIcons.calendar,
                title: 'Weekly plans',
                subtitle: 'Understand your schedule and exercise targets.'),
            SettingsRow(
                icon: CupertinoIcons.chart_bar,
                title: 'Workout history',
                subtitle: 'Review logged sets, reps and weights.'),
            SettingsRow(
                icon: CupertinoIcons.leaf_arrow_circlepath,
                title: 'Nutrition context',
                subtitle: 'Use your preferences and logged meals.'),
          ]),
          const SettingsGroup(title: 'Your control', children: [
            SettingsRow(
                icon: CupertinoIcons.lock_shield,
                title: 'Choose what to share',
                subtitle: 'Permissions will be reviewed before connecting.'),
            SettingsRow(
                icon: CupertinoIcons.hand_raised,
                title: 'Review and revoke access',
                subtitle:
                    'Manage the connection from this screen when it is available.'),
          ]),
          const SettingsNotice(
              'Connection setup is coming later. Nothing is shared with Claude from this screen.'),
        ],
      );
}
