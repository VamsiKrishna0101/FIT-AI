import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../train/components/graphite_anatomy.dart';

String onboardingBodyAsset({required bool female}) =>
    'assets/onboarding_bodies/${female ? 'female' : 'male'}-front.png';

const _posterior = {
  'upper_back',
  'lats',
  'lower_back',
  'triceps',
  'glutes',
  'hamstrings',
  'calves'
};
const _anterior = {'chest', 'shoulders', 'biceps', 'forearms', 'core', 'quads'};
final _frontMasks = <bool, Map<String, List<Path>>>{};

/// Registered to the original 1024 x 1536 gender-selection PNGs. These are not
/// the unrelated Body tab SVG paths. Painting and touch use the same masks.
Map<String, List<Path>> onboardingFocusPaths(
    {required bool female, required bool back}) {
  if (back) return graphiteMusclePaths(female: female, back: true);
  return _frontMasks.putIfAbsent(female, () {
    final mirror = Float64List.fromList(
        [-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1024, 0, 0, 1]);
    return {
      for (final entry in (female ? _femaleFront : _maleFront).entries)
        entry.key: [
          for (final data in entry.value) ...[
            parseSvgPathData(data),
            parseSvgPathData(data).transform(mirror),
          ]
        ]
    };
  });
}

const _maleFront = <String, List<String>>{
  'chest': [
    'M507 294 C463 276 415 276 376 295 C346 316 338 355 343 389 C374 407 421 427 459 424 L507 410 Z'
  ],
  'shoulders': [
    'M374 270 C337 270 305 291 293 323 L289 362 C304 391 326 396 344 383 C346 339 359 309 386 292 Z'
  ],
  'biceps': [
    'M321 389 C300 400 285 430 276 467 L265 498 L292 522 C317 503 335 459 342 418 L338 395 Z'
  ],
  'forearms': [
    'M269 507 C245 548 233 588 226 632 L218 714 L247 724 C270 681 284 642 294 602 L311 543 L294 517 Z'
  ],
  'core': [
    'M509 428 C467 434 422 426 366 419 L363 484 L382 548 L385 620 C425 641 465 643 509 636 Z'
  ],
  'quads': [
    'M337 865 C375 866 425 868 466 854 C477 901 462 967 445 1015 L428 1048 L402 1036 C377 1048 354 1019 348 981 Z'
  ],
  'calves': [
    'M350 1045 C337 1080 315 1116 316 1158 C317 1212 331 1263 333 1336 L376 1338 C379 1304 385 1266 402 1238 C427 1209 436 1175 432 1136 C427 1100 415 1070 425 1045 L400 1056 L378 1069 Z'
  ],
};
const _femaleFront = <String, List<String>>{
  'chest': [
    'M507 283 C471 276 438 281 416 297 C400 315 395 343 395 371 C397 408 426 435 467 435 L507 423 Z'
  ],
  'shoulders': [
    'M404 262 C382 251 355 257 337 278 C320 299 316 327 318 346 L337 359 C347 327 372 304 399 292 Z'
  ],
  'biceps': [
    'M338 355 C320 368 313 397 306 436 L300 470 L322 495 C346 468 358 423 364 392 L359 361 Z'
  ],
  'forearms': [
    'M303 495 C281 526 268 562 259 602 L239 675 L264 685 C289 646 307 614 318 575 L334 531 L324 506 Z'
  ],
  'core': [
    'M509 427 C475 435 436 421 408 421 L401 465 L417 520 L418 559 L399 588 C428 615 465 633 509 632 Z'
  ],
  'quads': [
    'M341 731 C374 751 413 780 474 806 L475 850 C469 916 449 978 435 1019 L408 1029 C382 1023 350 1006 345 964 L328 863 Z'
  ],
  'calves': [
    'M388 1021 C384 1052 377 1081 369 1114 C357 1160 369 1217 383 1267 L395 1337 L434 1338 L440 1298 C448 1266 456 1235 462 1198 C469 1160 464 1125 456 1090 L448 1040 L432 1024 Z'
  ],
};

