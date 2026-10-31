import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

// Lucide: sun, dumbbell, contact-round, chart-no-axes-column-increasing.
// ISC License — Copyright (c) 2026 Lucide Icons and Contributors.
// Sun is derived from Feather, MIT — Copyright (c) 2013-present Cole Bemis.
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// Feather permission: to deal in the Software without restriction, including
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies,
// and to permit persons to whom the Software is furnished to do so, subject to
// including this copyright and permission notice. THE SOFTWARE IS PROVIDED
// "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
// LIMITED TO MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

enum NavigationGlyphKind { today, train, body, progress }

/// The concept's matching outline icons, drawn as cached vectors without a font.
class NavigationGlyph extends StatelessWidget {
  final NavigationGlyphKind kind;
  final Color color;
  final double size;
  const NavigationGlyph(
      {super.key, required this.kind, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: CustomPaint(
          size: Size.square(size),
          painter: _NavigationGlyphPainter(kind, color)));
}

class _NavigationGlyphPainter extends CustomPainter {
  final NavigationGlyphKind kind;
  final Color color;
  const _NavigationGlyphPainter(this.kind, this.color);
  static final _paths = <NavigationGlyphKind, List<Path>>{
    NavigationGlyphKind.today: [
      Path()..addOval(const Rect.fromLTWH(8, 8, 8, 8)),
      parseSvgPathData('M12 2v2 M12 20v2 m-7.07-17.07 1.41 1.41 '
          'M17.66 17.66l1.41 1.41 M2 12h2 M20 12h2 '
          'M6.34 17.66l-1.41 1.41 M19.07 4.93l-1.41 1.41'),
    ],
    NavigationGlyphKind.train: [
      parseSvgPathData('M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767'
          'a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828'
          'l-1.767-1.768a2 2 0 1 0-2.829 2.829z'),
      parseSvgPathData('M2.5 21.5l1.4-1.4 M20.1 3.9l1.4-1.4'),
      parseSvgPathData('M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768'
          'a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829'
          'l1.768 1.767a2 2 0 0 0-2.828 2.829z'),
      parseSvgPathData('M9.6 14.4l4.8-4.8'),
    ],
    NavigationGlyphKind.body: [
      parseSvgPathData('M16 2v2 M17.915 21a6 6 0 1 0-12 0 M8 2v2'),
      Path()..addOval(const Rect.fromLTWH(8, 7, 8, 8)),
      Path()
        ..addRRect(RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18), const Radius.circular(2))),
    ],
    NavigationGlyphKind.progress: [
      parseSvgPathData('M5 21v-6 M12 21V9 M19 21V3'),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in _paths[kind]!) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NavigationGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
