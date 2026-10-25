import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import 'body_controls.dart';
import 'private_body_photo.dart';

class PhotoComparisonStudio extends StatefulWidget {
  final BodyAssessment before, after;
  final Widget Function(BodyPhoto)? imageBuilder;
  const PhotoComparisonStudio(
      {super.key,
      required this.before,
      required this.after,
      this.imageBuilder});
  @override
  State<PhotoComparisonStudio> createState() => _PhotoComparisonStudioState();
}

class _PhotoComparisonStudioState extends State<PhotoComparisonStudio> {
  String _view = 'front';
  bool _sideBySide = false, _align = false;
  double _split = .5, _x = 0, _y = 0, _scale = 1;
  final _zoom = TransformationController();
  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _reset() {
    _zoom.value = Matrix4.identity();
    _split = .5;
    _x = 0;
    _y = 0;
    _scale = 1;
  }

  @override
  void didUpdateWidget(PhotoComparisonStudio old) {
    super.didUpdateWidget(old);
    if (old.before.id != widget.before.id || old.after.id != widget.after.id) {
      _reset();
    }
  }

  Widget _image(BodyPhoto photo) =>
      widget.imageBuilder?.call(photo) ??
      PrivateBodyPhoto(
          key: ValueKey(photo.id), photo: photo, fit: BoxFit.contain);
  String _label(String view) => switch (view) {
        'left' => 'Left side',
        'right' => 'Right side',
        'back' => 'Back',
        _ => 'Front'
      };

