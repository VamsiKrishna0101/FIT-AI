import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import 'private_body_photo.dart';

/// The photo stays still. Only this small overlay repaints while analysis runs.
class PhysiquePhotoStage extends StatelessWidget {
  final Uint8List? bytes;
  final BodyPhoto? photo;
  final Widget? background;
  final Animation<double>? scan;
  final String label;
  final Widget? footer;
  final Color? borderColor;
  final double aspectRatio;
  final BoxFit fit;
  final bool strongGradient;
  const PhysiquePhotoStage(
      {super.key,
      this.bytes,
      this.photo,
      this.background,
      this.scan,
      this.label = 'Front view',
      this.borderColor,
      this.aspectRatio = .82,
      this.fit = BoxFit.contain,
      this.strongGradient = false,
      this.footer});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(
                color: FitnessTheme.surface,
                child: RepaintBoundary(
                    child: bytes != null
                        ? Image.memory(bytes!,
                            fit: fit,
                            cacheWidth: 1000,
                            gaplessPlayback: false,
                            errorBuilder: (_, __, ___) => const Center(
                                child: Icon(CupertinoIcons.photo,
                                    color: FitnessTheme.muted)))
                        : photo != null
                            ? PrivateBodyPhoto(
                                key: ValueKey(photo!.id),
                                photo: photo!,
                                fit: fit)
                            : background ??
                                const Center(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                      Icon(CupertinoIcons.person_crop_rectangle,
                                          size: 64, color: FitnessTheme.muted),
                                      SizedBox(height: 18),
                                      FitnessText(
                                          'Your photo, your starting point.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: FitnessTheme.muted)),
                                    ])))),
            IgnorePointer(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: strongGradient
                                ? const Alignment(0, -.6)
                                : Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: strongGradient
                                ? const [
                                    Colors.transparent,
                                    Color(0xEE000000),
                                    Colors.black
                                  ]
                                : const [Colors.transparent, Color(0xE6000000)],
                            stops:
                                strongGradient ? const [0, .42, 1] : null)))),
            if (scan != null)
              Positioned.fill(
                  child: IgnorePointer(
                      child: RepaintBoundary(
                          child: AnimatedBuilder(
                              animation: scan!,
                              builder: (_, __) => CustomPaint(
                                  key: const ValueKey('physique-scan-line'),
                                  painter: _ScanLine(scan!.value)))))),
            Positioned(
                top: 16,
                left: 16,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(20)),
                    child: FitnessText(label,
                        style: const TextStyle(
                            fontSize: 11, color: FitnessTheme.silver)))),
            if (footer != null)
              Positioned(left: 18, right: 18, bottom: 20, child: footer!),
            Positioned.fill(
                child: IgnorePointer(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: borderColor ??
                                    Colors.white.withValues(alpha: .14),
                                width: strongGradient ? 1.5 : .8))))),
          ]),
        ),
      );
}

class _ScanLine extends CustomPainter {
  final double progress;
  const _ScanLine(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final y = 18 + (size.height - 36) * progress;
    final rect =
        Rect.fromLTRB(0, (y - 90).clamp(0, size.height), size.width, y);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x668DBBFF)])
              .createShader(rect));
    canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0xFF8DBBFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
          ..strokeWidth = 8);
    canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0xFFE5F1FF)
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_ScanLine oldDelegate) => oldDelegate.progress != progress;
}
