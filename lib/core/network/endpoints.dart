// MARK: - Backend REST Endpoints Mapping
class Endpoints {
  static const String _configuredBaseUrl =
      String.fromEnvironment('FITAI_API_BASE_URL');
  static final String baseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : 'https://4266-2401-4900-1cb4-ee3e-a9de-3d34-fc2b-928c.ngrok-free.app';

  // Auth
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String socialExchange = '/api/auth/social';
  static const String refreshToken = '/api/auth/refresh';
  static const String me = '/api/auth/me';

  // Onboarding
  static const String onboarding = '/api/onboarding';

  // Home Dashboard
  static const String home = '/api/home';

  // Historical body records (new physique entries use /api/body).
  static const String bodyScanLatest = '/api/bodyscan/latest';
  static const String bodyScanHistory = '/api/bodyscan/history';
  static const String heatmapCompare = '/api/heatmap/compare';
  static String bodyScanDetail(String id) => '/api/bodyscan/$id';

  // Workout
  static const String workouts = '/api/workout';
  static const String workoutExercises = '/api/workout/exercises';
  static String workoutExerciseDetail(String id) =>
      '/api/workout/exercises/$id';
  static String userWorkouts(String day) => '/api/workout/me/$day';
  static String completeWorkoutItem(String itemId) =>
      '/api/workout/item/$itemId/complete';
  static String skipWorkoutItem(String itemId) =>
      '/api/workout/item/$itemId/skip';
  static String updateWorkoutItem(String itemId) => '/api/workout/item/$itemId';
  static const String addWorkoutItem = '/api/workout/item';
  static String deleteWorkoutItem(String itemId) => '/api/workout/item/$itemId';
  static String workoutDetail(String id) => '/api/workout/$id';
  static String completeWorkout(String id) => '/api/workout/$id/complete';

  // Nutrition
  static const String nutrition = '/api/nutrition';
  static const String nutritionItems = '/api/nutrition/items';
  static String nutritionItemDetail(String id) => '/api/nutrition/items/$id';
  static const String userNutrition = '/api/nutrition/me';
  static String userNutritionForDate(String day, String month, String year) =>
      '/api/nutrition/me/$day/$month/$year';
  static const String logMeal = '/api/nutrition/me/log';
  static String updateMealStatus(String id) =>
      '/api/nutrition/me/log/$id/status';
  static String deleteMealLog(String id) => '/api/nutrition/me/log/$id';
  static const String logWater = '/api/nutrition/water';
  static const String todayWater = '/api/nutrition/water';

  // HealthKit / Health Connect Sync
  static const String syncHealth = '/api/healthkit/sync';

  // History & Privacy
  static const String history = '/api/history';
  static const String strainHistory = '/api/history/strain';
  static const String recoveryHistory = '/api/history/recovery';
  static const String nutritionHistory = '/api/history/nutrition';
  static const String volumeHistory = '/api/history/volume';
  static const String completionHistory = '/api/history/completion';
  static const String strengthHistory = '/api/history/strength';
  static const String bodyHistory = '/api/history/body';
  static const String privacyExport = '/api/privacy/export';
  static const String deleteAccount = '/api/privacy/account';
}
