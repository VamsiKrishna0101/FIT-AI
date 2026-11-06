import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';

class UpdateStatsCard extends StatelessWidget {
  final VoidCallback onPressed;
  const UpdateStatsCard({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
      key: const ValueKey('today-update-stats-card'),
      width: double.infinity,
      child: FilledButton(
          key: const ValueKey('today-update-stats-button'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: DSColors.silver,
              foregroundColor: DSColors.bg,
              minimumSize: const Size.fromHeight(54),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: Row(children: [
            Expanded(
                child: Text(fitnessText(context, 'Update your stats'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500))),
            const SizedBox(width: 12),
            const Icon(CupertinoIcons.chevron_right,
                size: 13, color: DSColors.bg),
          ])));
}
