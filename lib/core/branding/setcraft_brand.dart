import 'package:flutter/material.dart';
import 'setcraft_geometry.dart';

/// One source for the public identity. Storage and platform IDs stay stable.
abstract final class SetcraftBrand {
  static const name = 'Setcraft';
  static const icon = 'assets/branding/setcraft-icon.png';
}

class SetcraftMark extends StatelessWidget {
  final double size;
  const SetcraftMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _SetcraftPainter()),
      );
}

class _SetcraftPainter extends CustomPainter {
  const _SetcraftPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024, size.height / 1024);
    // Use a filled annulus rather than the stroked-circle GPU primitive. The
    // latter was omitted on the physical Android renderer during startup.
    const outerRadius = 350 + SetcraftGeometry.ringStroke / 2;
    const innerRadius = 350 - SetcraftGeometry.ringStroke / 2;
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(
          Rect.fromCircle(center: const Offset(512, 512), radius: outerRadius))
      ..addOval(
          Rect.fromCircle(center: const Offset(512, 512), radius: innerRadius));
    canvas.drawPath(ring, Paint()..color = Colors.white);
    final symbolPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = SetcraftGeometry.symbolStroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.bevel;
    canvas.drawPath(SetcraftGeometry.symbol(), symbolPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SetcraftPainter oldDelegate) => false;
}

class SetcraftLockup extends StatelessWidget {
  final bool showName;
  const SetcraftLockup({super.key, this.showName = true});

  @override
  Widget build(BuildContext context) => Semantics(
        label: SetcraftBrand.name,
        image: true,
        child: ExcludeSemantics(
          child: SizedBox(
            width: 240,
            height: 144,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(child: SetcraftMark(size: 144)),
                if (showName)
                  const Positioned(
                    top: 152,
                    left: 0,
                    right: 0,
                    child: Text('SETCRAFT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFF5F5F2),
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4.2,
                        )),
                  ),
              ],
            ),
          ),
        ),
      );
}
