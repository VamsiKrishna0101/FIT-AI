import 'motion.dart';
import '../theme/ds_colors.dart';
import '../localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared satin silver action, sized by content at larger text settings.
class LiquidChromeButton extends StatefulWidget {
  final String title;
  final VoidCallback? onPressed;
  final double height;
  final bool isLoading, showArrow;
  const LiquidChromeButton(
      {super.key,
      required this.title,
      required this.onPressed,
      this.height = 54,
      this.isLoading = false,
      this.showArrow = true});
  @override
  State<LiquidChromeButton> createState() => _LiquidChromeButtonState();
}

class _LiquidChromeButtonState extends State<LiquidChromeButton> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: fitnessText(context, widget.title),
      child: MotionPress(
          enabled: enabled,
          child: Opacity(
            opacity: enabled || widget.isLoading ? 1 : .38,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: enabled
                      ? () {
                          HapticFeedback.lightImpact();
                          widget.onPressed!();
                        }
                      : null,
                  child: Ink(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFF0F0F0), Color(0xFFCDCDCD)]),
                          border: Border.all(
                              color: const Color(0xFFF4F4F4), width: .6)),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: widget.height),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.isLoading)
                                    const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: DSColors.bg))
                                  else ...[
                                    Expanded(
                                        child: FitnessText(widget.title,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                color: DSColors.bg,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -.3))),
                                    if (widget.showArrow)
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 20, color: DSColors.bg),
                                  ],
                                ])),
                      )),
                )),
          )),
    );
  }
}
