import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../core/storage/onboarding_draft.dart';

/// One draft for an onboarding flow. Screens share it through their constructors.
class OnboardingController extends ChangeNotifier with WidgetsBindingObserver {
  final Future<OnboardingDraft> Function() _load;
  final Future<void> Function(OnboardingDraft) _save;
  final Duration saveDelay;

  OnboardingDraft draft = OnboardingDraft();
  bool ready = false;
  String? saveError;
  bool _dirty = false, _disposed = false, _finished = false, _saving = false;
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  Timer? _timer;

  OnboardingController({
    Future<OnboardingDraft> Function()? load,
    Future<void> Function(OnboardingDraft)? save,
    this.saveDelay = const Duration(milliseconds: 400),
  })  : _load = load ?? OnboardingDraft.load,
        _save = save ?? ((draft) => draft.save()) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initialize() => _loading ??= _initialize();

  Future<void> _initialize() async {
    try {
      final restored = await _load();
      if (_disposed) return;
      draft = restored;
      ready = true;
      notifyListeners();
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  /// Changes are already in memory. Coalesce edits without blocking navigation.
  void checkpoint() {
    if (!ready || _finished || _disposed) return;
    _dirty = true;
    _timer?.cancel();
    _timer = Timer(saveDelay, _saveInBackground);
  }

  void _saveInBackground() {
    unawaited(flush().catchError((Object _) {
      // Keep the latest draft dirty; final submission retries and reports errors.
    }));
  }

  Future<void> flush() async {
    if (_finished) return;
    await initialize();
    _timer?.cancel();
    if (_saving) {
      await _writes;
      if (_dirty) await flush();
      return;
    }
    if (!_dirty) {
      await _writes;
      return;
    }
    _dirty = false;
    _saving = true;
    // Copy collections now so later edits cannot change a queued checkpoint.
    final snapshot = OnboardingDraft.fromJson(draft.toJson());
    final write = Future<void>.sync(() => _save(snapshot));
    _writes = write;
    try {
      await write;
      saveError = null;
    } catch (_) {
      _dirty = true;
      saveError = 'Could not save your preferences. Please try again.';
      rethrow;
    } finally {
      _saving = false;
    }
  }

  /// Called after registration succeeds and the stored draft has been cleared.
  void finish() {
    _finished = true;
    _dirty = false;
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ready &&
        !_finished &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused)) {
      _saveInBackground();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (ready && _dirty && !_finished) _saveInBackground();
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
