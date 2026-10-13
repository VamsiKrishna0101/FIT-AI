import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../localization/fitness_copy.dart';

/// Original animation bytes have their own cache. Poster resizing must never
/// turn a demo into a single-frame thumbnail.
class ExerciseAnimationCache {
  static final manager = CacheManager(Config('exercise_animation_originals_v1',
      stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 150));

  static Future<Uint8List> load(String url, {bool refresh = false}) async {
    if (refresh) await manager.removeFile(url);
    final file = await manager.getSingleFile(url);
    if (await file.length() > 32 * 1024 * 1024) {
      throw StateError('Animation is too large');
    }
    return file.readAsBytes();
  }
}

typedef AnimationBytesLoader = Future<Uint8List> Function(String url,
    {bool refresh});

/// Decodes the original multi-frame file, preserves its frame durations and
/// loops the exercise demo. Only the displayed frame is retained in memory.
/// Frame updates repaint the media, rather than rebuilding the exercise page.
class ExerciseAnimationController extends ChangeNotifier {
  ExerciseAnimationController({AnimationBytesLoader? loader})
      : _loader = loader ?? ExerciseAnimationCache.load;

  final AnimationBytesLoader _loader;
  final frame = ValueNotifier<ui.Image?>(null);
  ui.Codec? _codec;
  Timer? _timer;
  Duration _duration = const Duration(milliseconds: 100);
  String? _url;
  int _generation = 0;
  bool _disposed = false, _decoding = false, _active = true;
  bool _wantsPlay = true;
  bool loading = false, failed = false;
  int frameCount = 0, width = 0, height = 0;
  bool get playing =>
      _wantsPlay && _active && !loading && !failed && frameCount > 1;

  void setActive(bool active, {bool notify = true}) {
    if (_active == active || _disposed) return;
    _active = active;
    _timer?.cancel();
    _timer = null;
    _schedule();
    if (notify) notifyListeners();
  }

  void setPlaying(bool play) {
    if (_wantsPlay == play || _disposed) return;
    _wantsPlay = play;
    _timer?.cancel();
    _timer = null;
    _schedule();
    notifyListeners();
  }

  Future<void> load(String url, {bool refresh = false}) async {
    final generation = ++_generation;
    _url = url;
    _timer?.cancel();
    _timer = null;
    _codec?.dispose();
    _codec = null;
    _decoding = false;
    _replaceFrame(null);
    loading = true;
    failed = false;
    frameCount = width = height = 0;
    notifyListeners();
    // One fresh download repairs an invalid or flattened cached file.
    for (var attempt = 0; attempt < 2; attempt++) {
      ui.Codec? candidate;
      try {
        final bytes = await _loader(url, refresh: refresh || attempt > 0);
        if (_disposed || generation != _generation) return;
        candidate = await ui.instantiateImageCodec(bytes);
        if (_disposed || generation != _generation) {
          candidate.dispose();
          return;
        }
        if (candidate.frameCount < 2) {
          throw StateError('The demo has no animation frames');
        }
        _codec = candidate;
        frameCount = candidate.frameCount;
        final first = await candidate.getNextFrame();
        final firstImage = first.image;
        if (_disposed || generation != _generation) {
          firstImage.dispose();
          return;
        }
        width = firstImage.width;
        height = firstImage.height;
        _duration = _frameDuration(first.duration);
        _replaceFrame(firstImage);
        loading = false;
        notifyListeners();
        _schedule();
        return;
      } catch (_) {
        if (_disposed || generation != _generation) return;
        candidate?.dispose();
        _codec = null;
        if (attempt == 1) {
          loading = false;
          failed = true;
          frameCount = 0;
          notifyListeners();
        }
      }
    }
  }

  Future<void> retry() =>
      _url == null ? Future.value() : load(_url!, refresh: true);

  Duration _frameDuration(Duration duration) => duration.inMilliseconds < 16
      ? const Duration(milliseconds: 100)
      : duration;

  void _schedule() {
    if (!playing || _codec == null || _decoding || _timer?.isActive == true) {
      return;
    }
    _timer = Timer(_duration, _nextFrame);
  }

  Future<void> _nextFrame() async {
    final codec = _codec, generation = _generation;
    _timer = null;
    if (!playing || codec == null || _decoding) return;
    _decoding = true;
    try {
      final next = await codec.getNextFrame();
      final nextImage = next.image;
      if (_disposed || generation != _generation) {
        nextImage.dispose();
        return;
      }
      if (!playing) {
        nextImage.dispose();
        return;
      }
      _duration = _frameDuration(next.duration);
      _replaceFrame(nextImage);
    } catch (_) {
      if (!_disposed && generation == _generation) {
        failed = true;
        notifyListeners();
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _decoding = false;
        _schedule();
      }
    }
  }

