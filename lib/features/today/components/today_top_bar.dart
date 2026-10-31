import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/components/liquid_glass_box.dart';
import '../../../core/theme/ds_colors.dart';
import '../../profile/views/profile_view.dart';

// MARK: - Silver Liquid Glass Top Bar
class TodayTopBar extends StatelessWidget {
  final String userName;
  final int streakDays;

  const TodayTopBar({
    super.key,
    required this.userName,
    this.streakDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d • EEEE').format(now).toUpperCase();
    final trimmedName = userName.trim();
    final firstName = trimmedName.isEmpty
        ? 'ATHLETE'
        : trimmedName.split(RegExp(r'\s+')).first.toUpperCase();
    final initial = trimmedName.isEmpty ? 'A' : trimmedName[0].toUpperCase();
    final streak = streakDays > 0 ? streakDays : 1;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: Date & Name ──────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                    color: Colors.white.withValues(alpha: 0.52),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    LiquidGlassPill(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const FitnessText(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Right: Streak & Avatar ─────────────────────────────────
          LiquidGlassPill(
            borderRadius: 22,
            isElevated: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.flame_fill,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  '$streak ${streak == 1 ? "DAY" : "DAYS"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                AppPageRoute(builder: (_) => const ProfileView()),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: DSColors.specularBorder,
              ),
              padding: const EdgeInsets.all(0.8),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: DSColors.glassControlGradient,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