Rect onboardingFocusViewport({required bool female, required bool back}) => back
    ? Rect.fromLTRB(581, female ? 725 : 12, 912, female ? 1464 : 704)
    : const Rect.fromLTWH(0, 0, 1024, 1536);

Rect _fitted(Rect source, Size size) {
  final scale =
      math.min(size.width / source.width, size.height / source.height);
  return Rect.fromLTWH(
      (size.width - source.width * scale) / 2,
      (size.height - source.height * scale) / 2,
      source.width * scale,
      source.height * scale);
}

/// One readable body, using the exact image from the saved gender selection.
/// Posterior priorities open the existing registered rear view automatically.
class OnboardingFocusBody extends StatefulWidget {
  final bool female;
  final Set<String> selected;
  final double height;
  final ValueChanged<String> onSelected;
  const OnboardingFocusBody(
      {super.key,
      required this.female,
      required this.selected,
      required this.onSelected,
      this.height = 360});
  @override
  State<OnboardingFocusBody> createState() => _OnboardingFocusBodyState();
}

class _OnboardingFocusBodyState extends State<OnboardingFocusBody>
    with SingleTickerProviderStateMixin {
  late final _motion =
      AnimationController(vsync: this, duration: DSMotion.selection, value: 1);
  late bool _back =
      widget.selected.isNotEmpty && widget.selected.every(_posterior.contains);
  Map<String, double> _from = {}, _to = {};
  Map<String, double> get _values => {
        for (final id in {..._from.keys, ..._to.keys})
          id: ui.lerpDouble(_from[id] ?? 0, _to[id] ?? 0,
              DSMotion.snappy.transform(_motion.value))!,
      };
  @override
  void initState() {
    super.initState();
    _from = _to = {for (final id in widget.selected) id: 1};
  }

  @override
  void didUpdateWidget(OnboardingFocusBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.female != widget.female) _back = false;
    if (setEquals(oldWidget.selected, widget.selected)) return;
    final added = widget.selected.difference(oldWidget.selected);
    if (added.isNotEmpty) {
      if (added.every(_posterior.contains)) {
        _back = true;
      } else if (added.any(_anterior.contains)) {
        _back = false;
      }
    }
    _from = _values;
    _to = {for (final id in widget.selected) id: 1};
    if (DSMotion.reduced(context)) {
      _motion.value = 1;
    } else {
      _motion.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DSMotion.reduced(context)) _motion.value = 1;
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final back in [false, true])
            Semantics(
                button: true,
                selected: _back == back,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextButton(
                        key: ValueKey('focus-body-${back ? 'back' : 'front'}'),
                        onPressed: () => setState(() => _back = back),
                        style: TextButton.styleFrom(
                            foregroundColor: _back == back
                                ? Colors.white
                                : FitnessTheme.muted,
                            backgroundColor: _back == back
                                ? const Color(0xFF242424)
                                : Colors.transparent,
                            minimumSize: const Size(90, 44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22))),
                        child: FitnessText(back ? 'Back view' : 'Front view',
                            style: const TextStyle(fontSize: 12))))),
        ]),
        const SizedBox(height: 6),
        SizedBox(
            height: widget.height,
            width: double.infinity,
            child: AnimatedBuilder(
                animation: _motion,
                builder: (context, _) => OnboardingFocusFigure(
                    female: widget.female,
                    back: _back,
                    activation: _values,
                    onSelected: widget.onSelected))),
      ]);
}

class OnboardingFocusFigure extends StatefulWidget {
  final bool female, back;
  final Map<String, double> activation;
  final ValueChanged<String> onSelected;
  const OnboardingFocusFigure(
      {super.key,
      required this.female,
      required this.back,
      required this.activation,
      required this.onSelected});
  String get asset =>
      back ? graphiteAnatomyAsset : onboardingBodyAsset(female: female);
  @override
  State<OnboardingFocusFigure> createState() => _OnboardingFocusFigureState();
}

