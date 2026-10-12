import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/components/liquid_glass_box.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_typography.dart';

// MARK: - Compact Personalized Coaching Note
class AiTargetCard extends StatelessWidget {
  final String? aiTarget;

  const AiTargetCard({super.key, required this.aiTarget});

  @override
  Widget build(BuildContext context) {
    final rawTarget = aiTarget?.trim() ?? '';
    final effort = RegExp(
      r'^Target Effort:\s*([\d.]+\s*/\s*10)(?:\s*\(([^)]+)\))?\s*(?:—\s*(.*))?$',
      caseSensitive: false,
    ).firstMatch(rawTarget);
    final effortValue = effort?.group(1)?.replaceAll(RegExp(r'\s+'), ' ');
    final phase = effort?.group(2)?.trim();
    final suppliedNote = effort?.group(3)?.trim() ?? '';
    final note = suppliedNote.isNotEmpty ? suppliedNote : rawTarget;
    if (note.isEmpty) return const SizedBox.shrink();

    return LiquidGlassBox(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LiquidOrbIcon(
                icon: CupertinoIcons.sparkles,
                iconColor: Colors.white,
                size: 31,
                iconSize: 15,
              ),
              const SizedBox(width: 8),
              Text(
                'Your AI target',
                style: DSTypography.cardTitle.copyWith(
                  fontSize: 15,
                  color: DSColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (effortValue != null)
                _EffortGlassPill(value: effortValue, phase: phase),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: DSTypography.body.copyWith(
              fontSize: 12.5,
              color: DSColors.textSecondary,
              letterSpacing: -0.12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EffortGlassPill extends StatelessWidget {
  final String value;
  final String? phase;

  const _EffortGlassPill({required this.value, this.phase});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: DSColors.glassControlGradient,
        border: Border.all(color: DSColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.scope,
            size: 13,
            color: Colors.white.withValues(alpha: 0.78),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.15,
            ),
          ),
          if (phase != null && phase!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Container(
              width: 1,
              height: 12,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 5),
            Text(
              phase!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
