import '../theme/ds_motion.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Setcraft Premium Toast System
//
// Usage:
//   FitToast.show(context, message: 'Please enter your name.');
//
// Features:
//   • Slides up from the bottom with a spring-overshoot curve
//   • Swipeable — drag or fling downward to dismiss
//   • Auto-dismisses after [duration] with a draining progress bar
//   • Pure white frosted glass — Apple iOS notification aesthetic
// ─────────────────────────────────────────────────────────────────────────────

class FitToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_rounded,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _FitToastWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismissed: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    overlay.insert(entry);
    _current = entry;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Toast Widget (handles animation + gesture)
// ─────────────────────────────────────────────────────────────────────────────
class _FitToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _FitToastWidget({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_FitToastWidget> createState() => _FitToastWidgetState();
}

class _FitToastWidgetState extends State<_FitToastWidget>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _progressCtrl;
  bool _started = false;

  double _dragOffset = 0.0;
  bool _isDismissing = false;

  static const double _dismissThreshold = 60.0;
  static const double _velocityThreshold = 400.0;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: DSMotion.feedback,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve: DSMotion.effects,
    ));

    _progressCtrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      animationBehavior: AnimationBehavior.preserve,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _slideCtrl.duration = DSMotion.duration(context, DSMotion.feedback);
    _slideCtrl.forward().then((_) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _progressCtrl.forward().then((_) {
        if (mounted) _dismiss();
      });
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted || _isDismissing) return;
    _isDismissing = true;
    _progressCtrl.stop();
    _slideCtrl
        .animateBack(
          0.0,
          duration: DSMotion.duration(context, DSMotion.selection),
          curve: Curves.easeInCubic,
        )
        .then((_) => widget.onDismissed());
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_isDismissing) return;
    if (d.delta.dy > 0) {
      setState(() => _dragOffset += d.delta.dy);
      if (_progressCtrl.isAnimating) _progressCtrl.stop();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (_isDismissing) return;
    final velocity = d.velocity.pixelsPerSecond.dy;
    if (_dragOffset > _dismissThreshold || velocity > _velocityThreshold) {
      HapticFeedback.selectionClick();
      _dismiss();
    } else {
      setState(() => _dragOffset = 0.0);
      if (!_progressCtrl.isCompleted) _progressCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: GestureDetector(
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
              child: _ToastCard(
                message: widget.message,
                icon: widget.icon,
                progressCtrl: _progressCtrl,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Toast Card Visual
// ─────────────────────────────────────────────────────────────────────────────
class _ToastCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final AnimationController progressCtrl;

  const _ToastCard({
    required this.message,
    required this.icon,
    required this.progressCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon pill — dark on white
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F0F0F),
                          letterSpacing: -0.2,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Draining progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: AnimatedBuilder(
                    animation: progressCtrl,
                    builder: (_, __) => LinearProgressIndicator(
                      value: DSMotion.reduced(context)
                          ? 1
                          : 1.0 - progressCtrl.value,
                      backgroundColor:
                          const Color(0xFF0F0F0F).withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F0F0F),
                      ),
                      minHeight: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
