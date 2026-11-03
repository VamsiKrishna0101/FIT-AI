import 'package:flutter/material.dart';
import 'onboarding_copy.dart';
import '../../../core/theme/ds_motion.dart';

/// Reveal the message in a fixed layout, then expose all controls at once.
/// Assistive technology always receives whole sentences, never partial words.
class OnboardingQuestionReveal extends StatefulWidget {
  /// Reading pace is consistent across short questions and longer translations.
  static Duration durationFor(String text) =>
      Duration(milliseconds: (text.runes.length * 32).clamp(1000, 2000));
  final String title;
  final String? greeting;
  final String subtitle;
  final Widget child;
  final bool animate;
  final double controlsGap;
  const OnboardingQuestionReveal(
      {super.key,
      required this.title,
      this.greeting,
      this.subtitle = '',
      required this.child,
      this.animate = true,
      this.controlsGap = 28});
  @override
  State<OnboardingQuestionReveal> createState() =>
      _OnboardingQuestionRevealState();
}

class _OnboardingQuestionRevealState extends State<OnboardingQuestionReveal>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDuration();
    if (!widget.animate || DSMotion.reduced(context)) {
      _reveal.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _reveal.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingQuestionReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.greeting != widget.greeting ||
        oldWidget.subtitle != widget.subtitle) {
      _updateDuration();
      if (!widget.animate || DSMotion.reduced(context)) {
        _reveal.value = 1;
      } else {
        _reveal.forward(from: 0);
      }
    }
  }

  void _updateDuration() {
    _reveal.duration = OnboardingQuestionReveal.durationFor([
      if (widget.greeting != null) onboardingText(context, widget.greeting!),
      onboardingText(context, widget.title),
      onboardingText(context, widget.subtitle),
    ].join());
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = widget.greeting == null
        ? ''
        : onboardingText(context, widget.greeting!);
    final title = onboardingText(context, widget.title);
    final subtitle = onboardingText(context, widget.subtitle);
    final total =
        greeting.runes.length + title.runes.length + subtitle.runes.length;
    return AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) {
          final count = (total * _reveal.value).ceil();
          Widget text(String value, int start, TextStyle style,
              {bool heading = false}) {
            final runes = value.runes.toList();
            final visible = (count - start).clamp(0, runes.length).toInt();
            return Semantics(
                label: value,
                header: heading,
                child: ExcludeSemantics(
                  child: Text.rich(TextSpan(style: style, children: [
                    TextSpan(text: String.fromCharCodes(runes.take(visible))),
                    TextSpan(
                        text: String.fromCharCodes(runes.skip(visible)),
                        style: style.copyWith(color: Colors.transparent)),
                  ])),
                ));
          }

          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (greeting.isNotEmpty) ...[
                  text(
                      greeting,
                      0,
                      const TextStyle(
                          fontSize: 16,
                          height: 1.45,
                          color: Color(0xFFC7C7CB),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                ],
                text(
                    title,
                    greeting.runes.length,
                    const TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.8,
                        height: 1.16,
                        color: Colors.white),
                    heading: true),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  text(
                      subtitle,
                      greeting.runes.length + title.runes.length,
                      const TextStyle(
                          fontSize: 14, height: 1.5, color: Color(0xFF9D9DA1))),
                ],
                SizedBox(height: widget.controlsGap),
                Visibility(
                    visible: _reveal.value == 1,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: widget.child),
              ]);
        });
  }
}
