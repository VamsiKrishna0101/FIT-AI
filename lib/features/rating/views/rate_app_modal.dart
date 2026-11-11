import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../profile/repositories/support_repository.dart';
import '../services/rate_app_service.dart';

/// Premium Monochrome Rate Our App Sheet.
/// Adheres to pure black OLED styling, obsidian glass borders, and high-contrast typography.
class RateAppModal extends StatefulWidget {
  const RateAppModal({super.key});

  /// Displays the modal bottom sheet using standard motion curves.
  static Future<bool?> show(BuildContext context) =>
      showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        builder: (_) => const FitnessTheme(
          child: RateAppModal(),
        ),
      );

  @override
  State<RateAppModal> createState() => _RateAppModalState();
}

class _RateAppModalState extends State<RateAppModal> {
  int _selectedRating = 0;
  final bool _submittedFeedback = false;
  bool _isSending = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _onStarSelected(int rating) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedRating = rating;
    });
  }

  Future<void> _handlePrimaryAction() async {
    HapticFeedback.mediumImpact();

    final text = _feedbackController.text.trim();
    if (text.isNotEmpty) {
      setState(() => _isSending = true);
      try {
        final support = SupportRepository();
        await support.create({
          'subject': 'In-App Rating Feedback ($_selectedRating/5)',
          'category': 'OTHER',
          'message': text,
        });
      } catch (_) {
        // Even if network ticket submission fails, user intent is honored
      }
    }

    // Always direct user to the store without review gating (Apple Guideline 5.6.1)
    await RateAppService.shared.openReviewUrl();
    await RateAppService.shared.recordUserRated();
    if (mounted) {
      setState(() => _isSending = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0x2EFFFFFF), width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Badge (Obsidian Monochrome)
                  Center(
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x28FFFFFF),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.04),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _submittedFeedback
                            ? CupertinoIcons.checkmark_alt
                            : _selectedRating >= 4
                                ? CupertinoIcons.star_fill
                                : _selectedRating > 0
                                    ? CupertinoIcons.chat_bubble_text_fill
                                    : CupertinoIcons.star_fill,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Sub-heading tag
                  const Text(
                    'SETCRAFT  /  COMMUNITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DSColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _submittedFeedback
                          ? 'Thank you for your feedback.'
                          : _selectedRating >= 4
                              ? 'We appreciate your support.'
                              : _selectedRating > 0
                                  ? 'How can we improve?'
                                  : 'Enjoying Setcraft?',
                      key: ValueKey('title_$_selectedRating$_submittedFeedback'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle / Description
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _submittedFeedback
                          ? 'Your suggestions directly shape our next engineering and intelligence releases.'
                          : _selectedRating >= 4
                              ? 'A quick rating on the store helps independent fitness development and supports our continuous updates.'
                              : _selectedRating > 0
                                  ? 'Tell us what feels missing or could be better. We review every note to elevate your training.'
                                  : 'Your rating helps us craft superior AI workouts, biometric insights, and recovery intelligence.',
                      key: ValueKey('sub_$_selectedRating$_submittedFeedback'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DSColors.muted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5-Star Monochrome Rating Selector
                  if (!_submittedFeedback) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNumber = index + 1;
                        final isFilled = starNumber <= _selectedRating;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onStarSelected(starNumber),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 8,
                            ),
                            child: AnimatedScale(
                              scale: isFilled ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                isFilled
                                    ? CupertinoIcons.star_fill
                                    : CupertinoIcons.star,
                                color: isFilled
                                    ? Colors.white
                                    : const Color(0x38FFFFFF),
                                size: 34,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // Optional In-App Feedback Field
                    if (_selectedRating > 0) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x22FFFFFF),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: TextField(
                          controller: _feedbackController,
                          maxLines: 2,
                          cursorColor: Colors.white,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Share ideas or feedback with our team (optional)',
                            hintStyle: TextStyle(
                              color: Color(0x59FFFFFF),
                              fontSize: 13,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Primary Action Button (Always direct store access - Guideline 5.6.1)
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isSending ? null : _handlePrimaryAction,
                        icon: _isSending
                            ? const CupertinoActivityIndicator(color: Colors.black)
                            : const Icon(
                                CupertinoIcons.arrow_up_right,
                                size: 18,
                                color: Colors.black,
                              ),
                        label: Text(
                          _selectedRating > 0 ? 'Rate on Store' : 'Rate Setcraft',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF2A2A2A),
                          disabledForegroundColor: DSColors.muted,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    // Secondary Action ("Remind me in 30 days")
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        RateAppService.shared.recordPromptShown();
                        Navigator.of(context).pop(false);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0x8CFFFFFF),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text(
                        'Remind me in 30 days',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
