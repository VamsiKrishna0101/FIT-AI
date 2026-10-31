import 'package:setcraft/core/theme/ds_motion.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'video_cache.dart';
import 'exercise_animation.dart';
import '../localization/fitness_copy.dart';

// MARK: - FitVideoSurface
// The ONE widget used for every exercise video & animated GIF in the app.
// Original GIF frames and pooled MP4 playback share the same media surface.
// Each pipeline reports loading/failure and retains the source aspect ratio.
class FitVideoSurface extends StatefulWidget {
  final String? url;

  /// Width / height. Null = fill parent constraints.
  final double? aspectRatio;
  final BorderRadius borderRadius;
  final Alignment alignment;
  final bool autoplay;
  final bool tapToToggle;
  final Color backgroundColor;
  final bool neutralBackground;

  /// Shown until the first frame is ready (and when there is no video/gif).
  final Widget? placeholder;

  /// Media fit mode (defaults to BoxFit.contain for GIFs to prevent cropping lifters).
  final BoxFit? fit;

  /// Painted above the media (scrims, labels, badges).
  final List<Widget> overlays;

  const FitVideoSurface({
    super.key,
    required this.url,
    this.aspectRatio,
    this.borderRadius = BorderRadius.zero,
    this.alignment = Alignment.center,
    this.fit,
    this.autoplay = true,
    this.tapToToggle = false,
    this.backgroundColor = const Color(0xFF0B0C10),
    this.neutralBackground = false,
    this.placeholder,
    this.overlays = const [],
  });

  @override
  State<FitVideoSurface> createState() => _FitVideoSurfaceState();
}

