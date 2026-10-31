import 'dart:async';
import '../../../core/theme/ds_motion.dart';
import '../../../core/components/motion.dart';
import '../../../core/components/content_transition.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/theme/fitness_theme.dart';
import 'onboarding_chrome.dart';

/// One scrollable content region and one reachable action across every step.
class OnboardingScaffold extends StatelessWidget {
  final int step, totalSteps;
  final String title, subtitle, actionTitle, sectionLabel;
  final List<Widget> children;
  final VoidCallback? onBack;
  final FutureOr<void> Function()? onContinue;
  final bool loading;
  final bool showProgress;
  final int part, parts;
  final bool canPop;
  final String? footer;
  final String? actionMessage;
  final Widget? secondaryAction;
  final Widget? header;
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
      this.footer});
  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
              statusBarColor: FitnessTheme.canvas,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: FitnessTheme.canvas,
              systemNavigationBarIconBrightness: Brightness.light),
          child: PopScope(
              canPop: canPop,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) onBack?.call();
              },
              child: Scaffold(
                backgroundColor: FitnessTheme.canvas,
                resizeToAvoidBottomInset: true,
                body: SafeArea(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      if (showProgress)
                        OnboardingTopBar(
                            currentStep: step,
                            totalSteps: totalSteps,
                            sectionLabel: sectionLabel,
                            part: part,
                            parts: parts,
                            onBack: onBack)
                      else
                        Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: onBack == null
                                    ? const SizedBox(height: 44)
                                    : OnboardingBackButton(
                                        onPressed: onBack!))),
                      Expanded(
                          child: ContentTransition(
                              child: KeyedSubtree(
                                  key: ValueKey('onboarding-page-$step-$part'),
                                  child: ListView(
                                      key: const ValueKey('onboarding-scroll'),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: const EdgeInsets.fromLTRB(
                                          24, 32, 24, 28),
                                      children: [
                                        if (header != null) ...[
                                          header!,
                                          const SizedBox(height: 24)
                                        ],
                                        if (sectionLabel.isNotEmpty) ...[
                                          FitnessText(sectionLabel,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  letterSpacing: 1.6,
                                                  color: Color(0xFF969696),
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 13),
                                        ],
                                        FitnessText(title,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -.8,
                                                height: 1.18)),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 14),
                                          FitnessText(subtitle,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  color: FitnessTheme.muted,
                                                  height: 1.45)),
                                        ],
                                        const SizedBox(height: 28),
                                        ...children
                                      ])))),
                      Container(
                          decoration:
                              const BoxDecoration(color: FitnessTheme.canvas),
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
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
                            OnboardingContinueButton(
                                title: actionTitle,
                                onPressed: onContinue,
                                loading: loading),
                            if (secondaryAction != null) secondaryAction!,
                            if (footer != null &&
                                MediaQuery.viewInsetsOf(context).bottom ==
                                    0) ...[
                              const SizedBox(height: 10),
                              FitnessText(footer!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11, color: FitnessTheme.muted))
                            ],
                          ])),
                    ])),
              ))));
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
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      child: TweenAnimationBuilder<double>(
          tween: Tween(begin: selected ? 1 : 0, end: selected ? 1 : 0),
          duration: DSMotion.duration(context, DSMotion.selection),
          curve: DSMotion.effects,
          builder: (context, value, _) => MotionPress(
              child: Material(
                  animationDuration: Duration.zero,
                  color: Color.lerp(
                      FitnessTheme.surface, const Color(0xFFF4F4F4), value),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: Color.lerp(const Color(0xFF303030),
                              const Color(0xFFF4F4F4), value)!,
                          width: .8)),
                  child: InkWell(
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap();
                    },
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Row(children: [
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: 16)
                          ],
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                FitnessText(title,
                                    style: TextStyle(
                                        color: Color.lerp(
                                            Colors.white, Colors.black, value),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -.2)),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 5),
                                  FitnessText(subtitle!,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color.lerp(FitnessTheme.muted,
                                              const Color(0xFF4B4B4B), value),
                                          height: 1.4))
                                ],
                              ])),
                          const SizedBox(width: 12),
                          MotionFeedback(
                              child: Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: Color.lerp(const Color(0xFF606060),
                                      Colors.black, value),
                                  key: ValueKey(selected),
                                  size: 20))
                        ])),
                  )))));
}
