import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/database/app_database.dart';
import 'package:setcraft/core/database/cache_manager.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late CacheManager cacheManager;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cacheManager = CacheManager.forTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift SQLite CacheManager Tests', () {
    test('upserts and retrieves Today Dashboard cached metrics', () async {
      const userId = 'user_test_123';
      const dateString = '2026-09-29';

      await cacheManager.saveTodayDashboard(
        TodayDashboardCacheTableCompanion.insert(
          userId: userId,
          dateString: dateString,
          caloriesTarget: const drift.Value(2400),
          caloriesConsumed: const drift.Value(1850),
          caloriesBurned: const drift.Value(620),
          waterTargetMl: const drift.Value(3500),
          waterLoggedMl: const drift.Value(2000),
          readinessScore: const drift.Value(9.2),
          readinessLabel: const drift.Value('Prime Condition'),
          todayWorkoutTitle: const drift.Value('Upper Body Push & Core'),
          todayWorkoutDurationMinutes: const drift.Value(50),
        ),
      );

      final cached = await cacheManager.getTodayDashboard(
        userId: userId,
        dateString: dateString,
      );

      expect(cached, isNotNull);
      expect(cached!.userId, equals(userId));
      expect(cached.caloriesTarget, equals(2400));
      expect(cached.caloriesConsumed, equals(1850));
      expect(cached.caloriesBurned, equals(620));
      expect(cached.waterLoggedMl, equals(2000));
      expect(cached.readinessScore, equals(9.2));
      expect(cached.readinessLabel, equals('Prime Condition'));
      expect(cached.todayWorkoutTitle, equals('Upper Body Push & Core'));
      expect(cached.todayWorkoutDurationMinutes, equals(50));
    });

    test('increments water intake reactively', () async {
      const userId = 'user_water_test';
      const dateString = '2026-09-29';

      await cacheManager.saveTodayDashboard(
        TodayDashboardCacheTableCompanion.insert(
          userId: userId,
          dateString: dateString,
          waterLoggedMl: const drift.Value(1000),
        ),
      );

      await cacheManager.incrementWaterLogged(
        userId: userId,
        dateString: dateString,
        amountMl: 500,
      );

      final cached = await cacheManager.getTodayDashboard(
        userId: userId,
        dateString: dateString,
      );

      expect(cached!.waterLoggedMl, equals(1500));
    });

    test('enqueues and fetches offline sync mutations', () async {
      final id1 = await cacheManager.enqueueSyncMutation(
        endpoint: '/api/nutrition/water',
        httpMethod: 'POST',
        payloadJson: '{"amountMl": 250}',
      );

      final id2 = await cacheManager.enqueueSyncMutation(
        endpoint: '/api/workout/123/complete',
        httpMethod: 'POST',
        payloadJson: '{"durationMinutes": 45}',
      );

      final pending = await cacheManager.getPendingSyncMutations();

      expect(pending.length, equals(2));
      expect(pending[0].endpoint, equals('/api/nutrition/water'));
      expect(pending[1].endpoint, equals('/api/workout/123/complete'));

      await cacheManager.deleteSyncMutation(id1);

      final remaining = await cacheManager.getPendingSyncMutations();
      expect(remaining.length, equals(1));
      expect(remaining[0].id, equals(id2));
    });

    test('streams reactive updates on today dashboard changes', () async {
      const userId = 'user_stream_test';
      const dateString = '2026-09-29';

      final stream = cacheManager.watchTodayDashboard(
        userId: userId,
        dateString: dateString,
      );

      expectLater(
        stream,
        emitsInOrder([
          isNull, // Initially empty
          predicate<TodayDashboardCacheTableData>(
            (d) => d.caloriesConsumed == 500,
          ),
          predicate<TodayDashboardCacheTableData>(
            (d) => d.caloriesConsumed == 1200,
          ),
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await cacheManager.saveTodayDashboard(
        TodayDashboardCacheTableCompanion.insert(
          userId: userId,
          dateString: dateString,
          caloriesConsumed: const drift.Value(500),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      await cacheManager.saveTodayDashboard(
        TodayDashboardCacheTableCompanion.insert(
          userId: userId,
          dateString: dateString,
          caloriesConsumed: const drift.Value(1200),
        ),
      );
    });
  });
}
