import 'package:flutter_timezone/flutter_timezone.dart';
import '../../../core/network/api_client.dart';
import '../../planner/repositories/weekly_plan_repository.dart';

class StarterPlanRepository extends WeeklyPlanRepository {
  Future<void> prepareUnlock(String id) async {
    await ApiClient.shared.post<Map<String, dynamic>>(
        '/api/plans/starter/validate',
        data: {'planId': id});
  }

  Future<Map<String, dynamic>> current() async {
    final response =
        await ApiClient.shared.get<Map<String, dynamic>>('/api/plans/starter');
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }

  Future<Map<String, dynamic>> start() async {
    final zone = await FlutterTimezone.getLocalTimezone();
    final response = await ApiClient.shared.post<Map<String, dynamic>>(
        '/api/plans/starter',
        data: {'timezone': zone.identifier});
    return Map<String, dynamic>.from(response.data!['data'] as Map);
  }
}
