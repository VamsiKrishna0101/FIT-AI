import '../../../../core/components/content_transition.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../planner/repositories/weekly_plan_repository.dart';
import '../../../planner/views/weekly_plan_card.dart';
import '../../models/body_assessment_models.dart';
import '../../models/body_progress_summary.dart';
import 'body_controls.dart';
import 'body_focus_panel.dart';

class BodyPhysiqueHome extends StatelessWidget {
  final BodyOverview? overview;
  final bool loading, isActive;
  final String? error;
  final WeeklyPlanRepository? planRepository;
  final Future<void> Function() onRefresh;
  final VoidCallback onManual, onPhotos, onMeasurements, onHistory;
  final ValueChanged<BodyAssessment> onRecord, onCompare;

  const BodyPhysiqueHome({
    super.key,
    this.overview,
    this.loading = false,
    this.isActive = true,
    this.error,
    this.planRepository,
    required this.onRefresh,
    required this.onManual,
    required this.onPhotos,
    required this.onMeasurements,
    required this.onHistory,
    required this.onRecord,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final summary = BodyProgressSummary(overview);
    final report = summary.report ?? overview?.latest;
    final earlier = report == null
        ? <BodyAssessment>[]
        : overview!.records
            .where((entry) => entry.isEarlierThan(report))
            .toList();

    final loadingData = loading && overview == null;

    return Stack(children: [
      IgnorePointer(
        ignoring: loadingData,
        child: ExcludeSemantics(
          excluding: loadingData,
          child: AnimatedOpacity(
            opacity: loadingData ? 0 : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : ContentTransition.duration,
            curve: Curves.easeOutCubic,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: FitnessTheme.silver,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 4, 16,
                    LiquidSilverBottomBar.scrollBottomInset(context)),
                children: [
                  if (error != null)
                    FitnessCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FitnessText(error!,
                                style:
                                    const TextStyle(color: FitnessTheme.muted)),
                            TextButton(
                                onPressed: onRefresh,
                                child: const FitnessText('Retry')),
                          ]),
                    ),
                  if (loading && overview == null)
                    const SizedBox(height: 440)
                  else ...[
                    LayoutBuilder(builder: (context, constraints) {
                      final manual = OutlinedButton.icon(
                        onPressed: onManual,
                        icon: const Icon(CupertinoIcons.add, size: 17),
                        label: const FitnessText('Measurements',
                            style: TextStyle(fontSize: 12)),
                      );
                      final photos = FilledButton.icon(
                        onPressed: onPhotos,
                        style: FilledButton.styleFrom(
                            backgroundColor: FitnessTheme.silver,
                            foregroundColor: FitnessTheme.canvas),
                        icon: const Icon(CupertinoIcons.camera, size: 17),
                        label: const FitnessText('Photo scan',
                            style: TextStyle(fontSize: 12)),
                      );
                      if (constraints.maxWidth < 340 ||
                          MediaQuery.textScalerOf(context).scale(12) > 16) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              manual,
                              const SizedBox(height: 8),
                              photos
                            ]);
                      }
                      return Row(children: [
                        Expanded(child: manual),
                        const SizedBox(width: 10),
                        Expanded(child: photos)
                      ]);
                    }),
                    const SizedBox(height: 16),
                    WeeklyPlanCard(
                      repository: planRepository,
                      isActive: isActive,
                      onReturn: onRefresh,
                    ),
                    BodySectionTitle('Your physique',
                        action: report == null ? null : 'View report',
                        onTap: report == null ? null : () => onRecord(report)),
                    BodyFocusPanel(
                      assessment: report,
                      chosenFocus: overview?.focus ?? const [],
                      female: overview?.female ?? false,
                      onCompare:
                          earlier.isEmpty ? null : () => onCompare(report!),
                      onOpenPhotos:
                          report == null ? null : () => onRecord(report),
                    ),
                    const SizedBox(height: 18),
                    FitnessCard(
                      child: Material(
                          color: Colors.transparent,
                          child: Column(children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(CupertinoIcons.chart_bar,
                                  size: 21),
                              title: const FitnessText('Measurements',
                                  style: TextStyle(fontSize: 14)),
                              subtitle: const FitnessText(
                                  'Your saved readings and sources',
                                  style: TextStyle(
                                      color: FitnessTheme.muted, fontSize: 12)),
                              trailing: const Icon(CupertinoIcons.chevron_right,
                                  size: 14),
                              onTap: onMeasurements,
                            ),
                            const Divider(color: FitnessTheme.line),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading:
                                  const Icon(CupertinoIcons.clock, size: 21),
                              title: const FitnessText('Body history',
                                  style: TextStyle(fontSize: 14)),
                              subtitle: const FitnessText(
                                  'Review previous scans and entries',
                                  style: TextStyle(
                                      color: FitnessTheme.muted, fontSize: 12)),
                              trailing: const Icon(CupertinoIcons.chevron_right,
                                  size: 14),
                              onTap: onHistory,
                            ),
                          ])),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      if (loadingData)
        const Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: LoadingPlaceholder(),
          ),
        ),
    ]);
  }
}
