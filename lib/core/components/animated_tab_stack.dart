import 'package:flutter/material.dart';

/// Keeps tab subtrees mounted while fading and sliding between destinations.
class AnimatedTabStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const AnimatedTabStack({
    super.key,
    required this.index,
    required this.children,
  }) : assert(index >= 0 && index < children.length);

  static const duration = Duration(milliseconds: 320);
  static const curve = Curves.easeInOutCubic;

  @override
  State<AnimatedTabStack> createState() => _AnimatedTabStackState();
}

class _AnimatedTabStackState extends State<AnimatedTabStack> {
  late final Set<int> _visible = {widget.index};

  @override
  void didUpdateWidget(AnimatedTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _visible.add(widget.index);
    }
    _visible.removeWhere((index) => index >= widget.children.length);
  }

  void _hideFinishedTab(int index) {
    if (index != widget.index && _visible.contains(index)) {
      setState(() => _visible.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reducedMotion ? Duration.zero : AnimatedTabStack.duration;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          Offstage(
            offstage: reducedMotion
                ? index != widget.index
                : !_visible.contains(index),
            child: IgnorePointer(
              ignoring: index != widget.index,
              child: ExcludeSemantics(
                excluding: index != widget.index,
                child: AnimatedOpacity(
                  opacity: index == widget.index ? 1 : 0,
                  duration: duration,
                  curve: AnimatedTabStack.curve,
                  onEnd: () => _hideFinishedTab(index),
                  child: AnimatedSlide(
                    offset: index == widget.index
                        ? Offset.zero
                        : Offset(index < widget.index ? -.025 : .025, 0),
                    duration: duration,
                    curve: AnimatedTabStack.curve,
                    child: RepaintBoundary(child: widget.children[index]),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
