import 'settings_account_repository.dart';

class PrivacyRepository extends SettingsAccountRepository {
  Future<Map<String, dynamic>> configuration() async =>
      Map<String, dynamic>.from(
          await request('GET', '/api/support/config') as Map);
  Future<Map<String, dynamic>> consent() async => Map<String, dynamic>.from(
      await request('GET', '/api/privacy/consent') as Map);
  Future<Map<String, dynamic>> setAiConsent(
          bool granted, String version) async =>
      Map<String, dynamic>.from(await request('PUT', '/api/privacy/consent',
          data: {
            'aiPlanningConsent': granted,
            'aiPlanningPolicyVersion': version
          }) as Map);
}
