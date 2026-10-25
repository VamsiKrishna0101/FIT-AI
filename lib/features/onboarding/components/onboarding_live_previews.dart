import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../body_scan/views/widgets/anatomical_training_map.dart';

/// Summarizes frequency without inventing or saving particular weekdays.
class OnboardingFrequencyPreview extends StatelessWidget {
  final int? frequency;
  const OnboardingFrequencyPreview({super.key, required this.frequency});

  @override
  Widget build(BuildContext context) {
    final count = frequency?.clamp(0, 6) ?? 0;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale).format(count);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: FitnessText('Training days',
                  style: TextStyle(fontSize: 12, color: FitnessTheme.muted))),
          Text(frequency == null ? '—' : '$number${count == 6 ? '+' : ''}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DSColors.silver)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (var day = 0; day < 7; day++) ...[
            if (day > 0) const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                selected: day < count,
                child: AnimatedContainer(
                  key: ValueKey('onboarding-frequency-segment-$day'),
                  duration: DSMotion.duration(context, DSMotion.selection),
                  curve: DSMotion.snappy,
                  height: 6,
                  decoration: BoxDecoration(
                    color: day < count ? DSColors.silver : DSColors.bgRaised,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 9),
        const FitnessText('Choose your exact days later.',
            style: TextStyle(
                fontSize: 11, color: FitnessTheme.muted, height: 1.4)),
      ]),
    );
  }
}

/// Two cached vector illustrations. Only their selected-region colors animate.
class OnboardingMusclePreview extends StatefulWidget {
  final Set<String> selected;
  final bool female;
  final double height;
  final ValueChanged<String>? onSelected;
  const OnboardingMusclePreview(
      {super.key,
      required this.selected,
      this.female = false,
      this.height = 128,
      this.onSelected});
  @override
  State<OnboardingMusclePreview> createState() =>
      _OnboardingMusclePreviewState();
}

class _OnboardingMusclePreviewState extends State<OnboardingMusclePreview>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: DSMotion.selection, value: 1);
  Map<String, Color> _from = {}, _to = {};
  static const _neutral = Color(0xFF505050);
  static const _selected = Color(0xFFD56B55);

  Map<String, Color> get _colors => {
        for (final id in const [
          'chest',
          'shoulders',
          'biceps',
          'triceps',
          'forearms',
          'upper_back',
          'lats',
          'lower_back',
          'core',
          'glutes',
          'quads',
          'hamstrings',
          'calves'
        ])
          id: _neutral,
        for (final id in {..._from.keys, ..._to.keys})
          id: Color.lerp(_from[id] ?? _neutral, _to[id] ?? _neutral,
              DSMotion.snappy.transform(_controller.value))!,
      };

  @override
  void initState() {
    super.initState();
    _to = {for (final id in widget.selected) id: _selected};
    _from = Map.of(_to);
  }

  @override
  void didUpdateWidget(OnboardingMusclePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected.length == widget.selected.length &&
        oldWidget.selected.containsAll(widget.selected)) {
      return;
    }
    _from = _colors;
    _to = {for (final id in widget.selected) id: _selected};
    if (DSMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DSMotion.reduced(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) =>
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final back in [false, true])
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(children: [
                  SizedBox(
                      width: widget.height / 2,
                      height: widget.height,
                      child: widget.onSelected == null
                          ? AnatomicalMuscleIllustration(
                              back: back,
                              female: widget.female,
                              colors: _colors)
                          : AnatomicalTrainingMap(
                              back: back,
                              female: widget.female,
                              colors: _colors,
                              onSelected: widget.onSelected!)),
                  const SizedBox(height: 5),
                  FitnessText(back ? 'Back view' : 'Front view',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, color: FitnessTheme.muted)),
                ]),
              )),
          ]),
        ),
      );
}
