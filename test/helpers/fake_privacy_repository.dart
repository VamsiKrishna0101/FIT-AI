import 'package:setcraft/features/profile/repositories/privacy_repository.dart';

class FakePrivacyRepository extends PrivacyRepository {
  final Map<String, dynamic> config = {
    'privacyPolicyUrl': 'https://example.invalid/privacy',
    'termsUrl': 'https://example.invalid/terms',
    'aiProvider': 'OpenAI',
    'aiPolicyVersion': 'test-v1'
  };
  final Map<String, dynamic> values = {
    'aiPlanningConsent': false,
    'aiPlanningPolicyVersion': null
  };
  final List<bool> changes = [];
  bool fail = false;
  @override
  Future<Map<String, dynamic>> configuration() async => Map.from(config);
  @override
  Future<Map<String, dynamic>> consent() async => Map.from(values);
  bool apple = false;
  @override
  Future<bool> usesAppleSignIn() async => apple;
  @override
  Future<Map<String, dynamic>> setAiConsent(
      bool granted, String version) async {
    if (fail) throw StateError('Could not save. Please try again.');
    changes.add(granted);
    values.addAll(
        {'aiPlanningConsent': granted, 'aiPlanningPolicyVersion': version});
    return Map.from(values);
  }
}
