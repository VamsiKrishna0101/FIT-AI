import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_drawing/path_drawing.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';

const anatomyPrimary = Color(0xFFFF5B50);
const anatomySecondary = Color(0xFFE7ACA8);
const graphiteAnatomyAsset = 'assets/exercise_anatomy/graphite-atlas-v1.png';

/// Hand-traced regions in the ORIGINAL 1024 × 1536 atlas coordinate space.
/// These masks belong to this artwork, not to the Body tab's SVG geometry.
/// Shading/fibres remain visible because the source pixels are tinted in place.
final _regions = <String, Map<String, List<Path>>>{};

Map<String, List<Path>> graphiteMusclePaths(
    {required bool female, required bool back}) {
  final key = '${female ? 'female' : 'male'}_${back ? 'back' : 'front'}';
  return _regions.putIfAbsent(key, () {
    final source = _regionData[key]!;
    final center = back ? 748.0 : 275.0;
    final mirror = Float64List.fromList(
        [-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, center * 2, 0, 0, 1]);
    return {
      for (final entry in source.entries)
        entry.key: [
          for (final data in entry.value) ...[
            parseSvgPathData(data),
            parseSvgPathData(data).transform(mirror),
          ]
        ]
    };
  });
}

// Each path traces the viewer's left side; the matching right side is mirrored.
// Clothing over chest/glutes is tinted as an anatomical location, not exposed tissue.
const _regionData = <String, Map<String, List<String>>>{
  'male_front': {
    'chest': [
      'M273 149 C250 143 226 137 211 146 C202 154 197 170 201 182 C211 200 235 214 253 207 L273 197 Z'
    ],
    'shoulders': [
      'M207 137 C186 135 174 148 171 166 C168 180 172 191 179 195 C188 185 197 167 212 153 Z'
    ],
    'biceps': [
      'M181 189 C166 196 160 218 158 237 L165 248 C178 246 192 222 198 198 L193 185 Z'
    ],
    'triceps': [
      'M167 190 C156 203 153 225 148 246 L155 258 L162 238 C159 221 169 200 173 192 Z'
    ],
    'forearms': [
      'M151 246 C139 259 135 277 133 296 L127 334 L137 337 C148 314 163 285 170 261 L163 246 Z'
    ],
    'core': [
      'M273 210 C251 213 229 208 214 200 L222 249 L218 282 L223 307 C239 314 256 315 273 312 Z'
    ],
    'upper_back': ['M252 108 L239 125 L210 136 L228 143 L268 147 L270 139 Z'],
    'quads': [
      'M194 402 C212 406 241 412 265 407 C263 436 248 461 240 475 L231 485 C211 486 201 469 197 450 C191 434 191 419 194 402 Z'
    ],
    'calves': [
      'M203 492 C199 511 185 526 184 547 C182 575 191 607 194 640 L207 648 C209 619 221 591 231 571 C239 547 237 526 226 504 L220 493 Z'
    ],
  },
  'male_back': {
    'upper_back': [
      'M747 107 L730 121 L705 133 L692 143 C710 153 726 172 739 203 L747 225 Z'
    ],
    'lats': [
      'M691 177 C708 194 724 207 740 212 L745 246 L733 281 C714 279 701 265 690 249 C679 230 675 209 678 199 Z'
    ],
    'lower_back': ['M746 244 L734 280 L715 286 L706 302 L747 306 Z'],
    'shoulders': [
      'M691 140 C668 136 650 149 643 168 L642 184 L656 193 C668 177 684 164 705 154 Z'
    ],
    'triceps': [
      'M658 190 C647 204 643 223 638 241 L646 257 C661 250 673 224 681 201 L673 190 Z'
    ],
    'forearms': [
      'M635 248 C619 267 615 285 610 310 L605 334 L616 338 C632 310 649 282 652 261 L647 250 Z'
    ],
    'glutes': [
      'M700 319 C716 319 733 321 747 323 L747 395 C728 403 704 399 685 388 L689 350 Z'
    ],
    'hamstrings': [
      'M681 405 C696 413 718 419 740 412 C740 446 728 476 715 493 L699 495 C684 471 677 438 681 405 Z'
    ],
    'calves': [
      'M701 506 C686 519 682 542 687 567 C691 583 700 595 701 620 L707 643 L716 642 C718 615 727 588 730 563 C733 539 730 518 721 507 Z'
    ],
  },
  'female_front': {
    'chest': [
      'M273 866 L245 861 C236 881 223 890 215 899 L219 936 C237 942 254 944 273 940 Z'
    ],
    'shoulders': [
      'M223 856 C201 852 189 863 183 879 L182 906 L192 918 C200 900 209 887 225 880 Z'
    ],
    'biceps': [
      'M191 915 C179 931 174 948 170 965 L178 978 C193 967 204 946 208 924 L201 910 Z'
    ],
    'triceps': ['M180 915 L170 938 L162 968 L168 978 L176 960 L188 925 Z'],
    'forearms': [
      'M166 973 C150 996 143 1021 135 1045 L128 1067 L138 1074 C155 1046 174 1016 182 990 L179 979 Z'
    ],
    'core': [
      'M273 951 C255 953 237 950 223 944 C224 970 231 987 220 1018 L222 1032 C238 1042 256 1043 273 1042 Z'
    ],
    'quads': [
      'M195 1100 C217 1107 241 1113 268 1112 C268 1146 252 1183 238 1206 L226 1220 C206 1219 202 1193 197 1167 C191 1145 190 1123 195 1100 Z'
    ],
    'calves': [
      'M204 1232 C200 1251 187 1271 186 1294 C184 1322 193 1361 195 1391 L208 1400 C210 1370 221 1344 232 1320 C240 1294 235 1265 224 1244 L218 1232 Z'
    ],
  },
  'female_back': {
    'upper_back': [
      'M747 826 L733 844 L710 856 L706 872 C721 878 734 893 747 914 Z'
    ],
    'lats': [
      'M702 895 C711 914 727 925 746 932 L744 969 L728 1005 C713 1000 706 985 697 972 L691 937 Z'
    ],
    'lower_back': ['M747 968 L730 997 L714 1009 L710 1024 L747 1026 Z'],
    'shoulders': [
      'M704 856 C686 851 670 865 662 882 L661 901 L674 912 C684 894 697 881 714 875 Z'
    ],
    'triceps': [
      'M674 910 C661 925 657 947 651 965 L658 980 C671 968 684 945 687 923 L682 910 Z'
    ],
    'forearms': [
      'M647 977 C632 999 622 1024 612 1050 L605 1068 L615 1078 C634 1050 651 1021 660 994 L656 981 Z'
    ],
    'glutes': [
      'M701 1037 C714 1037 732 1040 747 1041 L747 1107 C731 1117 708 1114 686 1101 L691 1069 Z'
    ],
    'hamstrings': [
      'M686 1110 C703 1119 725 1122 743 1115 C741 1150 730 1185 716 1213 L709 1224 L697 1226 C683 1197 679 1155 686 1110 Z'
    ],
    'calves': [
      'M705 1234 C690 1246 684 1270 687 1297 C690 1320 698 1334 702 1361 L708 1397 L717 1400 C718 1364 727 1339 732 1307 C735 1273 728 1246 718 1233 Z'
    ],
  },
};

