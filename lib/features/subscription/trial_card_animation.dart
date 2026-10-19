import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/fitness_copy.dart';
import '../../core/localization/fitness_text.dart';
import '../../core/theme/ds_colors.dart';
import '../../core/theme/ds_motion.dart';

/// A finite illustration: the card settles halfway into the bin and stays there.
class TrialCardAnimation extends StatefulWidget {
  const TrialCardAnimation({super.key});

  @override
  State<TrialCardAnimation> createState() => _TrialCardAnimationState();
}

class _TrialCardAnimationState extends State<TrialCardAnimation>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1900));
  bool _started = false;
  ui.Image? _binImage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBin());
  }

  Future<void> _loadBin() async {
    try {
      final data = await rootBundle.load('assets/branding/trial-bin.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
          targetWidth: 400);
      try {
        final frame = await codec.getNextFrame();
        if (!mounted) {
          frame.image.dispose();
          return;
        }
        setState(() => _binImage = frame.image);
        _play();
      } finally {
        codec.dispose();
      }
    } catch (_) {
      if (mounted) _controller.value = 1;
    }
  }

  void _play() {
    if (DSMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 1;
      _started = true;
    } else if (!_started && _binImage != null) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _play();
  }

  @override
  void dispose() {
    _controller.dispose();
    _binImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: fitnessText(context, 'No card needed'),
        child: ExcludeSemantics(
            child: Column(children: [
          SizedBox(
            key: const ValueKey('trial-card-animation'),
            height: 190,
            width: double.infinity,
            child: RepaintBoundary(
                child: CustomPaint(
              painter: TrialCardPainter(_controller, binImage: _binImage),
              isComplex: true,
            )),
          ),
          FadeTransition(
            opacity: _controller.drive(CurveTween(
                curve: const Interval(.86, 1, curve: Curves.easeOut))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DSColors.bgElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DSColors.border),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_rounded, size: 14, color: DSColors.silver),
                SizedBox(width: 6),
                Flexible(
                    child: FitnessText('No card needed',
                        style:
                            TextStyle(fontSize: 11, color: DSColors.silver))),
              ]),
            ),
          ),
        ])),
      );
}

class TrialCardPainter extends CustomPainter {
  final Animation<double> progress;
  final ui.Image? binImage;
  TrialCardPainter(this.progress, {this.binImage}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    const design = Size(320, 230);
    final scale =
        math.min(size.width / design.width, size.height / design.height);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - design.width * scale) / 2,
        (size.height - design.height * scale) / 2);
    canvas.scale(scale);
    canvas.translate(-21, 0);

    final time = progress.value;
    final glide = Curves.easeInOutCubic.transform((time / .56).clamp(0.0, 1.0));
    final drop =
        Curves.easeInOutCubic.transform(((time - .56) / .32).clamp(0.0, 1.0));
    final settle =
        -math.sin(((time - .88) / .12).clamp(0.0, 1.0) * math.pi) * 1.2;
    const binRect = Rect.fromLTWH(99, 36, 164, 196.8);
    final image = binImage;
    final source = image == null
        ? Rect.zero
        : Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final imagePaint = Paint()..filterQuality = FilterQuality.medium;
    if (image != null) canvas.drawImageRect(image, source, binRect, imagePaint);

    // This card is never dissolved or fully hidden: its lower half is occluded.
    final center = Offset(
      ui.lerpDouble(-55, 181, glide)!,
      42 + 38 * drop - math.sin(glide * math.pi) * 4,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy + settle);
    canvas.rotate(ui.lerpDouble(-.02, -.18, glide)! + .06 * drop);
    canvas.scale(.86);
    final card = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-61, -39, 122, 78), const Radius.circular(10));
    canvas.drawRRect(
        card.shift(const Offset(0, 4)),
        Paint()
          ..color = const Color(0x50000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawRRect(card.shift(const Offset(0, 1.5)),
        Paint()..color = const Color(0xFF616A70));
    canvas.drawRRect(
        card,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F1F2),
              Color(0xFFBCC2C7),
              Color(0xFFE1E4E6),
              Color(0xFF89939C),
            ],
            stops: [0, .38, .6, 1],
          ).createShader(card.outerRect));

    canvas.save();
    canvas.clipRRect(card);

    // Fine, low-contrast grain follows the metal rather than floating over it.
    final grain = Paint()..strokeWidth = .3;
    for (var line = 0; line < 52; line++) {
      grain.color =
          line.isEven ? const Color(0x17FFFFFF) : const Color(0x0D35414A);
      final y = -38 + line * 1.5;
      canvas.drawLine(Offset(-61, y), Offset(61, y - 8), grain);
    }

    final etching = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .55
      ..color = const Color(0x33758088);
    for (var ring = 0; ring < 4; ring++) {
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(63, 28),
              width: 69 + ring * 15,
              height: 100 + ring * 15),
          etching);
    }

    canvas.drawRRect(
        card,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF)],
            stops: [0, .28, 1],
          ).createShader(card.outerRect));
    canvas.restore();

    canvas.drawRRect(
        card.deflate(.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xEFFFFFFF), Color(0x36838D96), Color(0xA6FFFFFF)],
          ).createShader(card.outerRect));
    final chip = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-45, -20, 20, 16), const Radius.circular(4));
    canvas.drawRRect(
        chip,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8DFC9), Color(0xFFB4A994), Color(0xFFF1EADB)],
          ).createShader(chip.outerRect));
    final engraving = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = const Color(0xFF8F8779);
    canvas.drawRRect(chip, engraving);
    canvas.drawLine(const Offset(-39, -20), const Offset(-39, -4), engraving);
    canvas.drawLine(const Offset(-31, -20), const Offset(-31, -4), engraving);
    canvas.drawLine(const Offset(-45, -12), const Offset(-25, -12), engraving);
    final contactless = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1
      ..color = const Color(0xFF67737D);
    for (var wave = 0; wave < 3; wave++) {
      final radius = 4.0 + wave * 3;
      canvas.drawArc(
          Rect.fromCircle(center: const Offset(34, -14), radius: radius),
          -.7,
          1.4,
          false,
          contactless);
    }
    for (var index = 0; index < 4; index++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-45 + index * 23, 9, 16, 3),
              const Radius.circular(1.5)),
          Paint()..color = const Color(0x66616E78));
    }
    canvas.restore();

    // Paint the same 3D asset's front lip/body over the card. The mask follows
    // the opening's lower ellipse, so only the card's top half remains visible.
    if (image != null) {
      canvas.save();
      canvas.clipPath(Path()
        ..moveTo(122, 68)
        ..quadraticBezierTo(181, 101, 240, 68)
        ..lineTo(263, 233)
        ..lineTo(99, 233)
        ..close());
      canvas.drawImageRect(image, source, binRect, imagePaint);
      canvas.restore();
    }

    // A few finite specks lift from the rim and disappear; no perpetual sparkle.
    final burst = ((time - .78) / .22).clamp(0.0, 1.0);
    final opacity = math.sin(burst * math.pi) * .6;
    if (opacity > 0) {
      for (var index = 0; index < 7; index++) {
        final side = index.isEven ? -1.0 : 1.0;
        final x = 181 + side * (42 + burst * (12 + index * 3));
        final y = 75 - burst * (15 + index * 7);
        canvas.drawCircle(Offset(x, y), index.isEven ? 1.3 : .9,
            Paint()..color = DSColors.silver.withValues(alpha: opacity));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TrialCardPainter old) =>
      old.progress != progress || old.binImage != binImage;
}
