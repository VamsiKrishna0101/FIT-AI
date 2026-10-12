import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../storage/secure_session_store.dart';

class PhoneSleepEstimate {
  final DateTime start, end;
  const PhoneSleepEstimate(this.start, this.end);
  int get minutes =>
      ((end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / 60000)
          .round();
  String get wakeDate =>
      '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
  static PhoneSleepEstimate? parse(Map<dynamic, dynamic> value) {
    final start = value['start'], end = value['end'];
    if (start is! num ||
        end is! num ||
        !start.isFinite ||
        !end.isFinite ||
        end <= start ||
        end - start > 86400000) {
      return null;
    }
    return PhoneSleepEstimate(
        DateTime.fromMillisecondsSinceEpoch(start.toInt()),
        DateTime.fromMillisecondsSinceEpoch(end.toInt()));
  }
}

/// Android-only, explicitly opted in. Estimates remain local until confirmed.
class PhoneSleepService {
  static final shared = PhoneSleepService();
  static const channel = MethodChannel('fitai/sleep_estimate');
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<T?> _call<T>(String method, [Map<String, dynamic>? arguments]) async {
    if (!supported) return null;
    return channel.invokeMethod<T>(method, arguments);
  }

  Future<void> setUsage(String usage, {String? expectedOwner}) async {
    await SecureSessionStore.shared.syncPhoneSleepSession();
    final owner = expectedOwner ?? await SecureSessionStore.shared.userId;
    if (owner != await SecureSessionStore.shared.userId) {
      throw StateError('Session changed');
    }
    if (owner != null) {
      await _call<void>('setUsage', {'owner': owner, 'usage': usage});
    }
  }

  Future<bool> enabled() async {
    final owner = await SecureSessionStore.shared.userId;
    return owner != null &&
        await _call<bool>('enabled', {'owner': owner}) == true;
  }

  Future<bool> start() async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) return false;
    return await _call<bool>('start', {'owner': owner}) == true;
  }

  Future<void> resume() async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner != null) await _call<bool>('resume', {'owner': owner});
  }

  Future<void> stop() async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner != null) await _call<void>('stop', {'owner': owner});
  }

  Future<PhoneSleepEstimate?> estimate(String date) async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) return null;
    final values =
        await _call<List<dynamic>>('estimates', {'owner': owner}) ?? [];
    if (owner != await SecureSessionStore.shared.userId) return null;
    final matching = values
        .whereType<Map>()
        .map(PhoneSleepEstimate.parse)
        .whereType<PhoneSleepEstimate>()
        .where((e) => e.wakeDate == date)
        .toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));
    return matching.firstOrNull;
  }
}
