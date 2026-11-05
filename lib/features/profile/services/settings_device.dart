import 'dart:convert';
import 'package:flutter/services.dart';

class SettingsDevice {
  static const channel = MethodChannel('setcraft/settings');
  static Future<Map<String, dynamic>> info() async => Map<String, dynamic>.from(
      await channel.invokeMapMethod<String, dynamic>('appInfo') ?? {});
  static Future<void> shareExport(Map<String, dynamic> data) async {
    await channel.invokeMethod<void>('shareExport',
        {'json': const JsonEncoder.withIndent('  ').convert(data)});
  }

  static Future<void> clearExports() async {
    try {
      await channel.invokeMethod<void>('clearExports');
    } on PlatformException {
      /* Retry at the next native start. */
    } on MissingPluginException {/* Older binary. */}
  }
}
