import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';

Future<bool> confirmRoutineDeletion(BuildContext context, String name) async =>
    await showDialog<bool>(
        context: context,
        animationStyle: DSMotion.dialogStyle(context),
        builder: (context) => AlertDialog(
                title: Text(fitnessText(context, 'Delete workout?')),
                content: Text(name),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(fitnessText(context, 'Cancel'))),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(fitnessText(context, 'Delete'))),
                ])) ==
    true;

class SavedRoutineTile extends StatelessWidget {
  final Map<String, dynamic> routine;
  final VoidCallback? onOpen, onDelete;
  const SavedRoutineTile(
      {super.key, required this.routine, this.onOpen, this.onDelete});

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(routine['name'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(
                      fitnessText(
                          context,
                          routine['count'] == 1
                              ? '{count} exercise'
                              : '{count} exercises',
                          values: {'count': routine['count'] as num}),
                      style: const TextStyle(
                          fontSize: 12, color: DSColors.muted, height: 1.4)),
                ])),
            if (onDelete != null)
              IconButton(
                  tooltip: fitnessText(context, 'Delete workout'),
                  onPressed: onDelete,
                  icon: const Icon(CupertinoIcons.minus_circle,
                      size: 20, color: DSColors.coral))
            else
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(CupertinoIcons.chevron_right,
                      size: 12, color: DSColors.muted)),
          ])));
}
