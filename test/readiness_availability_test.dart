import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/today/models/readiness_availability.dart';
import 'package:fitai_mobile/models/home_models.dart';

void main() {
  test(
      'Movement-only sync identifies both missing inputs without a connect prompt',
      () {
    final status = ReadinessAvailability.fromMetrics(const HomeHealthMetrics(
        date: '2026-10-10', source: 'health_connect', steps: 100));
    expect(status.synced, true);
    expect(status.sleep, false);
    expect(status.heart, false);
    expect(status.title, 'Health data synced');
    expect(status.description, contains('Both are still missing'));
  });
  test('Sleep without heart readings names the remaining input', () {
    final status = ReadinessAvailability.fromMetrics(const HomeHealthMetrics(
        date: '2026-10-10', source: 'health_connect', sleepMinutes: 420));
    expect(status.sleep, true);
    expect(status.heart, false);
    expect(status.description, contains('resting heart rate or HRV'));
  });
  test('Heart without sleep names the remaining input', () {
    final status = ReadinessAvailability.fromMetrics(const HomeHealthMetrics(
        date: '2026-10-10', source: 'healthkit', restingHR: 60));
    expect(status.sleep, false);
    expect(status.heart, true);
    expect(status.description, contains('Sleep is still missing'));
  });
  test('A missing dated snapshot is distinct from successful sync', () {
    final status = ReadinessAvailability.fromMetrics(null);
    expect(status.synced, false);
    expect(status.title, 'No readiness for this day');
  });
}
