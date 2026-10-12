import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// MARK: - Whoop 5.0 Bioluminescent Trend View Card
class BioluminescentTrendCard extends StatefulWidget {
  final List<double> dataPoints;
  final double baseline;
  final String title;
  final String metricName;
  final String unit;
  final Color trajectoryColor;
  final List<String> xLabels;

  const BioluminescentTrendCard({
    super.key,
    this.dataPoints = const [74, 82, 79, 86, 78, 84, 88],
    this.baseline = 80.0,
    this.title = 'Trend View',
    this.metricName = 'RECOVERY SCORE',
    this.unit = '%',
    this.trajectoryColor = const Color(0xFFE5A93C),
    this.xLabels = const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'TODAY'],
  });

  @override
  State<BioluminescentTrendCard> createState() => _BioluminescentTrendCardState();
}

class _BioluminescentTrendCardState extends State<BioluminescentTrendCard> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.dataPoints;
    final currentScore = points.isNotEmpty ? points.last.toInt() : 0;
    final activeValue = _hoveredIndex != null && _hoveredIndex! < points.length
        ? points[_hoveredIndex!].toInt()
        : currentScore;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101216).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Header (Title + Scrubber Metric Value) ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.metricName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              // Current Value Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.trajectoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.trajectoryColor.withValues(alpha: 0.35),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  '$activeValue${widget.unit}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: widget.trajectoryColor,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── 2. Legend Row ─────────────────────────────────────────────────
          Row(
            children: [
              _LegendDot(
                color: widget.trajectoryColor,
                label: 'YOUR SCORE',
              ),
              const SizedBox(width: 14),
              _LegendDot(
                color: Colors.white.withValues(alpha: 0.35),
                label: 'BASELINE (${widget.baseline.toInt()}${widget.unit})',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── 3. Interactive Bioluminescent Line Canvas ─────────────────────
          SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragDown: (details) =>
                      _handleTouch(details.localPosition.dx, constraints.maxWidth),
                  onHorizontalDragUpdate: (details) =>
                      _handleTouch(details.localPosition.dx, constraints.maxWidth),
                  onHorizontalDragEnd: (_) => setState(() => _hoveredIndex = null),
                  onTapUp: (_) => setState(() => _hoveredIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 120),
                    painter: _BioluminescentChartPainter(
                      dataPoints: points,
                      baseline: widget.baseline,
                      trajectoryColor: widget.trajectoryColor,
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── 4. Day Labels on X Axis ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (final l in widget.xLabels) _XAxisLabel(l)],
          ),
        ],
      ),
    );
  }

  void _handleTouch(double touchX, double width) {
    final count = widget.dataPoints.length;
    if (count < 2) return;
    final step = width / (count - 1);
    final idx = (touchX / step).round().clamp(0, count - 1);
    if (_hoveredIndex != idx) {
      HapticFeedback.selectionClick();
      setState(() => _hoveredIndex = idx);
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _XAxisLabel extends StatelessWidget {
  final String text;

  const _XAxisLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.4),
        letterSpacing: 0.3,
      ),
    );
  }
}

// MARK: - Glowing Bezier Chart Painter
class _BioluminescentChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final double baseline;
  final Color trajectoryColor;
  final int? hoveredIndex;

  _BioluminescentChartPainter({
    required this.dataPoints,
    required this.baseline,
    required this.trajectoryColor,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final w = size.width;
    final h = size.height;

    // Y Axis Range: 40 to 100
    const minY = 40.0;
    const maxY = 100.0;
    const rangeY = maxY - minY;

    double yPos(double val) =>
        h - (((val - minY) / rangeY).clamp(0.0, 1.0) * h);

    // 1. Gridlines (at 50, 75, 100)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;

    for (final tick in [50.0, 75.0, 100.0]) {
      final gy = yPos(tick);
      canvas.drawLine(Offset(0, gy), Offset(w, gy), gridPaint);
    }

    // 2. Baseline Reference Line (dashed style or faint white)
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;
    final by = yPos(baseline);
    canvas.drawLine(Offset(0, by), Offset(w, by), basePaint);

    // 3. Compute Bezier Path
    final dx = w / (dataPoints.length - 1);
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final pt = Offset(i * dx, yPos(dataPoints[i]));
      points.add(pt);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        final prev = points[i - 1];
        final midX = (prev.dx + pt.dx) / 2;
        path.cubicTo(midX, prev.dy, midX, pt.dy, pt.dx, pt.dy);
      }
    }

    // 4. Pass A: Soft Gaussian Glow Layer
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = trajectoryColor.withValues(alpha: 0.45);
    canvas.drawPath(path, glowPaint);

    // 5. Pass B: Crisp Core Trajectory Line
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = trajectoryColor;
    canvas.drawPath(path, corePaint);

    // 6. Data Points & Active Scrubber
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF101216);

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isHovered = hoveredIndex == i;
      final isLast = hoveredIndex == null && i == points.length - 1;

      if (isHovered || isLast) {
        // Glowing vertical guideline if scrubbed
        if (isHovered) {
          final guidePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.2)
            ..strokeWidth = 1.0;
          canvas.drawLine(Offset(pt.dx, 0), Offset(pt.dx, h), guidePaint);
        }

        // Active Dot (Larger with Halo)
        final haloPaint = Paint()
          ..color = trajectoryColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(pt, 8, haloPaint);

        dotPaint.color = Colors.white;
        canvas.drawCircle(pt, 4.5, dotPaint);
        canvas.drawCircle(pt, 4.5, ringPaint);
      } else {
        // Subtle Vertex Point
        dotPaint.color = trajectoryColor.withValues(alpha: 0.85);
        canvas.drawCircle(pt, 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BioluminescentChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.trajectoryColor != trajectoryColor;
  }
}
