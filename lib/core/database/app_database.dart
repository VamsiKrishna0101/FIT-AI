import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// MARK: - 1. Cached User Profile & Biometrics
class UserProfilesTable extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get name => text().nullable()();
  TextColumn get gender => text().nullable()();
  IntColumn get age => integer().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get targetWeightKg => real().nullable()();
  TextColumn get workingToward => text().nullable()();
  TextColumn get experienceLevel => text().nullable()();
  IntColumn get daysPerWeek => integer().nullable()();
  IntColumn get workoutDuration => integer().nullable()();
  TextColumn get trainingLocation => text().nullable()();
  TextColumn get equipmentJson => text().nullable()();
  TextColumn get activityLevel => text().nullable()();
  TextColumn get sleepDuration => text().nullable()();
  TextColumn get eatingStyle => text().nullable()();
  TextColumn get customEatingStyle => text().nullable()();
  TextColumn get weeklyFoodBudget => text().nullable()();
  TextColumn get limitationsJson => text().nullable()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// MARK: - 2. Cached Today Dashboard (Zero-ms Startup & Reactive UI)
class TodayDashboardCacheTable extends Table {
  TextColumn get userId => text()();
  TextColumn get dateString => text()(); // YYYY-MM-DD
  IntColumn get caloriesTarget => integer().withDefault(const Constant(2200))();
  IntColumn get caloriesConsumed => integer().withDefault(const Constant(0))();
  IntColumn get caloriesBurned => integer().withDefault(const Constant(0))();
  IntColumn get waterTargetMl => integer().withDefault(const Constant(3000))();
  IntColumn get waterLoggedMl => integer().withDefault(const Constant(0))();
  RealColumn get readinessScore => real().withDefault(const Constant(8.5))();
  TextColumn get readinessLabel =>
      text().withDefault(const Constant('Optimal Recovery'))();
  TextColumn get todayWorkoutTitle => text().nullable()();
  IntColumn get todayWorkoutDurationMinutes => integer().nullable()();
  BoolColumn get isWorkoutCompleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get dailyQuote => text().nullable()();
  DateTimeColumn get lastCachedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId, dateString};
}

// MARK: - 3. Cached Workout Plans & Exercise Logs
class WorkoutCacheTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get dayOfWeek => text()(); // MONDAY, TUESDAY...
  IntColumn get durationMinutes => integer().withDefault(const Constant(45))();
  TextColumn get muscleGroupsJson => text().nullable()();
  TextColumn get exercisesJson => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// MARK: - 4. Cached Nutrition & Meal Logs
class NutritionCacheTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get dateString => text()();
  TextColumn get mealType => text()(); // BREAKFAST, LUNCH, DINNER, SNACK
  TextColumn get foodName => text()();
  IntColumn get calories => integer().withDefault(const Constant(0))();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fatsG => real().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// MARK: - 5. Offline Sync Outbox Queue
class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endpoint => text()();
  TextColumn get httpMethod => text()(); // POST, PUT, DELETE, PATCH
  TextColumn get payloadJson => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))(); // PENDING, FAILED
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  UserProfilesTable,
  TodayDashboardCacheTable,
  WorkoutCacheTable,
  NutritionCacheTable,
  SyncQueueTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fitai_local_store');
  }
}
