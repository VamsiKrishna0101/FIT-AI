import 'package:flutter/material.dart';
import '../theme/ds_motion.dart';

/// Keeps tab subtrees mounted while crossfading between destinations.
class AnimatedTabStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const AnimatedTabStack({
    super.key,
    required this.index,
    required this.children,
  }) : assert(index >= 0 && index < children.length);

  static const duration = DSMotion.feedback;
  static const curve = DSMotion.effects;

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
    // A zero-duration animation can complete while its parent is rebuilding.
    // Wait until that frame ends, and check rapid tab changes again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index == widget.index || !_visible.contains(index)) {
        return;
      }
      setState(() => _visible.remove(index));
    });
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
                  child: RepaintBoundary(child: widget.children[index]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
