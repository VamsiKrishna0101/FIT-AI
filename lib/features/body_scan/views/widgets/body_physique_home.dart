import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/components/content_transition.dart';
import '../../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../../core/components/motion.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import '../../models/planned_physique_models.dart';
import 'planned_physique_map.dart';

class BodyPhysiqueHome extends StatelessWidget {
  final BodyOverview? overview;
  final Widget? planCard;
  final bool loading, isActive, planLoading;
  final DateTime? selectedWeek;
  final ValueChanged<DateTime>? onWeekChanged;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onManual, onPhotos, onMeasurements, onHistory;
  final ValueChanged<BodyAssessment>? onRecord;
  final PlannedPhysiqueData? planData;
  final String? planError;

  const BodyPhysiqueHome({
    super.key,
    this.overview,
    this.planCard,
    this.loading = false,
    this.planLoading = false,
    this.selectedWeek,
    this.onWeekChanged,
    this.isActive = true,
    this.error,
    required this.onRefresh,
    required this.onManual,
    required this.onPhotos,
    required this.onMeasurements,
    required this.onHistory,
    this.onRecord,
    this.planData,
    this.planError,
  });

  @override
  Widget build(BuildContext context) {
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
                PlannedPhysiqueMap(
                    data: planData,
                    loading: loading || planLoading,
                    selectedWeek: selectedWeek,
                    onWeekChanged: onWeekChanged,
                    error: planError,
                    onRetry: onRefresh,
                    female: overview?.female ?? false),
                const SizedBox(height: 16),
                if (planCard != null) ...[
                  planCard!,
                  const SizedBox(height: 16),
                ],
                FitnessCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(children: [
                    _link(CupertinoIcons.camera, 'Photo review', 'Optional',
                        onPhotos),
                    const Divider(height: 1, color: FitnessTheme.line),
                    _link(CupertinoIcons.photo_on_rectangle, 'Scan history',
                        'Explore', onHistory),
                  ]),
                ),
                const SizedBox(height: 12),
                FitnessCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(children: [
                    _link(CupertinoIcons.add, 'Add measurements', 'Optional',
                        onManual),
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
