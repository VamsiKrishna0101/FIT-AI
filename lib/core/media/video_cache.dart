import 'dart:async';
import 'dart:collection';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

// MARK: - Exercise Video Disk Cache
// Videos are downloaded once and replayed from disk afterwards, so second and
// later opens start instantly (no network round-trip, no buffering).
class VideoAssetCache {
  VideoAssetCache._();

  static final CacheManager manager = CacheManager(
    Config(
      'fitai_exercise_videos',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 250,
    ),
  );

  static final Set<String> _inFlight = {};

  static bool isVideo(String? url) {
    final uri = Uri.tryParse(url?.trim() ?? '');
    if (uri == null || !['http', 'https'].contains(uri.scheme)) return false;
    final path = uri.path.toLowerCase();
    return ['.mp4', '.mov', '.m3u8', '.webm'].any(path.endsWith);
  }

  static bool isGif(String? url) {
    final uri = Uri.tryParse(url?.trim() ?? '');
    return uri != null &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.path.toLowerCase().endsWith('.gif');
  }

  static bool isPlayable(String? url) => isVideo(url);

  /// Local file if the clip is already on disk (never touches network).
  static Future<FileInfo?> cachedFile(String url) async {
    try {
      return await manager.getFileFromCache(url);
    } catch (_) {
      return null;
    }
  }

  /// Background download into the disk cache (deduplicated).
  static Future<void> prefetch(String url) async {
    if (!isPlayable(url) || _inFlight.contains(url)) return;
    _inFlight.add(url);
    try {
      final existing = await cachedFile(url);
      if (existing == null) await manager.downloadFile(url);
    } catch (_) {
      // Network failures are non-fatal; playback falls back to streaming.
    } finally {
      _inFlight.remove(url);
    }
  }

  /// Prefetch a list sequentially so the first (most important) clip wins
  /// bandwidth.
  static Future<void> prefetchAll(Iterable<String?> urls) async {
    for (final u in urls) {
      if (isPlayable(u)) await prefetch(u!.trim());
    }
  }
}

// MARK: - Shared Video Controller Pool
// One initialized controller per URL shared by every surface (home card, plan,
// detail). Navigating Home → Detail reuses the already-playing controller, so
// the detail hero shows video on its very first frame. Idle controllers are
// kept (LRU) so going back is instant too.
class VideoControllerPool {
  VideoControllerPool._();
  static final VideoControllerPool shared = VideoControllerPool._();

  static const int _maxIdle = 3;
  final LinkedHashMap<String, _PoolEntry> _entries = LinkedHashMap();

  /// Already-initialized controller for [url], or null (synchronous).
  VideoPlayerController? peekReady(String url) {
    final e = _entries[url];
    final c = e?.controller;
    return (c != null && c.value.isInitialized) ? c : null;
  }

  /// Warm a controller without holding a reference (e.g. when plan loads).
  void warm(String url) {
    if (!VideoAssetCache.isPlayable(url) || _entries.containsKey(url)) return;
    final entry = _PoolEntry();
    _entries[url] = entry;
    entry.ready = _create(url, entry);
    _dropOnFailure(url, entry);
    _evict();
  }

  Future<VideoPlayerController> acquire(String url) {
    final existing = _entries.remove(url);
    if (existing != null) {
      existing.refs++;
      _entries[url] = existing; // move to MRU
      return existing.ready;
    }
    final entry = _PoolEntry()..refs = 1;
    _entries[url] = entry;
    entry.ready = _create(url, entry);
    _dropOnFailure(url, entry);
    _evict();
    return entry.ready;
  }

  void _dropOnFailure(String url, _PoolEntry entry) {
    entry.ready.then((_) {}, onError: (_) {
      if (identical(_entries[url], entry)) _entries.remove(url);
    });
  }

  void release(String url) {
    final e = _entries[url];
    if (e == null) return;
    e.refs = (e.refs - 1).clamp(0, 1 << 20);
    if (e.refs == 0) e.controller?.pause();
    _evict();
  }

  Future<VideoPlayerController> _create(String url, _PoolEntry entry) async {
    final options = VideoPlayerOptions(mixWithOthers: true);
    VideoPlayerController controller;

    final cached = await VideoAssetCache.cachedFile(url);
    if (cached != null) {
      controller = VideoPlayerController.file(
        cached.file,
        videoPlayerOptions: options,
      );
      try {
        await controller.initialize();
      } catch (_) {
        // Corrupt cache entry → drop it and stream instead.
        await controller.dispose();
        await VideoAssetCache.manager.removeFile(url);
        controller = await _network(url, options);
      }
    } else {
      controller = await _network(url, options);
      // Save to disk in the background for instant future opens.
      unawaited(VideoAssetCache.prefetch(url));
    }

    await controller.setLooping(true);
    await controller.setVolume(0);
    if (!identical(_entries[url], entry) && entry.refs == 0) {
      await controller.dispose();
      throw StateError('Evicted before ready');
    }
    entry.controller = controller;
    return controller;
  }

  Future<VideoPlayerController> _network(
    String url,
    VideoPlayerOptions options,
  ) async {
    final c = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: options,
    );
    try {
      await c.initialize();
      return c;
    } catch (_) {
      await c.dispose();
      rethrow;
    }
  }

  void _evict() {
    final idle = _entries.entries.where((e) => e.value.refs == 0).toList();
    var overflow = idle.length - _maxIdle;
    for (final e in idle) {
      if (overflow <= 0) break;
      _entries.remove(e.key);
      e.value.controller?.dispose();
      overflow--;
    }
  }

  /// Pause everything (app backgrounded).
  void pauseAll() {
    for (final e in _entries.values) {
      e.controller?.pause();
    }
  }
}

class _PoolEntry {
  int refs = 0;
  late Future<VideoPlayerController> ready;
  VideoPlayerController? controller;
}