class GraphiteMuscleFigure extends StatefulWidget {
  final bool female, back;
  final Set<String> primary, secondary;
  const GraphiteMuscleFigure(
      {super.key,
      required this.female,
      required this.back,
      required this.primary,
      required this.secondary});
  @override
  State<GraphiteMuscleFigure> createState() => _GraphiteMuscleFigureState();
}

class _GraphiteMuscleFigureState extends State<GraphiteMuscleFigure> {
  ImageStream? _stream;
  ImageInfo? _frame;
  late final ImageStreamListener _listener;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener((frame, _) {
      if (!mounted) {
        frame.dispose();
        return;
      }
      final old = _frame;
      setState(() {
        _frame = frame;
        _failed = false;
      });
      old?.dispose();
    }, onError: (Object error, StackTrace? stack) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(graphiteAnatomyAsset)
        .resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _failed
      ? Center(
          child: Text(fitnessText(context, 'Muscle map unavailable'),
              style: const TextStyle(fontSize: 12, color: DSColors.muted)))
      : _frame == null
          ? const Center(child: CupertinoActivityIndicator())
          : RepaintBoundary(
              child: CustomPaint(
                  isComplex: true,
                  painter: GraphiteAnatomyPainter(
                      image: _frame?.image,
                      female: widget.female,
                      back: widget.back,
                      primary: widget.primary,
                      secondary: widget.secondary)));
}

class GraphiteAnatomyPainter extends CustomPainter {
  final ui.Image? image;
  final bool female, back;
  final Set<String> primary, secondary;
  GraphiteAnatomyPainter(
      {required this.image,
      required this.female,
      required this.back,
      required this.primary,
      required this.secondary});

  Rect get viewport => Rect.fromLTRB(back ? 581 : 105, female ? 725 : 12,
      back ? 912 : 437, female ? 1464 : 704);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = image;
    if (frame == null) return;
    final box = viewport;
    final scale = math.min(size.width / box.width, size.height / box.height);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - box.width * scale) / 2,
        (size.height - box.height * scale) / 2);
    canvas.scale(scale);
    canvas.translate(-box.left, -box.top);
    canvas.clipRect(box);
    final src =
        Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble());
    const dest = Rect.fromLTWH(0, 0, 1024, 1536);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(frame, src, dest, paint);
    final paths = graphiteMusclePaths(female: female, back: back);
    void tint(Set<String> ids, Color color) {
      final mask = Path();
      for (final id in ids) {
        for (final path in paths[id] ?? <Path>[]) {
          mask.addPath(path, Offset.zero);
        }
      }
      canvas.save();
      canvas.clipPath(mask);
      canvas.drawImageRect(
          frame,
          src,
          dest,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..colorFilter = ColorFilter.mode(color, BlendMode.modulate));
      // Opaque black shorts need a restrained lift for the glute region to
      // remain legible. Screen blending retains the cloth texture underneath.
      if (ids.contains('glutes')) {
        for (final path in paths['glutes'] ?? <Path>[]) {
          canvas.drawPath(
              path,
              Paint()
                ..blendMode = BlendMode.screen
                ..color = color.withValues(
                    alpha: color == anatomyPrimary ? .28 : .13));
        }
      }
      canvas.restore();
    }

    tint(secondary.difference(primary), anatomySecondary);
    tint(primary, anatomyPrimary);
    canvas.restore();
  }

  @override
  bool shouldRepaint(GraphiteAnatomyPainter old) =>
      image != old.image ||
      female != old.female ||
      back != old.back ||
      !setEquals(primary, old.primary) ||
      !setEquals(secondary, old.secondary);
}