  @override
  Widget build(BuildContext context) {
    final views = ['front', 'back', 'left', 'right']
        .where((view) =>
            widget.before.photos.any((p) => p.view == view) &&
            widget.after.photos.any((p) => p.view == view))
        .toList();
    if (views.isEmpty || !widget.after.canComparePhotosWith(widget.before)) {
      return const SizedBox.shrink();
    }
    final selected = views.contains(_view) ? _view : views.first;
    final before = widget.before.photos.firstWhere((p) => p.view == selected);
    final after = widget.after.photos.firstWhere((p) => p.view == selected);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const FitnessText('Your progress, in focus.',
          style: TextStyle(
              fontSize: 25, fontWeight: FontWeight.w600, letterSpacing: -.7)),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final view in views)
          ChoiceChip(
              label: FitnessText(_label(view)),
              selected: selected == view,
              showCheckmark: false,
              selectedColor: FitnessTheme.silver,
              backgroundColor: FitnessTheme.surface,
              labelStyle: TextStyle(
                  color: selected == view
                      ? FitnessTheme.canvas
                      : FitnessTheme.silver),
              onSelected: (_) => setState(() {
                    _view = view;
                    _reset();
                  }))
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        _mode('Drag to compare', false),
        _mode('Side by side', true),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _date('BEFORE', widget.before.recordedDate)),
        const SizedBox(width: 16),
        Expanded(child: _date('AFTER', widget.after.recordedDate)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
              aspectRatio: .78,
              child: ColoredBox(
                  color: FitnessTheme.surface,
                  child: _sideBySide
                      ? Row(children: [
                          Expanded(child: _image(before)),
                          const SizedBox(width: 2),
                          Expanded(child: _image(after))
                        ])
                      : InteractiveViewer(
                          transformationController: _zoom,
                          minScale: 1,
                          maxScale: 3,
                          child: LayoutBuilder(builder: (context, constraints) {
                            final width = constraints.maxWidth,
                                height = constraints.maxHeight;
                            final x = width * _split;
                            return Stack(fit: StackFit.expand, children: [
                              Transform.translate(
                                  key: const ValueKey(
                                      'comparison-before-transform'),
                                  offset: Offset(_x * width, _y * height),
                                  child: Transform.scale(
                                      scale: _scale, child: _image(before))),
                              ClipRect(
                                  clipper: _RevealClipper(_split),
                                  child: _image(after)),
                              Positioned(
                                  left: x - .75,
                                  top: 0,
                                  bottom: 0,
                                  child: const SizedBox(
                                      width: 1.5,
                                      child: ColoredBox(color: Colors.white))),
                              Positioned(
                                  left: (x - 24).clamp(0.0, width - 48),
                                  top: 0,
                                  bottom: 0,
                                  child: Semantics(
                                      label: 'Before and after divider',
                                      value:
                                          '${(_split * 100).round()} percent revealed',
                                      increasedValue:
                                          '${((_split + .1).clamp(.03, .97) * 100).round()} percent revealed',
                                      decreasedValue:
                                          '${((_split - .1).clamp(.03, .97) * 100).round()} percent revealed',
                                      onIncrease: () => setState(() => _split =
                                          (_split + .1).clamp(.03, .97)),
                                      onDecrease: () => setState(() => _split =
                                          (_split - .1).clamp(.03, .97)),
                                      child: GestureDetector(
                                          key: const ValueKey(
                                              'photo-comparison-handle'),
                                          behavior: HitTestBehavior.opaque,
                                          onHorizontalDragUpdate: (details) =>
                                              setState(() => _split =
                                                  (_split + details.delta.dx / width).clamp(.03, .97)),
                                          child: SizedBox(width: 48, child: Center(child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: FitnessTheme.line)), child: const Icon(CupertinoIcons.arrow_left_right, color: Colors.black, size: 18))))))),
                            ]);
                          }))))),
      if (!_sideBySide) ...[
        Slider(
            key: const ValueKey('photo-comparison-split'),
            value: _split,
            min: .03,
            max: .97,
            activeColor: FitnessTheme.silver,
            inactiveColor: FitnessTheme.line,
            semanticFormatterCallback: (value) =>
                '${(value * 100).round()} percent revealed',
            onChanged: (value) => setState(() => _split = value)),
        Wrap(spacing: 10, children: [
          TextButton.icon(
              onPressed: () => setState(() => _align = !_align),
              icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 14),
              label: const FitnessText('Align earlier photo')),
          TextButton(
              onPressed: () => setState(_reset),
              child: const FitnessText('Reset')),
        ]),
        if (_align) ...[
          const FitnessText(
              'Adjust framing only. Your original photos stay unchanged.',
              style: TextStyle(
                  fontSize: 11, height: 1.4, color: FitnessTheme.muted)),
          _adjust('Horizontal', _x, -.25, .25, (v) => setState(() => _x = v)),
          _adjust('Vertical', _y, -.25, .25, (v) => setState(() => _y = v)),
          _adjust('Size', _scale, .75, 1.5, (v) => setState(() => _scale = v)),
        ],
      ],
      const SizedBox(height: 8),
      const FitnessText(
          'Match pose, lighting and camera distance. Drag the divider to reveal each photo; pinch to zoom both together.',
          style:
              TextStyle(fontSize: 12, height: 1.5, color: FitnessTheme.muted)),
      const SizedBox(height: 6),
      const FitnessText(
          'Visual comparison does not measure muscle gain or fat loss.',
          style:
              TextStyle(fontSize: 11, height: 1.5, color: FitnessTheme.muted)),
    ]);
  }

  Widget _mode(String title, bool side) => ChoiceChip(
      label: FitnessText(title),
      selected: _sideBySide == side,
      showCheckmark: false,
      selectedColor: FitnessTheme.surface,
      side: BorderSide(
          color: _sideBySide == side ? FitnessTheme.silver : FitnessTheme.line),
      onSelected: (_) => setState(() => _sideBySide = side));
  Widget _date(String label, String date) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(label,
            style: const TextStyle(
                fontSize: 10, letterSpacing: 1.5, color: FitnessTheme.muted)),
        const SizedBox(height: 4),
        FitnessText(bodyDate(date),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ]);
  Widget _adjust(String title, double value, double min, double max,
          ValueChanged<double> changed) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(title, style: const TextStyle(fontSize: 12)),
        Slider(
            value: value,
            min: min,
            max: max,
            activeColor: FitnessTheme.silver,
            inactiveColor: FitnessTheme.line,
            onChanged: changed,
            label: title),
      ]);
}

class _RevealClipper extends CustomClipper<Rect> {
  final double split;
  const _RevealClipper(this.split);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width * split, 0, size.width, size.height);
  @override
  bool shouldReclip(_RevealClipper oldClipper) => oldClipper.split != split;
}
