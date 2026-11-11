import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/endpoints.dart';
import '../../../core/storage/local_cache.dart';
import '../../profile/repositories/support_repository.dart';
import '../views/rate_app_modal.dart';

/// Service managing the 30-day "Rate Our App" cadence and dynamic store redirection.
class RateAppService {
  RateAppService._();
  static final shared = RateAppService._();

  static const String _keyLastPrompt = 'rate_app_last_prompt_epoch';
  static const String _keyHasRated = 'rate_app_has_rated';
  static const String _keyFirstSeen = 'rate_app_first_seen_epoch';

  /// Standard 30-day interval between rating prompts.
  static const int minDaysBetweenPrompts = 30;

  /// Grace period in days from install before the first rating prompt can appear.
  static const int minDaysBeforeFirstPrompt = 3;

  bool _isPrompting = false;

  /// Checks whether the user is eligible for the rating prompt based on
  /// 30-day elapsed time and install date.
  Future<bool> shouldPrompt() async {
    final now = DateTime.now();

    final hasRated = await LocalCache.shared.getString(_keyHasRated);
    if (hasRated == 'true') return false;

    // Check first launch timestamp so new users are not interrupted immediately.
    final firstSeenStr = await LocalCache.shared.getString(_keyFirstSeen);
    if (firstSeenStr == null) {
      await LocalCache.shared.saveString(
        _keyFirstSeen,
        now.millisecondsSinceEpoch.toString(),
      );
      return false;
    }

    final firstSeenEpoch = int.tryParse(firstSeenStr);
    if (firstSeenEpoch != null) {
      final daysSinceInstall =
          now.difference(DateTime.fromMillisecondsSinceEpoch(firstSeenEpoch)).inDays;
      if (daysSinceInstall < minDaysBeforeFirstPrompt) {
        return false;
      }
    }

    // Check last prompt date (every 30 days)
    final lastPromptStr = await LocalCache.shared.getString(_keyLastPrompt);
    if (lastPromptStr == null) {
      return true;
    }

    final lastPromptEpoch = int.tryParse(lastPromptStr);
    if (lastPromptEpoch == null) return true;

    final daysSincePrompt =
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastPromptEpoch)).inDays;
    return daysSincePrompt >= minDaysBetweenPrompts;
  }

  /// Evaluates eligibility and presents the premium modal if appropriate.
  Future<bool> maybePrompt(BuildContext context) async {
    if (_isPrompting) return false;
    if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }

    final eligible = await shouldPrompt();
    if (!eligible) return false;

    _isPrompting = true;
    try {
      if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) {
        return false;
      }
      final result = await RateAppModal.show(context);
      // Advance prompt timestamp so user isn't prompted again within 30 days
      await recordPromptShown();
      return result ?? false;
    } finally {
      _isPrompting = false;
    }
  }

  /// Records that the prompt was shown, scheduling the next check in 30 days.
  Future<void> recordPromptShown() async {
    await LocalCache.shared.saveString(
      _keyLastPrompt,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Marks the app as rated so the prompt will not appear automatically again.
  Future<void> recordUserRated() async {
    await LocalCache.shared.saveString(_keyHasRated, 'true');
    await recordPromptShown();
  }

  /// Dynamically retrieves the review URL from the backend config,
  /// falling back to the backend redirect route or official fallback.
  Future<String> fetchReviewUrl() async {
    try {
      final repo = SupportRepository();
      final config = await repo.configuration().timeout(const Duration(seconds: 4));
      final remoteUrl = config['rateAppUrl'];
      if (remoteUrl is String && remoteUrl.trim().isNotEmpty) {
        return remoteUrl.trim();
      }
    } catch (_) {
      // Backend config offline or unauthenticated; fallback to direct redirect endpoint.
    }
    return '${Endpoints.baseUrl}/api/support/rate';
  }

  /// Opens the store review URL in an external browser or app store client.
  Future<bool> openReviewUrl() async {
    try {
      final url = await fetchReviewUrl();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await recordUserRated();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
