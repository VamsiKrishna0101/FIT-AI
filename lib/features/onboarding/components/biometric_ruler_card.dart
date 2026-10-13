import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

/// A horizontal ruler. Values change only after a user gesture or accessibility action.
class BiometricRulerCard extends StatefulWidget {
  final String label, valueDisplay;
  final String? unit, secondaryDisplay;
  final double value, min, max, step;
  final int majorEvery;
  final String Function(double) tickLabel;
  final ValueChanged<double> onChanged;

  const BiometricRulerCard({
    super.key,
    required this.label,
    required this.valueDisplay,
    this.unit,
    this.secondaryDisplay,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.majorEvery,
    required this.tickLabel,
    required this.onChanged,
  });

  @override
  State<BiometricRulerCard> createState() => _BiometricRulerCardState();
}

class _BiometricRulerCardState extends State<BiometricRulerCard> {
  static const _tickWidth = 10.0;
  late final ScrollController _scroll;
  late int _index;
  bool _dragging = false, _snapping = false;
  DateTime _lastFeedback = DateTime.fromMillisecondsSinceEpoch(0);

  int get _count => ((widget.max - widget.min) / widget.step).round() + 1;
  int _indexFor(double value) =>
      ((value - widget.min) / widget.step).round().clamp(0, _count - 1);
  double _valueAt(int index) =>
      double.parse((widget.min + index * widget.step).toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    _index = _indexFor(widget.value);
    _scroll = ScrollController(initialScrollOffset: _index * _tickWidth)
      ..addListener(_onScroll);
  }

  @override
  void didUpdateWidget(BiometricRulerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _indexFor(widget.value);
    if (!_dragging && next != _index) {
      _index = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients && !_dragging) {
          _scroll.jumpTo(_index * _tickWidth);
        }
      });
    }
  }

  void _onScroll() {
    if (!_dragging) return;
    final next = (_scroll.offset / _tickWidth).round().clamp(0, _count - 1);
    if (next == _index) return;
    _index = next;
    final now = DateTime.now();
    if (now.difference(_lastFeedback).inMilliseconds >= 50) {
      HapticFeedback.selectionClick();
      _lastFeedback = now;
    }
    widget.onChanged(_valueAt(next));
  }

  Future<void> _snap() async {
    if (_snapping || !_dragging || !_scroll.hasClients) return;
    _snapping = true;
    final target = _index * _tickWidth;
    if ((_scroll.offset - target).abs() > .1) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(target);
      } else {
        await _scroll.animateTo(target,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic);
      }
    }
    if (!mounted) return;
    _snapping = false;
    if (!_scroll.position.isScrollingNotifier.value) _dragging = false;
  }

  void _adjust(int amount) {
    final next = (_index + amount).clamp(0, _count - 1);
    if (next == _index) return;
    _index = next;
    HapticFeedback.selectionClick();
    if (_scroll.hasClients) _scroll.jumpTo(next * _tickWidth);
    widget.onChanged(_valueAt(next));
  }

  String _spokenAt(int index) {
    final value = _valueAt(index);
    return widget.unit == null
        ? widget.tickLabel(value)
        : '${value.toStringAsFixed(widget.step < 1 ? 1 : 0)} ${widget.unit}';
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF292B2D), Color(0xFF1B1C1E)]),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FitnessText(widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: FitnessTheme.muted)),
          const SizedBox(height: 10),
          Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(widget.valueDisplay,
                    style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1.5,
                        fontFeatures: [FontFeature.tabularFigures()])),
                if (widget.unit != null)
                  FitnessText(widget.unit!,
                      style: const TextStyle(
                          fontSize: 16, color: FitnessTheme.muted)),
              ]),
          if (widget.secondaryDisplay != null)
            Text(widget.secondaryDisplay!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          const SizedBox(height: 18),
          Semantics(
            label: widget.label,
            value: '${widget.valueDisplay} ${widget.unit ?? ''}',
            increasedValue: _index < _count - 1 ? _spokenAt(_index + 1) : null,
            decreasedValue: _index > 0 ? _spokenAt(_index - 1) : null,
            onIncrease: _index < _count - 1 ? () => _adjust(1) : null,
            onDecrease: _index > 0 ? () => _adjust(-1) : null,
            child: ExcludeSemantics(
                child: Directionality(
              textDirection: TextDirection.ltr,
              child: LayoutBuilder(
                  builder: (context, bounds) => SizedBox(
                        height: 72,
                        child: Stack(alignment: Alignment.topCenter, children: [
                          NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollStartNotification &&
                                  notification.dragDetails != null) {
                                _dragging = true;
                              }
                              if (notification is ScrollEndNotification) {
                                _snap();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              key: const ValueKey('biometric-ruler-track'),
                              controller: _scroll,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              itemExtent: _tickWidth,
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      (bounds.maxWidth - _tickWidth) / 2),
                              itemCount: _count,
                              itemBuilder: (context, index) {
                                final major =
                                    (_valueAt(index) / widget.step).round() %
                                            widget.majorEvery ==
                                        0;
                                return Column(children: [
                                  SizedBox(
                                      height: 42,
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                            width: major ? 2 : 1,
                                            height: major
                                                ? 30
                                                : index % 5 == 0
                                                    ? 22
                                                    : 14,
                                            color: Colors.white.withValues(
                                                alpha: major ? .55 : .22)),
                                      )),
                                  const SizedBox(height: 8),
                                  if (major)
                                    SizedBox(
                                        height: 18,
                                        child: OverflowBox(
                                            minWidth: 0,
                                            maxWidth: 64,
                                            maxHeight: 18,
                                            alignment: Alignment.topCenter,
                                            child: Text(
                                                widget
                                                    .tickLabel(_valueAt(index)),
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        FitnessTheme.muted)))),
                                ]);
                              },
                            ),
                          ),
                          IgnorePointer(
                              child: Container(
                                  width: 3,
                                  height: 46,
                                  decoration: BoxDecoration(
                                      color: FitnessTheme.silver,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.white
                                                .withValues(alpha: .12),
                                            blurRadius: 8)
                                      ]))),
                        ]),
                      )),
            )),
          ),
          const SizedBox(height: 8),
          const FitnessText('Swipe left or right to adjust',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        ]),
      );
}
