import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/cache/cache_scope.dart';
import 'package:fitai_mobile/features/body_scan/models/training_map_models.dart';
import 'package:fitai_mobile/features/body_scan/views/body_training_view.dart';
import 'package:fitai_mobile/features/train/models/training_session.dart';
import 'package:fitai_mobile/features/train/repositories/training_repository.dart';

void main() {
  testWidgets(
      'Saving sets refreshes the active Body map; reactivation refreshes the inactive map',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    int loads = 0;
    int savedSets = 0;
    final date = CacheScope.todayKey();
    Future<TrainingMapData> load() async {
      loads++;
      return TrainingMapData.fromJson({
        'date': date,
        'weekStart': date,
        'regions': [],
        'summary': {'loggedSets': savedSets},
      });
    }

    Widget app(bool active) => MaterialApp(
        home:
            BodyTrainingView(isActive: active, onTrain: () {}, loadMap: load));
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(loads, 1);
    savedSets = 2;
    TrainingRepository.shared.changes
        .add(TrainingDay({'date': date, 'items': []}));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(
        tester
            .widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard))
            .data!
            .summary['loggedSets'],
        2);
    await tester.pumpWidget(app(false));
    savedSets = 3;
    TrainingRepository.shared.changes
        .add(TrainingDay({'date': date, 'items': []}));
    await tester.pumpAndSettle();
    expect(loads, 2);
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(loads, 3);
    expect(
        tester
            .widget<TrainingMapDashboard>(find.byType(TrainingMapDashboard))
            .data!
            .summary['loggedSets'],
        3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
