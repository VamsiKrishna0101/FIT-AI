import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'app_language.dart';
import '../storage/local_cache.dart';
import '../storage/onboarding_draft.dart';
import '../network/api_client.dart';
import '../storage/secure_session_store.dart';

// MARK: - App-Wide Localization Manager
class LanguageManager extends ChangeNotifier {
  static final LanguageManager shared = LanguageManager._();
  LanguageManager._();

  AppLanguage _currentLanguage = AppLanguage.uk;
  AppLanguage get currentLanguage => _currentLanguage;
  bool _saving = false;
  int _revision = 0;
  bool get saving => _saving;

  Future<void> restoreAccountLanguage(String? code) async {
    if (code == null) return;
    final match = AppLanguage.values.where((language) => language.code == code);
    if (match.isEmpty) return;
    _revision++;
    _currentLanguage = match.first;
    Intl.defaultLocale = _currentLanguage.locale.toLanguageTag();
    await LocalCache.shared.saveString(LocalCache.keyAppLanguage, code);
    notifyListeners();
  }

  Future<void> syncAccountLanguage() async {
    final revision = _revision;
    final owner = await SecureSessionStore.shared.userId;
    if (owner == null) return;
    try {
      final response =
          await ApiClient.shared.get<Map<String, dynamic>>('/api/onboarding');
      if (owner == await SecureSessionStore.shared.userId &&
          !_saving &&
          revision == _revision) {
        final data = response.data?['data'];
        if (data is Map) {
          await restoreAccountLanguage(data['language'] as String?);
        }
      }
    } catch (_) {/* Keep the last saved language when offline. */}
  }

  // Initialize from cache or system default
  Future<void> init() async {
    final savedCode =
        await LocalCache.shared.getString(LocalCache.keyAppLanguage);
    if (savedCode != null) {
      final matched = AppLanguage.values.firstWhere(
        (l) => l.code == savedCode,
        orElse: () => AppLanguage.uk,
      );
      _currentLanguage = matched;
      Intl.defaultLocale = matched.locale.toLanguageTag();
      notifyListeners();
    }
  }

  // Select new language, trigger haptic, persist locally & update draft
  Future<void> selectLanguage(AppLanguage language,
      {bool persistAccount = false}) async {
    if (_saving) return;
    _revision++;
    if (persistAccount) {
      _saving = true;
      notifyListeners();
      try {
        final owner = await SecureSessionStore.shared.userId;
        if (owner == null) throw StateError('No signed-in account');
        await ApiClient.shared
            .patch('/api/onboarding', data: {'language': language.code});
        if (owner != await SecureSessionStore.shared.userId) {
          _saving = false;
          notifyListeners();
          return;
        }
      } catch (_) {
        _saving = false;
        notifyListeners();
        rethrow;
      }
      _saving = false;
    }
    HapticFeedback.heavyImpact();
    _currentLanguage = language;
    Intl.defaultLocale = language.locale.toLanguageTag();
    notifyListeners();

    await LocalCache.shared
        .saveString(LocalCache.keyAppLanguage, language.code);

    // Sync with OnboardingDraft so registration has language ready
    final draft = await OnboardingDraft.load();
    draft.languageCode = language.code;
    await draft.save();
  }
}
