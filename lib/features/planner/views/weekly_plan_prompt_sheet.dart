import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';

class WeeklyPlanPromptSheet extends StatelessWidget {
  final bool weekComplete;
  final bool canGenerate;
  final DateTime? nextGenerationAt;

  const WeeklyPlanPromptSheet({
    super.key,
    required this.weekComplete,
    required this.canGenerate,
    this.nextGenerationAt,
  });

  static Future<bool?> show(
    BuildContext context, {
    required bool weekComplete,
    required bool canGenerate,
    DateTime? nextGenerationAt,
  }) =>
      showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        builder: (_) => FitnessTheme(
          child: WeeklyPlanPromptSheet(
            weekComplete: weekComplete,
            canGenerate: canGenerate,
            nextGenerationAt: nextGenerationAt,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final localNext = nextGenerationAt?.toLocal();
    final title =
        weekComplete ? 'Week complete.' : 'Your next week starts here.';
    final message = canGenerate
        ? weekComplete
            ? 'You finished the work you planned. Build a fresh week around your training.'
            : 'Your planner is ready when you are. Build a week around your goals and schedule.'
        : localNext == null
            ? 'Your next plan is not available yet. You can review your saved week in the planner.'
            : 'Your next plan is available on the date below. Your saved week is ready to review.';

    return Container(
      decoration: const BoxDecoration(
        color: DSColors.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.fromBorderSide(BorderSide(color: DSColors.borderHi)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: DSColors.accent.withValues(alpha: .12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DSColors.accent.withValues(alpha: .28),
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar_badge_plus,
                      color: DSColors.accent,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SETCRAFT  /  WEEKLY PLAN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DSColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                FitnessText(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DSColors.textPrimary,
                    fontSize: 27,
                    height: 1.12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 10),
                FitnessText(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DSColors.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (!canGenerate && localNext != null) ...[
                  const SizedBox(height: 14),
                  FitnessText(
                    'Next plan available {date}',
                    values: {
                      'date': MaterialLocalizations.of(context)
                          .formatFullDate(localNext),
                    },
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DSColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: canGenerate
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    icon: const Icon(CupertinoIcons.sparkles, size: 18),
                    label: const FitnessText('Generate weekly plan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: DSColors.accent,
                      foregroundColor: DSColors.onAccent,
                      disabledBackgroundColor: DSColors.bgRaised,
                      disabledForegroundColor: DSColors.muted,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: DSColors.muted,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const FitnessText('Not now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
