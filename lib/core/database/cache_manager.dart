import 'package:drift/drift.dart';
import 'app_database.dart';

// MARK: - Centralized UI & Offline Cache Manager
class CacheManager {
  static final CacheManager shared = CacheManager._(AppDatabase());
  final AppDatabase db;

  CacheManager._(this.db);

  CacheManager.forTesting(this.db);

  // ── 1. Today Dashboard Reactive UI Caching ──────────────────────────────
  Stream<TodayDashboardCacheTableData?> watchTodayDashboard({
    required String userId,
    required String dateString,
  }) {
    return (db.select(db.todayDashboardCacheTable)
          ..where(
              (t) => t.userId.equals(userId) & t.dateString.equals(dateString)))
        .watchSingleOrNull();
  }

  Future<TodayDashboardCacheTableData?> getTodayDashboard({
    required String userId,
    required String dateString,
  }) {
    return (db.select(db.todayDashboardCacheTable)
          ..where(
              (t) => t.userId.equals(userId) & t.dateString.equals(dateString)))
        .getSingleOrNull();
  }

  Future<void> saveTodayDashboard(
      TodayDashboardCacheTableCompanion entry) async {
    await db.into(db.todayDashboardCacheTable).insertOnConflictUpdate(entry);
  }

  Future<void> incrementWaterLogged({
    required String userId,
    required String dateString,
    required int amountMl,
  }) async {
    final current = await getTodayDashboard(
      userId: userId,
      dateString: dateString,
    );
    if (current != null) {
      final updated = current.waterLoggedMl + amountMl;
      await (db.update(db.todayDashboardCacheTable)
            ..where((t) =>
                t.userId.equals(userId) & t.dateString.equals(dateString)))
          .write(TodayDashboardCacheTableCompanion(
        waterLoggedMl: Value(updated),
        lastCachedAt: Value(DateTime.now()),
      ));
    } else {
      await saveTodayDashboard(TodayDashboardCacheTableCompanion.insert(
        userId: userId,
        dateString: dateString,
        waterLoggedMl: Value(amountMl),
      ));
    }
  }

  // ── 2. User Profile Reactive Caching ─────────────────────────────────────
  Stream<UserProfilesTableData?> watchUserProfile(String userId) {
    return (db.select(db.userProfilesTable)..where((t) => t.id.equals(userId)))
        .watchSingleOrNull();
  }

  Future<UserProfilesTableData?> getUserProfile(String userId) {
    return (db.select(db.userProfilesTable)..where((t) => t.id.equals(userId)))
        .getSingleOrNull();
  }

  Future<void> saveUserProfile(UserProfilesTableCompanion profile) {
    return db.into(db.userProfilesTable).insertOnConflictUpdate(profile);
  }

  // ── 3. Workouts Caching ──────────────────────────────────────────────────
  Stream<List<WorkoutCacheTableData>> watchWorkouts(String userId) {
    return (db.select(db.workoutCacheTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .watch();
  }

  Future<void> saveWorkouts(List<WorkoutCacheTableCompanion> workouts) {
    return db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.workoutCacheTable, workouts);
    });
  }

  Future<void> setWorkoutCompleted({
    required String workoutId,
    required bool isCompleted,
  }) {
    return (db.update(db.workoutCacheTable)
          ..where((t) => t.id.equals(workoutId)))
        .write(WorkoutCacheTableCompanion(
      isCompleted: Value(isCompleted),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── 4. Nutrition & Meal Logs Caching ─────────────────────────────────────
  Stream<List<NutritionCacheTableData>> watchMealLogs({
    required String userId,
    required String dateString,
  }) {
    return (db.select(db.nutritionCacheTable)
          ..where(
              (t) => t.userId.equals(userId) & t.dateString.equals(dateString))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .watch();
  }

  Future<void> saveMeal(NutritionCacheTableCompanion meal) {
    return db.into(db.nutritionCacheTable).insertOnConflictUpdate(meal);
  }

  // ── 5. Offline Sync Outbox Queue ─────────────────────────────────────────
  Future<int> enqueueSyncMutation({
    required String endpoint,
    required String httpMethod,
    required String payloadJson,
  }) {
    return db.into(db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            endpoint: endpoint,
            httpMethod: httpMethod,
            payloadJson: payloadJson,
          ),
        );
  }

  Future<List<SyncQueueTableData>> getPendingSyncMutations() {
    return (db.select(db.syncQueueTable)
          ..where((t) => t.status.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deleteSyncMutation(int id) {
    return (db.delete(db.syncQueueTable)..where((t) => t.id.equals(id))).go();
  }

  // ── 6. Purge All Data (User Sign Out) ────────────────────────────────────
  Future<void> clearAll() async {
    await db.delete(db.todayDashboardCacheTable).go();
    await db.delete(db.workoutCacheTable).go();
    await db.delete(db.nutritionCacheTable).go();
    await db.delete(db.userProfilesTable).go();
    await db.delete(db.syncQueueTable).go();
  }
}
