import 'onboarding_copy.dart';
import 'dart:async';
import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import 'onboarding_question_reveal.dart';
import '../../../core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/theme/fitness_theme.dart';
import 'onboarding_chrome.dart';

/// One question at a time, with persistent controls for forms and multi-select.
class OnboardingScaffold extends StatelessWidget {
  final int step, totalSteps, part, parts;
  final String title, subtitle, actionTitle, sectionLabel;
  final List<Widget> children;
  final VoidCallback? onBack;
  final FutureOr<void> Function()? onContinue;
  final bool loading, showProgress, canPop, showContinue, catalogue;
  final bool? animateQuestion;
  final Widget? bottomAccessory;
  final ScrollController? scrollController;
  final String? footer, actionMessage, greeting, previousAnswer;
  final Widget? secondaryAction, header;
  const OnboardingScaffold(
      {super.key,
      required this.step,
      required this.sectionLabel,
      this.totalSteps = 8,
      required this.title,
      required this.subtitle,
      required this.actionTitle,
      required this.children,
      this.onBack,
      this.onContinue,
      this.loading = false,
      this.showProgress = true,
      this.part = 0,
      this.parts = 1,
      this.canPop = true,
      this.secondaryAction,
      this.header,
      this.actionMessage,
      this.footer,
      this.greeting,
      this.previousAnswer,
      this.showContinue = true,
      this.catalogue = false,
      this.animateQuestion,
      this.bottomAccessory,
      this.scrollController});
  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
            statusBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light),
        child: PopScope(
            canPop: canPop,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) onBack?.call();
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                  child: Center(
                      child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!catalogue)
                        OnboardingTopBar(
                            currentStep: step,
                            totalSteps: totalSteps,
                            sectionLabel: sectionLabel,
                            part: part,
                            parts: parts,
                            onBack: onBack),
                      Expanded(
                          child: KeyedSubtree(
                        key: ValueKey('onboarding-page-$step-$part'),
                        child: ListView(
                          key: const ValueKey('onboarding-scroll'),
                          controller: scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: catalogue
                              ? const EdgeInsets.only(bottom: 16)
                              : const EdgeInsets.fromLTRB(24, 24, 24, 20),
                          children: [
                            if (catalogue) ...[
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 16, 16, 0),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: Semantics(
                                                header: true,
                                                child: Text(
                                                    onboardingText(
                                                        context, title),
                                                    style: const TextStyle(
                                                        fontSize: 26,
                                                        height: 1.2,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: -.8)))),
                                        if (onBack != null)
                                          IconButton(
                                              tooltip: MaterialLocalizations.of(
                                                      context)
                                                  .backButtonTooltip,
                                              onPressed: onBack,
                                              icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 20,
                                                  color: FitnessTheme.muted)),
                                      ])),
                              if (subtitle.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 16, 24, 0),
                                    child: Text(
                                        onboardingText(context, subtitle),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: FitnessTheme.muted))),
                              const SizedBox(height: 24),
                              IgnorePointer(
                                  ignoring: loading,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: children)),
                            ] else ...[
                              const SizedBox(height: 36),
                              const Align(
                                  alignment: Alignment.centerLeft,
                                  child: ExcludeSemantics(
                                      child: OnboardingCoachIndicator())),
                              const SizedBox(height: 22),
                              OnboardingQuestionReveal(
                                key: ValueKey('question-$step-$part'),
                                title: title,
                                greeting: greeting,
                                subtitle: subtitle,
                                animate: animateQuestion ?? greeting != null,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (header != null) ...[
                                        header!,
                                        const SizedBox(height: 20)
                                      ],
                                      IgnorePointer(
                                          ignoring: loading,
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: children)),
                                    ]),
                              ),
                            ],
                          ],
                        ),
                      )),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            24, showContinue ? 10 : 0, 24, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (actionMessage != null) ...[
                              Semantics(
                                  liveRegion: true,
                                  child: FitnessText(actionMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: Color(0xFFE0B7B7)))),
                              const SizedBox(height: 10),
                            ],
                            if (bottomAccessory != null) ...[
                              bottomAccessory!,
                              const SizedBox(height: 12)
                            ],
                            if (showContinue)
                              OnboardingContinueButton(
                                  title: actionTitle,
                                  onPressed: onContinue,
                                  loading: loading),
                            if (secondaryAction != null) secondaryAction!,
                            if (footer != null &&
                                MediaQuery.viewInsetsOf(context).bottom ==
                                    0) ...[
                              const SizedBox(height: 10),
                              Text(onboardingText(context, footer!),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.4,
                                      color: Color(0xFF818186))),
                            ],
                          ],
                        ),
                      ),
                    ]),
              ))),
            )),
      ));
}