class _FitVideoSurfaceState extends State<FitVideoSurface>
    with WidgetsBindingObserver {
  VideoPlayerController? _ctrl;
  String? _boundUrl;
  bool _hasFirstFrame = false;
  bool _userPaused = false;
  bool _visible = false;
  bool _videoFailed = false;
  bool _resumed = true;
  bool _lastPlaying = false;
  int _binding = 0;

  bool get _isGif => VideoAssetCache.isGif(widget.url);

  String? get _url {
    final u = widget.url?.trim();
    return VideoAssetCache.isPlayable(u) ? u : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (_visible == visible) return;
    _visible = visible;
    if (!_visible) {
      _unbind(); // The pool pauses the decoder when its last visible user leaves.
    } else if (!_isGif) {
      _bind();
    }
  }

  @override
  void didUpdateWidget(covariant FitVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url?.trim() != widget.url?.trim()) {
      _unbind();
      _videoFailed = false;
      _userPaused = false;
      if (_visible && !_isGif) _bind();
    }
  }

  void _bind() {
    final url = _url;
    if (url == null) return;
    _boundUrl = url;
    _videoFailed = false;
    final binding = ++_binding;

    // Synchronous fast-path: controller already warm → paint on first frame.
    final ready = VideoControllerPool.shared.peekReady(url);
    if (ready != null) {
      VideoControllerPool.shared.acquire(url);
      _attach(ready, immediate: true);
      return;
    }

    VideoControllerPool.shared.acquire(url).then((c) {
      if (!mounted || _boundUrl != url || binding != _binding) return;
      _attach(c);
    }).catchError((_) {
      if (mounted && _boundUrl == url && binding == _binding) {
        setState(() => _videoFailed = true);
      }
    });
  }

  void _attach(VideoPlayerController c, {bool immediate = false}) {
    _ctrl = c;
    _lastPlaying = c.value.isPlaying;
    c.addListener(_onTick);
    if (widget.autoplay && _resumed && !_userPaused) c.play();
    // Initialization provides a renderable frame even when autoplay is paused.
    _hasFirstFrame = c.value.isInitialized;
    if (!immediate) setState(() {});
  }

  void _onTick() {
    final c = _ctrl;
    if (c == null || !mounted) return;
    if (_lastPlaying != c.value.isPlaying) {
      setState(() => _lastPlaying = c.value.isPlaying);
    }
    if (c.value.hasError && !_videoFailed) {
      setState(() => _videoFailed = true);
      return;
    }
    // First decoded frame is available once position advances (or it's
    // initialized and already playing) — crossfade only then, so the user
    // never sees a black flash.
    if (!_hasFirstFrame &&
        c.value.isInitialized &&
        (c.value.position > Duration.zero || c.value.isPlaying)) {
      setState(() => _hasFirstFrame = true);
    }
  }

  void _unbind() {
    _binding++;
    final url = _boundUrl;
    _ctrl?.removeListener(_onTick);
    _ctrl = null;
    _hasFirstFrame = false;
    if (url != null) VideoControllerPool.shared.release(url);
    _boundUrl = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    final c = _ctrl;
    if (c == null) return;
    if (!_resumed) {
      c.pause();
    } else if (state == AppLifecycleState.resumed &&
        widget.autoplay &&
        _visible &&
        !_userPaused) {
      c.play();
    }
  }

  void _toggle() {
    final c = _ctrl;
    if (c == null || !c.value.isInitialized) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _userPaused = true;
      } else {
        c.play();
        _userPaused = false;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Decode original multi-frame bytes; never substitute a static poster on failure.
    if (_isGif && widget.url != null && widget.url!.trim().isNotEmpty) {
      final gifUrl = widget.url!.trim();
      final gifBody = ClipRRect(
        borderRadius: widget.borderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            gradient: widget.neutralBackground
                ? null
                : const RadialGradient(
                    center: Alignment(0, -0.1),
                    radius: 0.95,
                    colors: [
                      Color(0xFF222834), // Subtle dark studio ambient light
                      Color(0xFF13161D), // Middle tone
                      Color(0xFF090A0E), // Deep studio edge
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExerciseAnimationSurface(
                url: gifUrl,
                fit: widget.fit ?? BoxFit.contain,
                alignment: widget.alignment,
                autoplay: widget.autoplay,
                compact: widget.neutralBackground,
                controls: widget.tapToToggle,
                placeholder: widget.placeholder,
              ),
              ...widget.overlays,
            ],
          ),
        ),
      );

      final ratio = widget.aspectRatio;
      return RepaintBoundary(
        child: ratio == null
            ? gifBody
            : AspectRatio(aspectRatio: ratio, child: gifBody),
      );
    }

    // ── MP4 / Video Pipeline ──────────────────────────────────────────────────
    String copy(String text) => fitnessText(context, text);
    final media = Stack(
      fit: StackFit.expand,
      children: [
        if (widget.neutralBackground && _url != null)
          ColoredBox(color: widget.backgroundColor)
        else
          widget.placeholder ?? const _DefaultVideoPlaceholder(),
        if (_ctrl != null)
          AnimatedOpacity(
            opacity: _hasFirstFrame ? 1 : 0,
            duration: DSMotion.duration(context, DSMotion.regular),
            curve: DSMotion.effects,
            child: _CoverVideo(
              controller: _ctrl!,
              alignment: widget.alignment,
              fit: widget.fit ?? BoxFit.cover,
            ),
          ),
        ...widget.overlays,
        if (_url != null && !_hasFirstFrame && !_videoFailed)
          Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CupertinoActivityIndicator(color: Color(0xFFE2E2E2)),
            const SizedBox(height: 12),
            Text(copy('Loading demo'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF969696))),
          ])),
        if (_videoFailed)
          ColoredBox(
              color: widget.backgroundColor,
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(CupertinoIcons.play_rectangle,
                    color: Color(0xFF969696), size: 28),
                const SizedBox(height: 10),
                Text(copy('Demo unavailable'),
                    style: const TextStyle(
                        color: Color(0xFF969696), fontSize: 13)),
                TextButton(
                    onPressed: () {
                      _unbind();
                      setState(_bind);
                    },
                    child: Text(copy('Retry'),
                        style: const TextStyle(color: Color(0xFFE2E2E2)))),
              ]))),
        if (widget.tapToToggle &&
            _ctrl != null &&
            _hasFirstFrame &&
            !_ctrl!.value.isPlaying)
          const Center(child: _PlayBadge()),
      ],
    );

    final tappable = widget.tapToToggle
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: media,
          )
        : media;

    final surface = ClipRRect(
        borderRadius: widget.borderRadius,
        child: ColoredBox(
            color: widget.backgroundColor,
            child:
                widget.neutralBackground && widget.tapToToggle && _url != null
                    ? Column(children: [
                        Expanded(child: tappable),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Row(children: [
                              IconButton(
                                  key: const ValueKey('exercise-demo-play'),
                                  tooltip: copy(_ctrl?.value.isPlaying == true
                                      ? 'Pause demo'
                                      : 'Play demo'),
                                  onPressed: _hasFirstFrame && !_videoFailed
                                      ? _toggle
                                      : null,
                                  icon: Icon(
                                      _ctrl?.value.isPlaying == true
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
                                          fontSize: 11,
                                          color: Color(0xFF969696)))),
                            ])),
                      ])
                    : tappable));

    final ratio = widget.aspectRatio;
    return RepaintBoundary(
      child: ratio == null
          ? surface
          : AspectRatio(aspectRatio: ratio, child: surface),
    );
  }
}

// Cover-fit the decoded video, compensating Android rotation metadata so the
// fitted box matches what is actually rendered (prevents side/bottom gaps).
class _CoverVideo extends StatelessWidget {
  final VideoPlayerController controller;
  final Alignment alignment;
  final BoxFit fit;

  const _CoverVideo(
      {required this.controller, required this.alignment, required this.fit});

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    var size = v.size;
    if (!v.isInitialized || size.isEmpty) return const SizedBox.expand();
    final quarterTurns = (v.rotationCorrection ~/ 90) % 4;
    if (quarterTurns.isOdd) size = Size(size.height, size.width);

    return SizedBox.expand(
      child: FittedBox(
        fit: fit,
        alignment: alignment,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _DefaultVideoPlaceholder extends StatelessWidget {
  const _DefaultVideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16181E), Color(0xFF0B0C10)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: 30,
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child:
          const Icon(CupertinoIcons.play_fill, size: 18, color: Colors.white),
    );
  }
}