  void _replaceFrame(ui.Image? image) {
    final previous = frame.value;
    frame.value = image;
    // The render object can still be painting the previous frame this turn.
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _codec?.dispose();
    final previous = frame.value;
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
    frame.dispose();
    super.dispose();
  }
}

class ExerciseAnimationSurface extends StatefulWidget {
  const ExerciseAnimationSurface(
      {super.key,
      required this.url,
      this.fit = BoxFit.contain,
      this.alignment = Alignment.center,
      this.controls = false,
      this.compact = false,
      this.autoplay = true,
      this.placeholder,
      this.controller});
  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final bool controls, compact, autoplay;
  final Widget? placeholder;
  final ExerciseAnimationController? controller;
  @override
  State<ExerciseAnimationSurface> createState() =>
      _ExerciseAnimationSurfaceState();
}

class _ExerciseAnimationSurfaceState extends State<ExerciseAnimationSurface>
    with WidgetsBindingObserver {
  late final ExerciseAnimationController _controller;
  bool _resumed = true, _visible = true, _configured = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ExerciseAnimationController();
    WidgetsBinding.instance.addObserver(this);
    _resumed = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    unawaited(_controller.load(widget.url));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    if (!_configured) {
      _configured = true;
      // A form demonstration is functional media, like an MP4, rather than a
      // decorative transition. Android animation scales must not freeze it.
      _controller.setPlaying(widget.autoplay);
    }
    _controller.setActive(_visible && _resumed);
  }

  @override
  void didUpdateWidget(covariant ExerciseAnimationSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) unawaited(_controller.load(widget.url));
    if (oldWidget.autoplay != widget.autoplay) {
      _controller.setPlaying(widget.autoplay);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _controller.setActive(_visible && _resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.setActive(false, notify: false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        String copy(String text) => fitnessText(context, text);
        final ready = !_controller.loading && !_controller.failed;
        return Column(children: [
          Expanded(
              child: ColoredBox(
                  color: ready ? Colors.white : Colors.transparent,
                  child: Stack(fit: StackFit.expand, children: [
                    if (!ready &&
                        !_controller.failed &&
                        !widget.compact &&
                        widget.placeholder != null)
                      Opacity(opacity: .12, child: widget.placeholder),
                    if (ready)
                      Center(
                          child: LayoutBuilder(builder: (context, constraints) {
                        // Fit the complete movement into the full stage without stretching or cropping.
                        final size =
                            Size(constraints.maxWidth, constraints.maxHeight);
                        return SizedBox(
                            width: size.width,
                            height: size.height,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    widget.compact ? 12 : 0),
                                child: RepaintBoundary(
                                    child: ValueListenableBuilder<ui.Image?>(
                                        valueListenable: _controller.frame,
                                        builder: (_, image, __) => ColoredBox(
                                            color: widget.compact
                                                ? Colors.white
                                                : Colors.transparent,
                                            child: RawImage(
                                                image: image,
                                                fit: widget.fit,
                                                alignment: widget.alignment,
                                                filterQuality:
                                                    FilterQuality.medium))))));
                      })),
                    if (_controller.loading)
                      Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        const CupertinoActivityIndicator(
                            color: Color(0xFFE2E2E2)),
                        const SizedBox(height: 12),
                        Text(copy('Loading demo'),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF969696))),
                      ])),
                    if (_controller.failed)
                      Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(CupertinoIcons.play_rectangle,
                            size: 28, color: Color(0xFF969696)),
                        const SizedBox(height: 10),
                        Text(copy('Demo unavailable'),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF969696))),
                        TextButton(
                            onPressed: _controller.retry,
                            child: Text(copy('Retry'),
                                style:
                                    const TextStyle(color: Color(0xFFE2E2E2)))),
                      ])),
                  ]))),
          if (widget.controls)
            Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(children: [
                  IconButton(
                      key: const ValueKey('exercise-demo-play'),
                      tooltip: copy(
                          _controller.playing ? 'Pause demo' : 'Play demo'),
                      onPressed: ready
                          ? () => _controller.setPlaying(!_controller.playing)
                          : null,
                      icon: Icon(
                          _controller.playing
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          size: 15,
                          color: const Color(0xFFE2E2E2))),
                  Expanded(
                      child: Text(copy('Exercise demo'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFB2B2B2)))),
                  const Icon(CupertinoIcons.repeat,
                      size: 14, color: Color(0xFF757575)),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(copy('Loop'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF969696)))),
                ])),
        ]);
      });
}