class OnboardingCoachIndicator extends StatelessWidget {
  const OnboardingCoachIndicator({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 13,
        height: 13,
        decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFB0B0B5)]),
            boxShadow: [
              BoxShadow(
                  color: Color(0x35FFFFFF), blurRadius: 16, spreadRadius: 4)
            ]),
      );
}

/// Keeps the action locked through both saves and local question transitions.
class OnboardingContinueButton extends StatefulWidget {
  final String title;
  final FutureOr<void> Function()? onPressed;
  final bool loading;
  const OnboardingContinueButton(
      {super.key, required this.title, this.onPressed, this.loading = false});

  @override
  State<OnboardingContinueButton> createState() =>
      _OnboardingContinueButtonState();
}

class _OnboardingContinueButtonState extends State<OnboardingContinueButton> {
  bool _working = false;
  Timer? _transitionTimer;
  Completer<void>? _transitionDone;

  @override
  void dispose() {
    _transitionTimer?.cancel();
    final transition = _transitionDone;
    if (transition != null && !transition.isCompleted) transition.complete();
    super.dispose();
  }

  Future<void> _continue() async {
    final action = widget.onPressed;
    if (_working || widget.loading || action == null) return;
    final duration = DSMotion.duration(context, DSMotion.pageTransition);
    setState(() => _working = true);
    try {
      // Render the disabled state before work begins, including synchronous steps.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final transition = Completer<void>();
      _transitionDone = transition;
      _transitionTimer = Timer(duration, transition.complete);
      try {
        await action();
      } finally {
        await transition.future;
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => LiquidChromeButton(
      title: widget.title,
      loadingTitle: 'Continuing…',
      pill: true,
      solid: true,
      showArrow: false,
      isLoading: _working || widget.loading,
      onPressed: _working || widget.loading || widget.onPressed == null
          ? null
          : _continue);
}

/// Content-sized answer bubbles with bounded wrapping and a shared right edge.
class OnboardingChoice extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  const OnboardingChoice(
      {super.key,
      required this.title,
      this.subtitle,
      this.leading,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  minWidth: constraints.maxWidth.clamp(0.0, 112.0).toDouble()),
              child: IntrinsicWidth(
                  child: Semantics(
                button: true,
                selected: selected,
                child: MotionPress(
                    child: AnimatedContainer(
                  duration: DSMotion.duration(context, DSMotion.selection),
                  curve: DSMotion.effects,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: selected
                            ? const [Color(0xFF38383B), Color(0xFF303033)]
                            : const [Color(0xFF262629), Color(0xFF202023)]),
                    borderRadius:
                        BorderRadius.circular(subtitle == null ? 32 : 24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.white.withValues(alpha: .04),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap();
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 16),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (leading != null) ...[
                              leading!,
                              const SizedBox(width: 12)
                            ],
                            Flexible(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  FitnessText(title,
                                      style: const TextStyle(
                                          color: Color(0xFFF3F3F5),
                                          fontSize: 18,
                                          height: 1.3,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -.25)),
                                  if (subtitle != null &&
                                      subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    FitnessText(subtitle!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFA5A5AA),
                                            height: 1.4)),
                                  ],
                                ])),
                          ]),
                        ),
                      ),
                    ),
                  ),
                )),
              )),
            ),
          ));
}

/// Keeps existing educational artwork in the onboarding's silver palette.
class OnboardingMonochrome extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const OnboardingMonochrome(
      {super.key, required this.child, this.enabled = true});
  @override
  Widget build(BuildContext context) => !enabled
      ? child
      : ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            .2126,
            .7152,
            .0722,
            0,
            0,
            .2126,
            .7152,
            .0722,
            0,
            0,
            .2126,
            .7152,
            .0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child);
}
