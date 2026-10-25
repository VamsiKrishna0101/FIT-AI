import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/cache/cache_scope.dart';

/// A dismissal belongs to an account and calendar day, not to a widget lifetime.
class DailyCheckInPrompt {
  static final _claimed = <String>{};
  static Future<bool> claim(String owner, DateTime date) async {
    if (owner == 'anonymous') return false;
    final key =
        'setcraft_check_in_prompt_v1_${owner}_${CacheScope.todayKey(date)}';
    if (!_claimed.add(key)) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) == true) return false;
      return await prefs.setBool(key, true);
    } catch (_) {
      return false;
    }
  }
}
