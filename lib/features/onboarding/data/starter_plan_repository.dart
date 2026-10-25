import 'package:flutter_timezone/flutter_timezone.dart';
import '../../../core/network/api_client.dart';
import '../../planner/repositories/weekly_plan_repository.dart';
import 'discovery_repository.dart';

class StarterEntryPreparation {
  final Map<String, dynamic>? data;
  final DiscoveryPreparation? discovery;
  const StarterEntryPreparation(this.data, {this.discovery});

  static bool shouldOffer(Map<String, dynamic>? data) {
    final run = data?['run'];
    return data?['eligible'] == true ||
        (data?['hasAccess'] == true &&
            run is Map &&
            (run['plan'] is! Map || (run['plan'] as Map)['status'] == 'DRAFT'));
  }
}

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
