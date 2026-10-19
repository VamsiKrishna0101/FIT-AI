import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/components/content_transition.dart';
import '../../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../../core/components/motion.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import '../../models/body_progress_summary.dart';
import 'body_focus_panel.dart';

class BodyPhysiqueHome extends StatelessWidget {
  final BodyOverview? overview;
  final Widget? planCard;
  final bool loading, isActive;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onManual, onPhotos, onMeasurements, onHistory;

  const BodyPhysiqueHome({
    super.key,
    this.overview,
    this.planCard,
    this.loading = false,
    this.isActive = true,
    this.error,
    required this.onRefresh,
    required this.onManual,
    required this.onPhotos,
    required this.onMeasurements,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final summary = BodyProgressSummary(overview);
    final report = overview?.records
        .where((entry) =>
            entry.bodyRegions.isNotEmpty ||
            (entry.physiqueReport?['photosUsed'] as num? ?? 0) > 0)
        .firstOrNull;
    final waiting = loading && overview == null;

    return Stack(children: [
      IgnorePointer(
        ignoring: waiting,
        child: AnimatedOpacity(
          opacity: waiting ? 0 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : ContentTransition.duration,
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: FitnessTheme.silver,
            child: ListView(
              key: const PageStorageKey('physique-home'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, LiquidSilverBottomBar.scrollBottomInset(context)),
              children: [
                if (error != null)
                  FitnessCard(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FitnessText(error!,
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.muted)),
                      TextButton(
                          onPressed: onRefresh,
                          child: const FitnessText('Retry')),
                    ],
                  )),
                if (planCard != null) ...[
                  planCard!,
                  const SizedBox(height: 16),
                ],
                BodyFocusPanel(
                  assessment: report,
                  chosenFocus: overview?.focus ?? const [],
                  female: overview?.female ?? false,
                  compact: true,
                  readings: summary.measurements,
                  onScan: onPhotos,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  final actions = [
                    FilledButton.icon(
                      onPressed: onPhotos,
                      style: FilledButton.styleFrom(
                          backgroundColor: FitnessTheme.silver,
                          foregroundColor: FitnessTheme.canvas,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)),
                      icon: const Icon(CupertinoIcons.camera, size: 17),
                      label: const FitnessText('Photo scan',
                          style: TextStyle(fontSize: 12)),
                    ),
                    OutlinedButton.icon(
                      onPressed: onManual,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: FitnessTheme.silver,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)),
                      icon: const Icon(CupertinoIcons.add, size: 16),
                      label: const FitnessText('Add measurements',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ];
                  if (constraints.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(12) > 16) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          actions[0],
                          const SizedBox(height: 8),
                          actions[1]
                        ]);
                  }
                  return Row(children: [
                    Expanded(child: actions[0]),
                    const SizedBox(width: 10),
                    Expanded(child: actions[1]),
                  ]);
                }),
                const SizedBox(height: 22),
                FitnessCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(children: [
                    _link(CupertinoIcons.photo_on_rectangle, 'Scan history',
                        'Explore', onHistory),
                    const Divider(height: 1, color: FitnessTheme.line),
                    _link(CupertinoIcons.resize, 'Measurements', 'View',
                        onMeasurements),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
      if (waiting) const Center(child: CupertinoActivityIndicator()),
    ]);
  }

  Widget _link(IconData icon, String name, String action, VoidCallback onTap) =>
      MotionPress(
          child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: onTap,
                leading: Icon(icon, size: 19, color: FitnessTheme.silver),
                title: FitnessText(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w400)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  FitnessText(action,
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted)),
                  const SizedBox(width: 7),
                  const Icon(CupertinoIcons.chevron_right,
                      size: 12, color: FitnessTheme.muted),
                ]),
              )));
}