class _OnboardingFocusFigureState extends State<OnboardingFocusFigure> {
  ImageStream? _stream;
  ImageInfo? _frame;
  late final _listener = ImageStreamListener((frame, _) {
    if (!mounted) {
      frame.dispose();
      return;
    }
    final old = _frame;
    setState(() => _frame = frame);
    old?.dispose();
  });
  void _resolve() {
    final stream = AssetImage(widget.asset)
        .resolve(createLocalImageConfiguration(context));
    if (_stream?.key == stream.key) return;
    _stream?.removeListener(_listener);
    _frame?.dispose();
    _frame = null;
    _stream = stream..addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(OnboardingFocusFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asset != oldWidget.asset) _resolve();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      image: true,
      label: fitnessText(
          context, widget.back ? 'Back muscle map' : 'Front muscle map'),
      child: LayoutBuilder(
          builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final source = onboardingFocusViewport(
                      female: widget.female, back: widget.back);
                  final fitted = _fitted(source, box.biggest);
                  if (!fitted.contains(details.localPosition)) return;
                  final scale = fitted.width / source.width;
                  final point =
                      (details.localPosition - fitted.topLeft) / scale +
                          source.topLeft;
                  for (final entry in onboardingFocusPaths(
                          female: widget.female, back: widget.back)
                      .entries) {
                    if (entry.value.any((path) => path.contains(point))) {
                      widget.onSelected(entry.key);
                      return;
                    }
                  }
                },
                child: RepaintBoundary(
                    child: CustomPaint(
                        isComplex: true,
                        painter: OnboardingFocusPainter(
                            image: _frame?.image,
                            female: widget.female,
                            back: widget.back,
                            activation: widget.activation))),
              )));
}

class OnboardingFocusPainter extends CustomPainter {
  final ui.Image? image;
  final bool female, back;
  final Map<String, double> activation;
  const OnboardingFocusPainter(
      {required this.image,
      required this.female,
      required this.back,
      required this.activation});
  static const _grey = ColorFilter.matrix([
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
  @override
  void paint(Canvas canvas, Size size) {
    final frame = image;
    if (frame == null) return;
    final source = onboardingFocusViewport(female: female, back: back);
    final fitted = _fitted(source, size);
    final scale = fitted.width / source.width;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(fitted.left, fitted.top);
    canvas.scale(scale);
    canvas.translate(-source.left, -source.top);
    canvas.clipRect(source);
    final src =
        Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble());
    const dest = Rect.fromLTWH(0, 0, 1024, 1536);
    canvas.drawImageRect(
        frame,
        src,
        dest,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = _grey);
    final paths = onboardingFocusPaths(female: female, back: back);
    for (final entry in activation.entries) {
      if (entry.value <= 0 || !paths.containsKey(entry.key)) continue;
      final mask = Path();
      for (final path in paths[entry.key]!) {
        mask.addPath(path, Offset.zero);
      }
      canvas.save();
      canvas.clipPath(mask);
      canvas.drawImageRect(
          frame,
          src,
          dest,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Colors.white.withValues(alpha: entry.value)
            ..colorFilter = back
                ? const ColorFilter.mode(anatomyPrimary, BlendMode.modulate)
                : null);
      // Clothing stays opaque; the tint marks the underlying muscle location.
      if ((female && !back && entry.key == 'chest') ||
          (back && entry.key == 'glutes')) {
        canvas.drawPath(
            mask,
            Paint()
              ..blendMode = BlendMode.screen
              ..color = anatomyPrimary.withValues(alpha: .32 * entry.value));
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(OnboardingFocusPainter old) =>
      image != old.image ||
      female != old.female ||
      back != old.back ||
      !mapEquals(activation, old.activation);
}
