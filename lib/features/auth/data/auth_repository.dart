import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../core/localization/language_manager.dart';
import '../../../models/auth_models.dart';
import '../../onboarding/models/equipment_models.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient.shared;

  Future<void> sendOtp(String email) async {
    await _api.post<void>(Endpoints.sendOtp, data: {'email': email});
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await _api.post<void>(
      Endpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<AuthResponse> registerVerifiedEmail({
    required String email,
    required String password,
    required OnboardingDraft draft,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      Endpoints.register,
      data: {
        'email': email,
        'password': password,
        'onboarding': _onboardingPayload(draft),
      },
    );
    final auth = AuthResponse.fromJson(response.data!);
    await _persistSession(auth);
    await OnboardingDraft.clear();
    return auth;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      Endpoints.login,
      data: {'email': email, 'password': password},
    );
    final auth = AuthResponse.fromJson(response.data!);
    await _persistSession(auth);
    return auth;
  }

  Future<void> _persistSession(AuthResponse auth) async {
    await SecureSessionStore.shared.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      userId: auth.user.id,
    );
    await LanguageManager.shared.restoreAccountLanguage(auth.language);
  }

  Map<String, dynamic> _onboardingPayload(OnboardingDraft draft) {
    final equipment = EquipmentCatalog.backendCategories(draft.equipmentIds);
    final requiredValues = <String, Object?>{
      'goal': draft.workingToward,
      'name': draft.name,
      'age': draft.age,
      'gender': draft.gender,
      'height': draft.heightCm,
      'weight': draft.weightKg,
      'experience': draft.experienceLevel,
      'days per week': draft.daysPerWeek,
      'workout duration': draft.workoutDuration,
      'training location': draft.trainingLocation,
      'activity level': draft.activityLevel,
      'sleep duration': draft.sleepDuration,
      'eating style': draft.eatingStyle,
    };
    final missing = requiredValues.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();
    if (equipment.isEmpty) missing.add('equipment');
    if (missing.isNotEmpty) {
      throw AuthFlowException(
        'Your setup is incomplete (${missing.join(', ')}). Go back and finish those choices first.',
      );
    }

    return {
      'workingToward': draft.workingToward,
      'language': draft.languageCode,
      'name': draft.name,
      'age': draft.age,
      'gender': draft.gender,
      'height': draft.heightCm,
      'weight': draft.weightKg,
      if (draft.targetWeightKg != null) 'targetWeight': draft.targetWeightKg,
      'experience': draft.experienceLevel,
      'daysPerWeek': draft.daysPerWeek,
      'workoutDuration': draft.workoutDuration,
      'trainingLocation': draft.trainingLocation,
      'equipment': equipment,
      'equipmentIds': EquipmentCatalog.normalizeIds(draft.equipmentIds),
      'activityLevel': draft.activityLevel,
      'sleepDuration': draft.sleepDuration,
      'eatingStyle': draft.eatingStyle,
      if (draft.customEatingStyle?.trim().isNotEmpty == true)
        'customEatingStyle': draft.customEatingStyle!.trim(),
      'weeklyFoodBudget': draft.weeklyFoodBudget,
      'limitations': draft.limitations.isEmpty ? ['NONE'] : draft.limitations,
      ...draft.personalizationPayload(),
    };
  }

  static String messageFor(Object error) {
    if (error is AuthFlowException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Could not reach FitAI. Check your connection and try again.';
      }
      return 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

class AuthFlowException implements Exception {
  final String message;
  const AuthFlowException(this.message);

  @override
  String toString() => message;
}
