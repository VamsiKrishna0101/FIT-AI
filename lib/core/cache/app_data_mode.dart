import 'package:flutter/foundation.dart';
import '../storage/secure_session_store.dart';

class AppDataMode extends ChangeNotifier {
  AppDataMode._();
  static final shared = AppDataMode._();
  String? _owner;
  String? get owner => _owner;
  // Production always uses recorded data. Saved preview choices are ignored.
  bool get preview => false;
  bool get available => false;
  bool ready = false;
  int get days => 0;
  String get dataset => 'real';
  int revision = 0;

  Future<void> ensureOwner() async {
    final owner = await SecureSessionStore.shared.userId;
    if (owner == _owner) return;
    _owner = owner;
    ready = false;
    revision++;
  }

  Future<void> initialize() async {
    await ensureOwner();
    if (ready) return;
    ready = true;
    notifyListeners();
  }

  Future<void> select(bool value) async {
    await ensureOwner();
  }

  static bool scopedPath(String path) =>
      path == '/api/home' ||
      path.startsWith('/api/home?') ||
      path == '/api/body' ||
      path.startsWith('/api/body/') ||
      path.startsWith('/api/heatmap/') ||
      path.startsWith('/api/history/') ||
      path.startsWith('/api/workout/training') ||
      path.startsWith('/api/nutrition/me') ||
      path == '/api/nutrition/water' ||
      path.startsWith('/api/plans') ||
      path.startsWith('/api/wellness/');
}
