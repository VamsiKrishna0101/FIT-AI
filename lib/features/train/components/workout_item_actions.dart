import '../../../core/theme/ds_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/workout_exercise_models.dart';

/// Shared controls keep the list and form guide's status vocabulary identical.
class WorkoutItemActions extends StatelessWidget {
  final TodayPlanItemModel item;
  final bool busy;
  final String doneLabel;
  final VoidCallback onDone, onSkip, onUndo;
  const WorkoutItemActions(
      {super.key,
      required this.item,
      required this.busy,
      this.doneLabel = 'Done',
      required this.onDone,
      required this.onSkip,
      required this.onUndo});

  @override
  Widget build(BuildContext context) {
    String copy(String key) => fitnessText(context, key);
    final finished = !item.isPending;
    final fontFamily = DefaultTextStyle.of(context).style.fontFamily;
    final primary = finished
        ? Row(children: [
            Icon(
                item.isCompleted
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.arrow_turn_down_right,
                size: 18,
                color: const Color(0xFFBDBDBD)),
            const SizedBox(width: 7),
            Flexible(
                child: Text(copy(item.isCompleted ? 'Completed' : 'Skipped'),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFBDBDBD)))),
          ])
        : FilledButton(
            onPressed: busy ? null : onDone,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE2E2E2),
                foregroundColor: DSColors.bg,
                disabledBackgroundColor: const Color(0xFF373737),
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                textStyle: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  busy
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CupertinoActivityIndicator())
                      : Icon(
                          doneLabel == 'Done'
                              ? CupertinoIcons.checkmark
                              : CupertinoIcons.pencil,
                          size: 14),
                  const SizedBox(width: 5),
                  Flexible(
                      child: Text(copy(busy ? 'Saving' : doneLabel),
                          textAlign: TextAlign.center)),
                ]));
    final secondary = TextButton(
        onPressed: busy
            ? null
            : finished
                ? onUndo
                : onSkip,
        style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFBDBDBD),
            backgroundColor: const Color(0xFF2D2D2D),
            disabledBackgroundColor: const Color(0xFF262626),
            minimumSize: const Size(64, 36),
            side: const BorderSide(color: Color(0x12FFFFFF), width: .7),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: TextStyle(fontSize: 13, fontFamily: fontFamily),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
        child: busy && finished
            ? const CupertinoActivityIndicator()
            : Text(copy(finished ? 'Undo' : 'Skip'),
                textAlign: TextAlign.center));
    return LayoutBuilder(builder: (context, constraints) {
      // Large accessibility text needs full-width labels on narrow phones.
      if (constraints.maxWidth < 330 &&
          MediaQuery.textScalerOf(context).scale(13) > 17) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [primary, const SizedBox(height: 4), secondary]);
      }
      return Row(children: [
        if (finished) Expanded(child: primary) else Flexible(child: primary),
        const SizedBox(width: 8),
        Flexible(child: secondary)
      ]);
    });
  }
}
