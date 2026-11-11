import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/planner/repositories/weekly_plan_repository.dart';

void main() {
  test('an old plan does not count as a current plan', () {
    expect(
        PlanStatus.fromAvailability(
            {'lastPlanId': 'old', 'hasCurrentPlan': false}),
        PlanStatus.none);
    expect(
        PlanStatus.fromAvailability(
            {'lastPlanId': 'now', 'hasCurrentPlan': true}),
        PlanStatus.ready);
  });

  test('a running generation reports generating', () {
    expect(
        PlanStatus.fromAvailability({
          'lastPlanId': null,
          'hasCurrentPlan': false,
          'pendingRun': {'id': 'run'},
        }),
        PlanStatus.generating);
  });

  test('older servers fall back to lastPlanId', () {
    expect(PlanStatus.fromAvailability({'lastPlanId': 'p'}), PlanStatus.ready);
    expect(PlanStatus.fromAvailability({'lastPlanId': null}), PlanStatus.none);
  });
}
