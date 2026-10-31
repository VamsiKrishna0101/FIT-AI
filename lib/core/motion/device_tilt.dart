import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GravitySample {
  final double x, y, z;
  const GravitySample(this.x, this.y, [this.z = 0]);

  bool get hasScreenGravity =>
      x.isFinite && y.isFinite && x * x + y * y > .0144;

  double pitch() {
    if (!x.isFinite || !y.isFinite || !z.isFinite) return 0;
    if (x.abs() + y.abs() + z.abs() < .15) return 0;
    return -math.atan2(z, math.sqrt(x * x + y * y));
  }

  double angle({bool landscape = false}) {
    if (!x.isFinite || !y.isFinite || x.abs() + y.abs() < .15) return 0;
    final horizontal = landscape ? (x < 0 ? -y : y) : x;
    final vertical = landscape ? x.abs() : -y;
    return -math.atan2(horizontal, vertical);
  }
}

class DeviceTilt {
  static const _control = MethodChannel('setcraft/hydration_motion_control');
  static final _events =
      const EventChannel('setcraft/hydration_motion').receiveBroadcastStream();
  static Future<bool>? _available;
  static Future<bool> _supported() async {
    if (kIsWeb ||
        ![TargetPlatform.android, TargetPlatform.iOS]
            .contains(defaultTargetPlatform)) {
      return false;
    }
    try {
      return await _control.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// A shared native broadcast starts on the first listener and stops on the last.
  static Stream<GravitySample> get samples async* {
    if (!await (_available ??= _supported())) return;
    await for (final event in _events) {
      if (event is List &&
          event.length >= 2 &&
          event[0] is num &&
          event[1] is num) {
        final x = (event[0] as num).toDouble(),
            y = (event[1] as num).toDouble();
        final z = event.length > 2 && event[2] is num
            ? (event[2] as num).toDouble()
            : 0.0;
        if (x.isFinite && y.isFinite && z.isFinite) {
          yield GravitySample(x, y, z);
        }
      }
    }
  }
}
