import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_motion.dart';
import 'coach_mascot.dart';
import 'onboarding_coach.dart';
import 'welcome_buddies.dart';

/// Mochi with a chat bubble: a brief "typing" beat, then the line.
///
/// In onboarding ([hero]) Mochi greets the user by name once, answers each
/// choice with a quick reply, and both Mochi and the bubble stay crisp in
/// place while the step below dissolves into the next.
class CoachSpeech extends StatefulWidget {
  final String text;

  /// Values for placeholders in [text], such as `{amount}`.
  final Map<String, Object> values;
  final CoachMood mood;
  final double mascotSize;

  /// Onboarding steps share one Mochi and bubble; screens inside the app keep
  /// theirs in place, since a screen may show more than one note.
  final bool hero;

  /// A buddy that joins Mochi on the steps it relates to.
  final BuddyKind? buddy;
  const CoachSpeech(
      {super.key,
      required this.text,
      this.values = const {},
      this.mood = CoachMood.listening,
      this.mascotSize = 58,
      this.hero = true,
      this.buddy});

  static const bubbleTag = 'onboarding-coach-bubble';

  @override
  State<CoachSpeech> createState() => _CoachSpeechState();
}

class _CoachSpeechState extends State<CoachSpeech>
    with TickerProviderStateMixin {
  late final _dots = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final _clock = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6000));
  late final _buddyPop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  bool _typing = false, _talking = false;
  String? _line;
  Map<String, Object> _values = const {};
  Timer? _beat, _reply;

  bool get _live => OnboardingCoach.liveMotion && !DSMotion.reduced(context);

  @override
  void initState() {
    super.initState();
    if (widget.hero) OnboardingCoach.reactions.addListener(_onChoice);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speak();
      _showBuddy();
    });
  }

  @override
  void didUpdateWidget(CoachSpeech oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        !mapEquals(oldWidget.values, widget.values)) {
      _speak();
    }
    if (oldWidget.buddy != widget.buddy) _showBuddy();
  }

  void _showBuddy() {
    if (!mounted) return;
    if (widget.buddy == null) {
      _clock.stop();
      _buddyPop.value = 0;
    } else if (!_live) {
      _buddyPop.value = 1;
    } else {
      _clock.repeat();
      _buddyPop.forward(from: 0);
    }
  }

  void _say(String line, [Map<String, Object> values = const {}]) {
    _dots.stop();
    setState(() {
      _typing = false;
      _talking = true;
      _line = line;
      _values = values;
    });
  }

  void _type(Duration delay, VoidCallback then) {
    setState(() => _typing = true);
    _dots.repeat();
    _beat = Timer(delay, () => mounted ? then() : null);
  }

  void _speak() {
    _beat?.cancel();
    _reply?.cancel();
    if (!mounted || widget.text.isEmpty) return;
    if (!_live) {
      setState(() {
        _typing = false;
        _line = null;
      });
      return;
    }
    final name = widget.hero ? OnboardingCoach.takeGreeting() : null;
    void sayLine() {
      _say(widget.text, widget.values);
      _beat = Timer(const Duration(milliseconds: 1400),
          () => mounted ? setState(() => _talking = false) : null);
    }

    _type(const Duration(milliseconds: 650), () {
      if (name == null) return sayLine();
      _say('Nice to meet you, {name}! 👋', {'name': name});
      _beat = Timer(const Duration(milliseconds: 1900),
          () => mounted ? _type(const Duration(milliseconds: 450), sayLine) : null);
    });
  }

  /// A quick reply to each choice, then back to the step's own line.
  void _onChoice() {
    if (!mounted || !_live || _typing || widget.text.isEmpty) return;
    _reply?.cancel();
    const replies = OnboardingCoach.replies;
    _say(replies[OnboardingCoach.reactions.value % replies.length]);
    _reply = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _typing) return;
      setState(() {
        _talking = false;
        _line = null;
        _values = const {};
      });
    });
  }

  @override
  void dispose() {
    OnboardingCoach.reactions.removeListener(_onChoice);
    _beat?.cancel();
    _reply?.cancel();
    _dots.dispose();
    _clock.dispose();
    _buddyPop.dispose();
    super.dispose();
  }

  Widget _bubble(Widget child) => Container(
      key: const ValueKey('coach-bubble'),
      // Two lines tall on every step, so the question below and Mochi's spot
      // never shift between screens.
      constraints: const BoxConstraints(minHeight: 62),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: const BoxDecoration(
          color: Color(0xFF1B1B1F),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(5))),
      child: child);

  @override
  Widget build(BuildContext context) {
    final duration = DSMotion.duration(context, DSMotion.pageTransition);
    Widget mascot = CoachMascot(
        size: widget.mascotSize, mood: widget.mood, talking: _talking);
    if (widget.hero) mascot = CoachHero(child: mascot);
    final buddy = widget.buddy;
    if (buddy != null) {
      mascot = Stack(clipBehavior: Clip.none, children: [
        mascot,
        Positioned(
            right: -widget.mascotSize * .58,
            bottom: -2,
            child: ScaleTransition(
                scale: CurvedAnimation(
                    parent: _buddyPop, curve: Curves.elasticOut),
                child: WelcomeBuddy(
                    key: ValueKey('coach-buddy-${buddy.name}'),
                    kind: buddy,
                    size: widget.mascotSize * .62,
                    clock: _clock))),
      ]);
    }
    Widget? bubble;
    if (widget.text.isNotEmpty) {
      bubble = _bubble(
          // A cross-fade, not AnimatedSize: the bubble's minimum height
          // absorbs the change, and AnimatedSize asserts under intrinsic
          // layouts such as the welcome screen.
          AnimatedSwitcher(
              duration: duration,
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.centerLeft, children: [
                    ...previous,
                    if (current != null) current,
                  ]),
              child: _typing
                  ? _TypingDots(animation: _dots)
                  : FitnessText(_line ?? widget.text,
                      key: ValueKey('${_line ?? widget.text}$_values'),
                      values: _line == null ? widget.values : _values,
                      style: CoachType.line())));
      if (widget.hero) {
        // Between steps the bubble stays put and "types" the next line.
        bubble = Hero(
            tag: CoachSpeech.bubbleTag,
            flightShuttleBuilder: (context, animation, direction, from, to) =>
                Material(
                    type: MaterialType.transparency,
                    child: _bubble(_TypingDots(animation: animation))),
            child: bubble);
      }
      bubble = TweenAnimationBuilder<double>(
          tween: Tween(begin: _live ? 0 : 1, end: 1),
          duration: duration,
          curve: DSMotion.effects,
          builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.scale(
                  scale: .9 + .1 * v,
                  alignment: Alignment.bottomLeft,
                  child: child)),
          child: bubble);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      mascot,
      SizedBox(width: buddy == null ? 8 : 8 + widget.mascotSize * .55),
      Expanded(child: bubble ?? const SizedBox.shrink()),
    ]);
  }
}

class _TypingDots extends StatelessWidget {
  final Animation<double> animation;
  const _TypingDots({required this.animation});
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 20,
      width: 38,
      child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 3; i++)
                  Transform.translate(
                      offset: Offset(
                          0,
                          -3 *
                              math.sin(((animation.value - i * .18) % 1) *
                                      math.pi)
                                  .clamp(0.0, 1.0)),
                      child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xFF8A8A92),
                              shape: BoxShape.circle))),
              ])));
}
