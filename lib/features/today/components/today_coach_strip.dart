import 'package:setcraft/core/navigation/onboarding_page_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/components/liquid_glass_box.dart';
import '../../train/views/train_view.dart';

// MARK: - Ready to Push Liquid Glass Coach Strip (Card 3)
class TodayCoachStrip extends StatelessWidget {
  final String title;
  final String subtitle;

  const TodayCoachStrip({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      borderRadius: 28,
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          AppPageRoute(builder: (_) => const TrainView()),
        );
      },
      child: Row(
        children: [
          // Circular Glass Lightning Orb
          const LiquidOrbIcon(
            icon: CupertinoIcons.bolt_fill,
            iconColor: Colors.white,
            size: 38,
            iconSize: 18,
          ),

          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2.5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: -0.1,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Navigation Chevron
          Icon(
            CupertinoIcons.chevron_right,
            size: 13,
            color: Colors.white.withValues(alpha: 0.50),
          ),
        ],
      ),
    );
  }
}
