import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Decode the local video's first frame while startup is already preparing.
abstract final class WelcomeVideoPreload {
  static VideoPlayerController? _ready;
  static Future<void>? _warming;
  static VideoPlayerController create() => VideoPlayerController.asset(
      'assets/branding/setcraft-welcome-reference.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
  static Future<void> prepare() => _warming ??= _prepare();
  static Future<void> _prepare() async {
    final controller = create();
    try {
      await controller.initialize().timeout(const Duration(seconds: 2));
      await controller.setVolume(0);
      await controller.setLooping(true);
      _ready = controller;
    } catch (_) {
      unawaited(controller.dispose());
    }
  }

  static VideoPlayerController? take() {
    final controller = _ready;
    _ready = null;
    _warming = null;
    return controller;
  }
}

/// Muted local video only. No poster, replacement image or network loading.
class WelcomeBackgroundVideo extends StatefulWidget {
  const WelcomeBackgroundVideo({super.key});
  @override
  State<WelcomeBackgroundVideo> createState() => _WelcomeBackgroundVideoState();
}

class _WelcomeBackgroundVideoState extends State<WelcomeBackgroundVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _reduced = false, _visible = true;
  AppLifecycleState? _lifecycle;
  @override
  void initState() {
    super.initState();
    _controller = WelcomeVideoPreload.take();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    if (_controller == null && _canPlay) {
      unawaited(_initialize());
    } else {
      unawaited(_syncPlayback());
    }
  }

  bool get _canPlay =>
      !_reduced &&
      _visible &&
      (_lifecycle == null || _lifecycle == AppLifecycleState.resumed);
  Future<void> _initialize() async {
    final controller = WelcomeVideoPreload.create();
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!mounted) return;
      await _syncPlayback();
      if (mounted) setState(() {});
    } catch (_) {/* Keep setup usable on a plain black canvas. */}
  }

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (_canPlay) {
        await controller.play();
      } else {
        await controller.pause();
      }
    } catch (_) {/* Playback must not interrupt setup. */}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    unawaited(_syncPlayback());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ExcludeSemantics(
        child: ColoredBox(
      color: const Color(0xFF000000),
      child: controller == null || !controller.value.isInitialized
          ? const SizedBox.expand()
          : ClipRect(
              child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller)))),
    ));
  }
}
