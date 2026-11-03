import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Shares the compiled program, while every tank owns its uniform state.
class LiquidWaterOptics {
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram?>? _loading;

  static ui.FragmentShader? create() => _program?.fragmentShader();

  static Future<ui.FragmentProgram?> load() => _loading ??= _load();

  static Future<ui.FragmentProgram?> _load() async {
    try {
      return _program =
          await ui.FragmentProgram.fromAsset('shaders/water_optics.frag');
    } catch (error) {
      // The existing canvas renderer remains available on older backends.
      debugPrint('Water optics unavailable; using canvas lighting: $error');
      return null;
    }
  }
}
