// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserProfilesTableTable extends UserProfilesTable
    with TableInfo<$UserProfilesTableTable, UserProfilesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _targetWeightKgMeta =
      const VerificationMeta('targetWeightKg');
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
      'target_weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _workingTowardMeta =
      const VerificationMeta('workingToward');
  @override
  late final GeneratedColumn<String> workingToward = GeneratedColumn<String>(
      'working_toward', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _experienceLevelMeta =
      const VerificationMeta('experienceLevel');
  @override
  late final GeneratedColumn<String> experienceLevel = GeneratedColumn<String>(
      'experience_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _daysPerWeekMeta =
      const VerificationMeta('daysPerWeek');
  @override
  late final GeneratedColumn<int> daysPerWeek = GeneratedColumn<int>(
      'days_per_week', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _workoutDurationMeta =
      const VerificationMeta('workoutDuration');
  @override
  late final GeneratedColumn<int> workoutDuration = GeneratedColumn<int>(
      'workout_duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _trainingLocationMeta =
      const VerificationMeta('trainingLocation');
  @override
  late final GeneratedColumn<String> trainingLocation = GeneratedColumn<String>(
      'training_location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _equipmentJsonMeta =
      const VerificationMeta('equipmentJson');
  @override
  late final GeneratedColumn<String> equipmentJson = GeneratedColumn<String>(
      'equipment_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activityLevelMeta =
      const VerificationMeta('activityLevel');
  @override
  late final GeneratedColumn<String> activityLevel = GeneratedColumn<String>(
      'activity_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sleepDurationMeta =
      const VerificationMeta('sleepDuration');
  @override
  late final GeneratedColumn<String> sleepDuration = GeneratedColumn<String>(
      'sleep_duration', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _eatingStyleMeta =
      const VerificationMeta('eatingStyle');
  @override
  late final GeneratedColumn<String> eatingStyle = GeneratedColumn<String>(
      'eating_style', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customEatingStyleMeta =
      const VerificationMeta('customEatingStyle');
  @override
  late final GeneratedColumn<String> customEatingStyle =
      GeneratedColumn<String>('custom_eating_style', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weeklyFoodBudgetMeta =
      const VerificationMeta('weeklyFoodBudget');
  @override
  late final GeneratedColumn<String> weeklyFoodBudget = GeneratedColumn<String>(
      'weekly_food_budget', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _limitationsJsonMeta =
      const VerificationMeta('limitationsJson');
  @override
  late final GeneratedColumn<String> limitationsJson = GeneratedColumn<String>(
      'limitations_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currentStreakMeta =
      const VerificationMeta('currentStreak');
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
      'current_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        email,
        name,
        gender,
        age,
        heightCm,
        weightKg,
        targetWeightKg,
        workingToward,
        experienceLevel,
        daysPerWeek,
        workoutDuration,
        trainingLocation,
        equipmentJson,
        activityLevel,
        sleepDuration,
        eatingStyle,
        customEatingStyle,
        weeklyFoodBudget,
        limitationsJson,
        currentStreak,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserProfilesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
          _targetWeightKgMeta,
          targetWeightKg.isAcceptableOrUnknown(
              data['target_weight_kg']!, _targetWeightKgMeta));
    }
    if (data.containsKey('working_toward')) {
      context.handle(
          _workingTowardMeta,
          workingToward.isAcceptableOrUnknown(
              data['working_toward']!, _workingTowardMeta));
    }
    if (data.containsKey('experience_level')) {
      context.handle(
          _experienceLevelMeta,
          experienceLevel.isAcceptableOrUnknown(
              data['experience_level']!, _experienceLevelMeta));
    }
    if (data.containsKey('days_per_week')) {
      context.handle(
          _daysPerWeekMeta,
          daysPerWeek.isAcceptableOrUnknown(
              data['days_per_week']!, _daysPerWeekMeta));
    }
    if (data.containsKey('workout_duration')) {
      context.handle(
          _workoutDurationMeta,
          workoutDuration.isAcceptableOrUnknown(
              data['workout_duration']!, _workoutDurationMeta));
    }
    if (data.containsKey('training_location')) {
      context.handle(
          _trainingLocationMeta,
          trainingLocation.isAcceptableOrUnknown(
              data['training_location']!, _trainingLocationMeta));
    }
    if (data.containsKey('equipment_json')) {
      context.handle(
          _equipmentJsonMeta,
          equipmentJson.isAcceptableOrUnknown(
              data['equipment_json']!, _equipmentJsonMeta));
    }
    if (data.containsKey('activity_level')) {
      context.handle(
          _activityLevelMeta,
          activityLevel.isAcceptableOrUnknown(
              data['activity_level']!, _activityLevelMeta));
    }
    if (data.containsKey('sleep_duration')) {
      context.handle(
          _sleepDurationMeta,
          sleepDuration.isAcceptableOrUnknown(
              data['sleep_duration']!, _sleepDurationMeta));
    }
    if (data.containsKey('eating_style')) {
      context.handle(
          _eatingStyleMeta,
          eatingStyle.isAcceptableOrUnknown(
              data['eating_style']!, _eatingStyleMeta));
    }
    if (data.containsKey('custom_eating_style')) {
      context.handle(
          _customEatingStyleMeta,
          customEatingStyle.isAcceptableOrUnknown(
              data['custom_eating_style']!, _customEatingStyleMeta));
    }
    if (data.containsKey('weekly_food_budget')) {
      context.handle(
          _weeklyFoodBudgetMeta,
          weeklyFoodBudget.isAcceptableOrUnknown(
              data['weekly_food_budget']!, _weeklyFoodBudgetMeta));
    }
    if (data.containsKey('limitations_json')) {
      context.handle(
          _limitationsJsonMeta,
          limitationsJson.isAcceptableOrUnknown(
              data['limitations_json']!, _limitationsJsonMeta));
    }
    if (data.containsKey('current_streak')) {
      context.handle(
          _currentStreakMeta,
          currentStreak.isAcceptableOrUnknown(
              data['current_streak']!, _currentStreakMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfilesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfilesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age']),
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm']),
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg']),
      targetWeightKg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}target_weight_kg']),
      workingToward: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}working_toward']),
      experienceLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}experience_level']),
      daysPerWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}days_per_week']),
      workoutDuration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}workout_duration']),
      trainingLocation: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}training_location']),
      equipmentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipment_json']),
      activityLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_level']),
      sleepDuration: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sleep_duration']),
      eatingStyle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}eating_style']),
      customEatingStyle: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_eating_style']),
      weeklyFoodBudget: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}weekly_food_budget']),
      limitationsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}limitations_json']),
      currentStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_streak'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserProfilesTableTable createAlias(String alias) {
    return $UserProfilesTableTable(attachedDatabase, alias);
  }
}

class UserProfilesTableData extends DataClass
    implements Insertable<UserProfilesTableData> {
  final String id;
  final String email;
  final String? name;
  final String? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String? workingToward;
  final String? experienceLevel;
  final int? daysPerWeek;
  final int? workoutDuration;
  final String? trainingLocation;
  final String? equipmentJson;
  final String? activityLevel;
  final String? sleepDuration;
  final String? eatingStyle;
  final String? customEatingStyle;
  final String? weeklyFoodBudget;
  final String? limitationsJson;
  final int currentStreak;
  final DateTime updatedAt;
  const UserProfilesTableData(
      {required this.id,
      required this.email,
      this.name,
      this.gender,
      this.age,
      this.heightCm,
      this.weightKg,
      this.targetWeightKg,
      this.workingToward,
      this.experienceLevel,
      this.daysPerWeek,
      this.workoutDuration,
      this.trainingLocation,
      this.equipmentJson,
      this.activityLevel,
      this.sleepDuration,
      this.eatingStyle,
      this.customEatingStyle,
      this.weeklyFoodBudget,
      this.limitationsJson,
      required this.currentStreak,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || targetWeightKg != null) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg);
    }
    if (!nullToAbsent || workingToward != null) {
      map['working_toward'] = Variable<String>(workingToward);
    }
    if (!nullToAbsent || experienceLevel != null) {
      map['experience_level'] = Variable<String>(experienceLevel);
    }
    if (!nullToAbsent || daysPerWeek != null) {
      map['days_per_week'] = Variable<int>(daysPerWeek);
    }
    if (!nullToAbsent || workoutDuration != null) {
      map['workout_duration'] = Variable<int>(workoutDuration);
    }
    if (!nullToAbsent || trainingLocation != null) {
      map['training_location'] = Variable<String>(trainingLocation);
    }
    if (!nullToAbsent || equipmentJson != null) {
      map['equipment_json'] = Variable<String>(equipmentJson);
    }
    if (!nullToAbsent || activityLevel != null) {
      map['activity_level'] = Variable<String>(activityLevel);
    }
    if (!nullToAbsent || sleepDuration != null) {
      map['sleep_duration'] = Variable<String>(sleepDuration);
    }
    if (!nullToAbsent || eatingStyle != null) {
      map['eating_style'] = Variable<String>(eatingStyle);
    }
    if (!nullToAbsent || customEatingStyle != null) {
      map['custom_eating_style'] = Variable<String>(customEatingStyle);
    }
    if (!nullToAbsent || weeklyFoodBudget != null) {
      map['weekly_food_budget'] = Variable<String>(weeklyFoodBudget);
    }
    if (!nullToAbsent || limitationsJson != null) {
      map['limitations_json'] = Variable<String>(limitationsJson);
    }
    map['current_streak'] = Variable<int>(currentStreak);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfilesTableCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesTableCompanion(
      id: Value(id),
      email: Value(email),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      targetWeightKg: targetWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeightKg),
      workingToward: workingToward == null && nullToAbsent
          ? const Value.absent()
          : Value(workingToward),
      experienceLevel: experienceLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(experienceLevel),
      daysPerWeek: daysPerWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(daysPerWeek),
      workoutDuration: workoutDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutDuration),
      trainingLocation: trainingLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(trainingLocation),
      equipmentJson: equipmentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(equipmentJson),
      activityLevel: activityLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(activityLevel),
      sleepDuration: sleepDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepDuration),
      eatingStyle: eatingStyle == null && nullToAbsent
          ? const Value.absent()
          : Value(eatingStyle),
      customEatingStyle: customEatingStyle == null && nullToAbsent
          ? const Value.absent()
          : Value(customEatingStyle),
      weeklyFoodBudget: weeklyFoodBudget == null && nullToAbsent
          ? const Value.absent()
          : Value(weeklyFoodBudget),
      limitationsJson: limitationsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(limitationsJson),
      currentStreak: Value(currentStreak),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfilesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfilesTableData(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      name: serializer.fromJson<String?>(json['name']),
      gender: serializer.fromJson<String?>(json['gender']),
      age: serializer.fromJson<int?>(json['age']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      targetWeightKg: serializer.fromJson<double?>(json['targetWeightKg']),
      workingToward: serializer.fromJson<String?>(json['workingToward']),
      experienceLevel: serializer.fromJson<String?>(json['experienceLevel']),
      daysPerWeek: serializer.fromJson<int?>(json['daysPerWeek']),
      workoutDuration: serializer.fromJson<int?>(json['workoutDuration']),
      trainingLocation: serializer.fromJson<String?>(json['trainingLocation']),
      equipmentJson: serializer.fromJson<String?>(json['equipmentJson']),
      activityLevel: serializer.fromJson<String?>(json['activityLevel']),
      sleepDuration: serializer.fromJson<String?>(json['sleepDuration']),
      eatingStyle: serializer.fromJson<String?>(json['eatingStyle']),
      customEatingStyle:
          serializer.fromJson<String?>(json['customEatingStyle']),
      weeklyFoodBudget: serializer.fromJson<String?>(json['weeklyFoodBudget']),
      limitationsJson: serializer.fromJson<String?>(json['limitationsJson']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'name': serializer.toJson<String?>(name),
      'gender': serializer.toJson<String?>(gender),
      'age': serializer.toJson<int?>(age),
      'heightCm': serializer.toJson<double?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'targetWeightKg': serializer.toJson<double?>(targetWeightKg),
      'workingToward': serializer.toJson<String?>(workingToward),
      'experienceLevel': serializer.toJson<String?>(experienceLevel),
      'daysPerWeek': serializer.toJson<int?>(daysPerWeek),
      'workoutDuration': serializer.toJson<int?>(workoutDuration),
      'trainingLocation': serializer.toJson<String?>(trainingLocation),
      'equipmentJson': serializer.toJson<String?>(equipmentJson),
      'activityLevel': serializer.toJson<String?>(activityLevel),
      'sleepDuration': serializer.toJson<String?>(sleepDuration),
      'eatingStyle': serializer.toJson<String?>(eatingStyle),
      'customEatingStyle': serializer.toJson<String?>(customEatingStyle),
      'weeklyFoodBudget': serializer.toJson<String?>(weeklyFoodBudget),
      'limitationsJson': serializer.toJson<String?>(limitationsJson),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfilesTableData copyWith(
          {String? id,
          String? email,
          Value<String?> name = const Value.absent(),
          Value<String?> gender = const Value.absent(),
          Value<int?> age = const Value.absent(),
          Value<double?> heightCm = const Value.absent(),
          Value<double?> weightKg = const Value.absent(),
          Value<double?> targetWeightKg = const Value.absent(),
          Value<String?> workingToward = const Value.absent(),
          Value<String?> experienceLevel = const Value.absent(),
          Value<int?> daysPerWeek = const Value.absent(),
          Value<int?> workoutDuration = const Value.absent(),
          Value<String?> trainingLocation = const Value.absent(),
          Value<String?> equipmentJson = const Value.absent(),
          Value<String?> activityLevel = const Value.absent(),
          Value<String?> sleepDuration = const Value.absent(),
          Value<String?> eatingStyle = const Value.absent(),
          Value<String?> customEatingStyle = const Value.absent(),
          Value<String?> weeklyFoodBudget = const Value.absent(),
          Value<String?> limitationsJson = const Value.absent(),
          int? currentStreak,
          DateTime? updatedAt}) =>
      UserProfilesTableData(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name.present ? name.value : this.name,
        gender: gender.present ? gender.value : this.gender,
        age: age.present ? age.value : this.age,
        heightCm: heightCm.present ? heightCm.value : this.heightCm,
        weightKg: weightKg.present ? weightKg.value : this.weightKg,
        targetWeightKg:
            targetWeightKg.present ? targetWeightKg.value : this.targetWeightKg,
        workingToward:
            workingToward.present ? workingToward.value : this.workingToward,
        experienceLevel: experienceLevel.present
            ? experienceLevel.value
            : this.experienceLevel,
        daysPerWeek: daysPerWeek.present ? daysPerWeek.value : this.daysPerWeek,
        workoutDuration: workoutDuration.present
            ? workoutDuration.value
            : this.workoutDuration,
        trainingLocation: trainingLocation.present
            ? trainingLocation.value
            : this.trainingLocation,
        equipmentJson:
            equipmentJson.present ? equipmentJson.value : this.equipmentJson,
        activityLevel:
            activityLevel.present ? activityLevel.value : this.activityLevel,
        sleepDuration:
            sleepDuration.present ? sleepDuration.value : this.sleepDuration,
        eatingStyle: eatingStyle.present ? eatingStyle.value : this.eatingStyle,
        customEatingStyle: customEatingStyle.present
            ? customEatingStyle.value
            : this.customEatingStyle,
        weeklyFoodBudget: weeklyFoodBudget.present
            ? weeklyFoodBudget.value
            : this.weeklyFoodBudget,
        limitationsJson: limitationsJson.present
            ? limitationsJson.value
            : this.limitationsJson,
        currentStreak: currentStreak ?? this.currentStreak,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserProfilesTableData copyWithCompanion(UserProfilesTableCompanion data) {
    return UserProfilesTableData(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      name: data.name.present ? data.name.value : this.name,
      gender: data.gender.present ? data.gender.value : this.gender,
      age: data.age.present ? data.age.value : this.age,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      workingToward: data.workingToward.present
          ? data.workingToward.value
          : this.workingToward,
      experienceLevel: data.experienceLevel.present
          ? data.experienceLevel.value
          : this.experienceLevel,
      daysPerWeek:
          data.daysPerWeek.present ? data.daysPerWeek.value : this.daysPerWeek,
      workoutDuration: data.workoutDuration.present
          ? data.workoutDuration.value
          : this.workoutDuration,
      trainingLocation: data.trainingLocation.present
          ? data.trainingLocation.value
          : this.trainingLocation,
      equipmentJson: data.equipmentJson.present
          ? data.equipmentJson.value
          : this.equipmentJson,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      sleepDuration: data.sleepDuration.present
          ? data.sleepDuration.value
          : this.sleepDuration,
      eatingStyle:
          data.eatingStyle.present ? data.eatingStyle.value : this.eatingStyle,
      customEatingStyle: data.customEatingStyle.present
          ? data.customEatingStyle.value
          : this.customEatingStyle,
      weeklyFoodBudget: data.weeklyFoodBudget.present
          ? data.weeklyFoodBudget.value
          : this.weeklyFoodBudget,
      limitationsJson: data.limitationsJson.present
          ? data.limitationsJson.value
          : this.limitationsJson,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesTableData(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('workingToward: $workingToward, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('workoutDuration: $workoutDuration, ')
          ..write('trainingLocation: $trainingLocation, ')
          ..write('equipmentJson: $equipmentJson, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('sleepDuration: $sleepDuration, ')
          ..write('eatingStyle: $eatingStyle, ')
          ..write('customEatingStyle: $customEatingStyle, ')
          ..write('weeklyFoodBudget: $weeklyFoodBudget, ')
          ..write('limitationsJson: $limitationsJson, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        email,
        name,
        gender,
        age,
        heightCm,
        weightKg,
        targetWeightKg,
        workingToward,
        experienceLevel,
        daysPerWeek,
        workoutDuration,
        trainingLocation,
        equipmentJson,
        activityLevel,
        sleepDuration,
        eatingStyle,
        customEatingStyle,
        weeklyFoodBudget,
        limitationsJson,
        currentStreak,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfilesTableData &&
          other.id == this.id &&
          other.email == this.email &&
          other.name == this.name &&
          other.gender == this.gender &&
          other.age == this.age &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.targetWeightKg == this.targetWeightKg &&
          other.workingToward == this.workingToward &&
          other.experienceLevel == this.experienceLevel &&
          other.daysPerWeek == this.daysPerWeek &&
          other.workoutDuration == this.workoutDuration &&
          other.trainingLocation == this.trainingLocation &&
          other.equipmentJson == this.equipmentJson &&
          other.activityLevel == this.activityLevel &&
          other.sleepDuration == this.sleepDuration &&
          other.eatingStyle == this.eatingStyle &&
          other.customEatingStyle == this.customEatingStyle &&
          other.weeklyFoodBudget == this.weeklyFoodBudget &&
          other.limitationsJson == this.limitationsJson &&
          other.currentStreak == this.currentStreak &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesTableCompanion
    extends UpdateCompanion<UserProfilesTableData> {
  final Value<String> id;
  final Value<String> email;
  final Value<String?> name;
  final Value<String?> gender;
  final Value<int?> age;
  final Value<double?> heightCm;
  final Value<double?> weightKg;
  final Value<double?> targetWeightKg;
  final Value<String?> workingToward;
  final Value<String?> experienceLevel;
  final Value<int?> daysPerWeek;
  final Value<int?> workoutDuration;
  final Value<String?> trainingLocation;
  final Value<String?> equipmentJson;
  final Value<String?> activityLevel;
  final Value<String?> sleepDuration;
  final Value<String?> eatingStyle;
  final Value<String?> customEatingStyle;
  final Value<String?> weeklyFoodBudget;
  final Value<String?> limitationsJson;
  final Value<int> currentStreak;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfilesTableCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.name = const Value.absent(),
    this.gender = const Value.absent(),
    this.age = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.workingToward = const Value.absent(),
    this.experienceLevel = const Value.absent(),
    this.daysPerWeek = const Value.absent(),
    this.workoutDuration = const Value.absent(),
    this.trainingLocation = const Value.absent(),
    this.equipmentJson = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.sleepDuration = const Value.absent(),
    this.eatingStyle = const Value.absent(),
    this.customEatingStyle = const Value.absent(),
    this.weeklyFoodBudget = const Value.absent(),
    this.limitationsJson = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesTableCompanion.insert({
    required String id,
    required String email,
    this.name = const Value.absent(),
    this.gender = const Value.absent(),
    this.age = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.workingToward = const Value.absent(),
    this.experienceLevel = const Value.absent(),
    this.daysPerWeek = const Value.absent(),
    this.workoutDuration = const Value.absent(),
    this.trainingLocation = const Value.absent(),
    this.equipmentJson = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.sleepDuration = const Value.absent(),
    this.eatingStyle = const Value.absent(),
    this.customEatingStyle = const Value.absent(),
    this.weeklyFoodBudget = const Value.absent(),
    this.limitationsJson = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        email = Value(email);
  static Insertable<UserProfilesTableData> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? name,
    Expression<String>? gender,
    Expression<int>? age,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<double>? targetWeightKg,
    Expression<String>? workingToward,
    Expression<String>? experienceLevel,
    Expression<int>? daysPerWeek,
    Expression<int>? workoutDuration,
    Expression<String>? trainingLocation,
    Expression<String>? equipmentJson,
    Expression<String>? activityLevel,
    Expression<String>? sleepDuration,
    Expression<String>? eatingStyle,
    Expression<String>? customEatingStyle,
    Expression<String>? weeklyFoodBudget,
    Expression<String>? limitationsJson,
    Expression<int>? currentStreak,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (workingToward != null) 'working_toward': workingToward,
      if (experienceLevel != null) 'experience_level': experienceLevel,
      if (daysPerWeek != null) 'days_per_week': daysPerWeek,
      if (workoutDuration != null) 'workout_duration': workoutDuration,
      if (trainingLocation != null) 'training_location': trainingLocation,
      if (equipmentJson != null) 'equipment_json': equipmentJson,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (sleepDuration != null) 'sleep_duration': sleepDuration,
      if (eatingStyle != null) 'eating_style': eatingStyle,
      if (customEatingStyle != null) 'custom_eating_style': customEatingStyle,
      if (weeklyFoodBudget != null) 'weekly_food_budget': weeklyFoodBudget,
      if (limitationsJson != null) 'limitations_json': limitationsJson,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? email,
      Value<String?>? name,
      Value<String?>? gender,
      Value<int?>? age,
      Value<double?>? heightCm,
      Value<double?>? weightKg,
      Value<double?>? targetWeightKg,
      Value<String?>? workingToward,
      Value<String?>? experienceLevel,
      Value<int?>? daysPerWeek,
      Value<int?>? workoutDuration,
      Value<String?>? trainingLocation,
      Value<String?>? equipmentJson,
      Value<String?>? activityLevel,
      Value<String?>? sleepDuration,
      Value<String?>? eatingStyle,
      Value<String?>? customEatingStyle,
      Value<String?>? weeklyFoodBudget,
      Value<String?>? limitationsJson,
      Value<int>? currentStreak,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserProfilesTableCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      workingToward: workingToward ?? this.workingToward,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      trainingLocation: trainingLocation ?? this.trainingLocation,
      equipmentJson: equipmentJson ?? this.equipmentJson,
      activityLevel: activityLevel ?? this.activityLevel,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      eatingStyle: eatingStyle ?? this.eatingStyle,
      customEatingStyle: customEatingStyle ?? this.customEatingStyle,
      weeklyFoodBudget: weeklyFoodBudget ?? this.weeklyFoodBudget,
      limitationsJson: limitationsJson ?? this.limitationsJson,
      currentStreak: currentStreak ?? this.currentStreak,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (workingToward.present) {
      map['working_toward'] = Variable<String>(workingToward.value);
    }
    if (experienceLevel.present) {
      map['experience_level'] = Variable<String>(experienceLevel.value);
    }
    if (daysPerWeek.present) {
      map['days_per_week'] = Variable<int>(daysPerWeek.value);
    }
    if (workoutDuration.present) {
      map['workout_duration'] = Variable<int>(workoutDuration.value);
    }
    if (trainingLocation.present) {
      map['training_location'] = Variable<String>(trainingLocation.value);
    }
    if (equipmentJson.present) {
      map['equipment_json'] = Variable<String>(equipmentJson.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(activityLevel.value);
    }
    if (sleepDuration.present) {
      map['sleep_duration'] = Variable<String>(sleepDuration.value);
    }
    if (eatingStyle.present) {
      map['eating_style'] = Variable<String>(eatingStyle.value);
    }
    if (customEatingStyle.present) {
      map['custom_eating_style'] = Variable<String>(customEatingStyle.value);
    }
    if (weeklyFoodBudget.present) {
      map['weekly_food_budget'] = Variable<String>(weeklyFoodBudget.value);
    }
    if (limitationsJson.present) {
      map['limitations_json'] = Variable<String>(limitationsJson.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesTableCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('workingToward: $workingToward, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('workoutDuration: $workoutDuration, ')
          ..write('trainingLocation: $trainingLocation, ')
          ..write('equipmentJson: $equipmentJson, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('sleepDuration: $sleepDuration, ')
          ..write('eatingStyle: $eatingStyle, ')
          ..write('customEatingStyle: $customEatingStyle, ')
          ..write('weeklyFoodBudget: $weeklyFoodBudget, ')
          ..write('limitationsJson: $limitationsJson, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodayDashboardCacheTableTable extends TodayDashboardCacheTable
    with
        TableInfo<$TodayDashboardCacheTableTable,
            TodayDashboardCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodayDashboardCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateStringMeta =
      const VerificationMeta('dateString');
  @override
  late final GeneratedColumn<String> dateString = GeneratedColumn<String>(
      'date_string', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caloriesTargetMeta =
      const VerificationMeta('caloriesTarget');
  @override
  late final GeneratedColumn<int> caloriesTarget = GeneratedColumn<int>(
      'calories_target', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2200));
  static const VerificationMeta _caloriesConsumedMeta =
      const VerificationMeta('caloriesConsumed');
  @override
  late final GeneratedColumn<int> caloriesConsumed = GeneratedColumn<int>(
      'calories_consumed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _caloriesBurnedMeta =
      const VerificationMeta('caloriesBurned');
  @override
  late final GeneratedColumn<int> caloriesBurned = GeneratedColumn<int>(
      'calories_burned', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _waterTargetMlMeta =
      const VerificationMeta('waterTargetMl');
  @override
  late final GeneratedColumn<int> waterTargetMl = GeneratedColumn<int>(
      'water_target_ml', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3000));
  static const VerificationMeta _waterLoggedMlMeta =
      const VerificationMeta('waterLoggedMl');
  @override
  late final GeneratedColumn<int> waterLoggedMl = GeneratedColumn<int>(
      'water_logged_ml', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _readinessScoreMeta =
      const VerificationMeta('readinessScore');
  @override
  late final GeneratedColumn<double> readinessScore = GeneratedColumn<double>(
      'readiness_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(8.5));
  static const VerificationMeta _readinessLabelMeta =
      const VerificationMeta('readinessLabel');
  @override
  late final GeneratedColumn<String> readinessLabel = GeneratedColumn<String>(
      'readiness_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Optimal Recovery'));
  static const VerificationMeta _todayWorkoutTitleMeta =
      const VerificationMeta('todayWorkoutTitle');
  @override
  late final GeneratedColumn<String> todayWorkoutTitle =
      GeneratedColumn<String>('today_workout_title', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _todayWorkoutDurationMinutesMeta =
      const VerificationMeta('todayWorkoutDurationMinutes');
  @override
  late final GeneratedColumn<int> todayWorkoutDurationMinutes =
      GeneratedColumn<int>('today_workout_duration_minutes', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isWorkoutCompletedMeta =
      const VerificationMeta('isWorkoutCompleted');
  @override
  late final GeneratedColumn<bool> isWorkoutCompleted = GeneratedColumn<bool>(
      'is_workout_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_workout_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dailyQuoteMeta =
      const VerificationMeta('dailyQuote');
  @override
  late final GeneratedColumn<String> dailyQuote = GeneratedColumn<String>(
      'daily_quote', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastCachedAtMeta =
      const VerificationMeta('lastCachedAt');
  @override
  late final GeneratedColumn<DateTime> lastCachedAt = GeneratedColumn<DateTime>(
      'last_cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        dateString,
        caloriesTarget,
        caloriesConsumed,
        caloriesBurned,
        waterTargetMl,
        waterLoggedMl,
        readinessScore,
        readinessLabel,
        todayWorkoutTitle,
        todayWorkoutDurationMinutes,
        isWorkoutCompleted,
        dailyQuote,
        lastCachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'today_dashboard_cache_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<TodayDashboardCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('date_string')) {
      context.handle(
          _dateStringMeta,
          dateString.isAcceptableOrUnknown(
              data['date_string']!, _dateStringMeta));
    } else if (isInserting) {
      context.missing(_dateStringMeta);
    }
    if (data.containsKey('calories_target')) {
      context.handle(
          _caloriesTargetMeta,
          caloriesTarget.isAcceptableOrUnknown(
              data['calories_target']!, _caloriesTargetMeta));
    }
    if (data.containsKey('calories_consumed')) {
      context.handle(
          _caloriesConsumedMeta,
          caloriesConsumed.isAcceptableOrUnknown(
              data['calories_consumed']!, _caloriesConsumedMeta));
    }
    if (data.containsKey('calories_burned')) {
      context.handle(
          _caloriesBurnedMeta,
          caloriesBurned.isAcceptableOrUnknown(
              data['calories_burned']!, _caloriesBurnedMeta));
    }
    if (data.containsKey('water_target_ml')) {
      context.handle(
          _waterTargetMlMeta,
          waterTargetMl.isAcceptableOrUnknown(
              data['water_target_ml']!, _waterTargetMlMeta));
    }
    if (data.containsKey('water_logged_ml')) {
      context.handle(
          _waterLoggedMlMeta,
          waterLoggedMl.isAcceptableOrUnknown(
              data['water_logged_ml']!, _waterLoggedMlMeta));
    }
    if (data.containsKey('readiness_score')) {
      context.handle(
          _readinessScoreMeta,
          readinessScore.isAcceptableOrUnknown(
              data['readiness_score']!, _readinessScoreMeta));
    }
    if (data.containsKey('readiness_label')) {
      context.handle(
          _readinessLabelMeta,
          readinessLabel.isAcceptableOrUnknown(
              data['readiness_label']!, _readinessLabelMeta));
    }
    if (data.containsKey('today_workout_title')) {
      context.handle(
          _todayWorkoutTitleMeta,
          todayWorkoutTitle.isAcceptableOrUnknown(
              data['today_workout_title']!, _todayWorkoutTitleMeta));
    }
    if (data.containsKey('today_workout_duration_minutes')) {
      context.handle(
          _todayWorkoutDurationMinutesMeta,
          todayWorkoutDurationMinutes.isAcceptableOrUnknown(
              data['today_workout_duration_minutes']!,
              _todayWorkoutDurationMinutesMeta));
    }
    if (data.containsKey('is_workout_completed')) {
      context.handle(
          _isWorkoutCompletedMeta,
          isWorkoutCompleted.isAcceptableOrUnknown(
              data['is_workout_completed']!, _isWorkoutCompletedMeta));
    }
    if (data.containsKey('daily_quote')) {
      context.handle(
          _dailyQuoteMeta,
          dailyQuote.isAcceptableOrUnknown(
              data['daily_quote']!, _dailyQuoteMeta));
    }
    if (data.containsKey('last_cached_at')) {
      context.handle(
          _lastCachedAtMeta,
          lastCachedAt.isAcceptableOrUnknown(
              data['last_cached_at']!, _lastCachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, dateString};
  @override
  TodayDashboardCacheTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodayDashboardCacheTableData(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      dateString: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_string'])!,
      caloriesTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories_target'])!,
      caloriesConsumed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories_consumed'])!,
      caloriesBurned: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories_burned'])!,
      waterTargetMl: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}water_target_ml'])!,
      waterLoggedMl: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}water_logged_ml'])!,
      readinessScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}readiness_score'])!,
      readinessLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}readiness_label'])!,
      todayWorkoutTitle: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}today_workout_title']),
      todayWorkoutDurationMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}today_workout_duration_minutes']),
      isWorkoutCompleted: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_workout_completed'])!,
      dailyQuote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}daily_quote']),
      lastCachedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_cached_at'])!,
    );
  }

  @override
  $TodayDashboardCacheTableTable createAlias(String alias) {
    return $TodayDashboardCacheTableTable(attachedDatabase, alias);
  }
}

class TodayDashboardCacheTableData extends DataClass
    implements Insertable<TodayDashboardCacheTableData> {
  final String userId;
  final String dateString;
  final int caloriesTarget;
  final int caloriesConsumed;
  final int caloriesBurned;
  final int waterTargetMl;
  final int waterLoggedMl;
  final double readinessScore;
  final String readinessLabel;
  final String? todayWorkoutTitle;
  final int? todayWorkoutDurationMinutes;
  final bool isWorkoutCompleted;
  final String? dailyQuote;
  final DateTime lastCachedAt;
  const TodayDashboardCacheTableData(
      {required this.userId,
      required this.dateString,
      required this.caloriesTarget,
      required this.caloriesConsumed,
      required this.caloriesBurned,
      required this.waterTargetMl,
      required this.waterLoggedMl,
      required this.readinessScore,
      required this.readinessLabel,
      this.todayWorkoutTitle,
      this.todayWorkoutDurationMinutes,
      required this.isWorkoutCompleted,
      this.dailyQuote,
      required this.lastCachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['date_string'] = Variable<String>(dateString);
    map['calories_target'] = Variable<int>(caloriesTarget);
    map['calories_consumed'] = Variable<int>(caloriesConsumed);
    map['calories_burned'] = Variable<int>(caloriesBurned);
    map['water_target_ml'] = Variable<int>(waterTargetMl);
    map['water_logged_ml'] = Variable<int>(waterLoggedMl);
    map['readiness_score'] = Variable<double>(readinessScore);
    map['readiness_label'] = Variable<String>(readinessLabel);
    if (!nullToAbsent || todayWorkoutTitle != null) {
      map['today_workout_title'] = Variable<String>(todayWorkoutTitle);
    }
    if (!nullToAbsent || todayWorkoutDurationMinutes != null) {
      map['today_workout_duration_minutes'] =
          Variable<int>(todayWorkoutDurationMinutes);
    }
    map['is_workout_completed'] = Variable<bool>(isWorkoutCompleted);
    if (!nullToAbsent || dailyQuote != null) {
      map['daily_quote'] = Variable<String>(dailyQuote);
    }
    map['last_cached_at'] = Variable<DateTime>(lastCachedAt);
    return map;
  }

  TodayDashboardCacheTableCompanion toCompanion(bool nullToAbsent) {
    return TodayDashboardCacheTableCompanion(
      userId: Value(userId),
      dateString: Value(dateString),
      caloriesTarget: Value(caloriesTarget),
      caloriesConsumed: Value(caloriesConsumed),
      caloriesBurned: Value(caloriesBurned),
      waterTargetMl: Value(waterTargetMl),
      waterLoggedMl: Value(waterLoggedMl),
      readinessScore: Value(readinessScore),
      readinessLabel: Value(readinessLabel),
      todayWorkoutTitle: todayWorkoutTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(todayWorkoutTitle),
      todayWorkoutDurationMinutes:
          todayWorkoutDurationMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(todayWorkoutDurationMinutes),
      isWorkoutCompleted: Value(isWorkoutCompleted),
      dailyQuote: dailyQuote == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyQuote),
      lastCachedAt: Value(lastCachedAt),
    );
  }

  factory TodayDashboardCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodayDashboardCacheTableData(
      userId: serializer.fromJson<String>(json['userId']),
      dateString: serializer.fromJson<String>(json['dateString']),
      caloriesTarget: serializer.fromJson<int>(json['caloriesTarget']),
      caloriesConsumed: serializer.fromJson<int>(json['caloriesConsumed']),
      caloriesBurned: serializer.fromJson<int>(json['caloriesBurned']),
      waterTargetMl: serializer.fromJson<int>(json['waterTargetMl']),
      waterLoggedMl: serializer.fromJson<int>(json['waterLoggedMl']),
      readinessScore: serializer.fromJson<double>(json['readinessScore']),
      readinessLabel: serializer.fromJson<String>(json['readinessLabel']),
      todayWorkoutTitle:
          serializer.fromJson<String?>(json['todayWorkoutTitle']),
      todayWorkoutDurationMinutes:
          serializer.fromJson<int?>(json['todayWorkoutDurationMinutes']),
      isWorkoutCompleted: serializer.fromJson<bool>(json['isWorkoutCompleted']),
      dailyQuote: serializer.fromJson<String?>(json['dailyQuote']),
      lastCachedAt: serializer.fromJson<DateTime>(json['lastCachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'dateString': serializer.toJson<String>(dateString),
      'caloriesTarget': serializer.toJson<int>(caloriesTarget),
      'caloriesConsumed': serializer.toJson<int>(caloriesConsumed),
      'caloriesBurned': serializer.toJson<int>(caloriesBurned),
      'waterTargetMl': serializer.toJson<int>(waterTargetMl),
      'waterLoggedMl': serializer.toJson<int>(waterLoggedMl),
      'readinessScore': serializer.toJson<double>(readinessScore),
      'readinessLabel': serializer.toJson<String>(readinessLabel),
      'todayWorkoutTitle': serializer.toJson<String?>(todayWorkoutTitle),
      'todayWorkoutDurationMinutes':
          serializer.toJson<int?>(todayWorkoutDurationMinutes),
      'isWorkoutCompleted': serializer.toJson<bool>(isWorkoutCompleted),
      'dailyQuote': serializer.toJson<String?>(dailyQuote),
      'lastCachedAt': serializer.toJson<DateTime>(lastCachedAt),
    };
  }

  TodayDashboardCacheTableData copyWith(
          {String? userId,
          String? dateString,
          int? caloriesTarget,
          int? caloriesConsumed,
          int? caloriesBurned,
          int? waterTargetMl,
          int? waterLoggedMl,
          double? readinessScore,
          String? readinessLabel,
          Value<String?> todayWorkoutTitle = const Value.absent(),
          Value<int?> todayWorkoutDurationMinutes = const Value.absent(),
          bool? isWorkoutCompleted,
          Value<String?> dailyQuote = const Value.absent(),
          DateTime? lastCachedAt}) =>
      TodayDashboardCacheTableData(
        userId: userId ?? this.userId,
        dateString: dateString ?? this.dateString,
        caloriesTarget: caloriesTarget ?? this.caloriesTarget,
        caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
        caloriesBurned: caloriesBurned ?? this.caloriesBurned,
        waterTargetMl: waterTargetMl ?? this.waterTargetMl,
        waterLoggedMl: waterLoggedMl ?? this.waterLoggedMl,
        readinessScore: readinessScore ?? this.readinessScore,
        readinessLabel: readinessLabel ?? this.readinessLabel,
        todayWorkoutTitle: todayWorkoutTitle.present
            ? todayWorkoutTitle.value
            : this.todayWorkoutTitle,
        todayWorkoutDurationMinutes: todayWorkoutDurationMinutes.present
            ? todayWorkoutDurationMinutes.value
            : this.todayWorkoutDurationMinutes,
        isWorkoutCompleted: isWorkoutCompleted ?? this.isWorkoutCompleted,
        dailyQuote: dailyQuote.present ? dailyQuote.value : this.dailyQuote,
        lastCachedAt: lastCachedAt ?? this.lastCachedAt,
      );
  TodayDashboardCacheTableData copyWithCompanion(
      TodayDashboardCacheTableCompanion data) {
    return TodayDashboardCacheTableData(
      userId: data.userId.present ? data.userId.value : this.userId,
      dateString:
          data.dateString.present ? data.dateString.value : this.dateString,
      caloriesTarget: data.caloriesTarget.present
          ? data.caloriesTarget.value
          : this.caloriesTarget,
      caloriesConsumed: data.caloriesConsumed.present
          ? data.caloriesConsumed.value
          : this.caloriesConsumed,
      caloriesBurned: data.caloriesBurned.present
          ? data.caloriesBurned.value
          : this.caloriesBurned,
      waterTargetMl: data.waterTargetMl.present
          ? data.waterTargetMl.value
          : this.waterTargetMl,
      waterLoggedMl: data.waterLoggedMl.present
          ? data.waterLoggedMl.value
          : this.waterLoggedMl,
      readinessScore: data.readinessScore.present
          ? data.readinessScore.value
          : this.readinessScore,
      readinessLabel: data.readinessLabel.present
          ? data.readinessLabel.value
          : this.readinessLabel,
      todayWorkoutTitle: data.todayWorkoutTitle.present
          ? data.todayWorkoutTitle.value
          : this.todayWorkoutTitle,
      todayWorkoutDurationMinutes: data.todayWorkoutDurationMinutes.present
          ? data.todayWorkoutDurationMinutes.value
          : this.todayWorkoutDurationMinutes,
      isWorkoutCompleted: data.isWorkoutCompleted.present
          ? data.isWorkoutCompleted.value
          : this.isWorkoutCompleted,
      dailyQuote:
          data.dailyQuote.present ? data.dailyQuote.value : this.dailyQuote,
      lastCachedAt: data.lastCachedAt.present
          ? data.lastCachedAt.value
          : this.lastCachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodayDashboardCacheTableData(')
          ..write('userId: $userId, ')
          ..write('dateString: $dateString, ')
          ..write('caloriesTarget: $caloriesTarget, ')
          ..write('caloriesConsumed: $caloriesConsumed, ')
          ..write('caloriesBurned: $caloriesBurned, ')
          ..write('waterTargetMl: $waterTargetMl, ')
          ..write('waterLoggedMl: $waterLoggedMl, ')
          ..write('readinessScore: $readinessScore, ')
          ..write('readinessLabel: $readinessLabel, ')
          ..write('todayWorkoutTitle: $todayWorkoutTitle, ')
          ..write('todayWorkoutDurationMinutes: $todayWorkoutDurationMinutes, ')
          ..write('isWorkoutCompleted: $isWorkoutCompleted, ')
          ..write('dailyQuote: $dailyQuote, ')
          ..write('lastCachedAt: $lastCachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId,
      dateString,
      caloriesTarget,
      caloriesConsumed,
      caloriesBurned,
      waterTargetMl,
      waterLoggedMl,
      readinessScore,
      readinessLabel,
      todayWorkoutTitle,
      todayWorkoutDurationMinutes,
      isWorkoutCompleted,
      dailyQuote,
      lastCachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodayDashboardCacheTableData &&
          other.userId == this.userId &&
          other.dateString == this.dateString &&
          other.caloriesTarget == this.caloriesTarget &&
          other.caloriesConsumed == this.caloriesConsumed &&
          other.caloriesBurned == this.caloriesBurned &&
          other.waterTargetMl == this.waterTargetMl &&
          other.waterLoggedMl == this.waterLoggedMl &&
          other.readinessScore == this.readinessScore &&
          other.readinessLabel == this.readinessLabel &&
          other.todayWorkoutTitle == this.todayWorkoutTitle &&
          other.todayWorkoutDurationMinutes ==
              this.todayWorkoutDurationMinutes &&
          other.isWorkoutCompleted == this.isWorkoutCompleted &&
          other.dailyQuote == this.dailyQuote &&
          other.lastCachedAt == this.lastCachedAt);
}

class TodayDashboardCacheTableCompanion
    extends UpdateCompanion<TodayDashboardCacheTableData> {
  final Value<String> userId;
  final Value<String> dateString;
  final Value<int> caloriesTarget;
  final Value<int> caloriesConsumed;
  final Value<int> caloriesBurned;
  final Value<int> waterTargetMl;
  final Value<int> waterLoggedMl;
  final Value<double> readinessScore;
  final Value<String> readinessLabel;
  final Value<String?> todayWorkoutTitle;
  final Value<int?> todayWorkoutDurationMinutes;
  final Value<bool> isWorkoutCompleted;
  final Value<String?> dailyQuote;
  final Value<DateTime> lastCachedAt;
  final Value<int> rowid;
  const TodayDashboardCacheTableCompanion({
    this.userId = const Value.absent(),
    this.dateString = const Value.absent(),
    this.caloriesTarget = const Value.absent(),
    this.caloriesConsumed = const Value.absent(),
    this.caloriesBurned = const Value.absent(),
    this.waterTargetMl = const Value.absent(),
    this.waterLoggedMl = const Value.absent(),
    this.readinessScore = const Value.absent(),
    this.readinessLabel = const Value.absent(),
    this.todayWorkoutTitle = const Value.absent(),
    this.todayWorkoutDurationMinutes = const Value.absent(),
    this.isWorkoutCompleted = const Value.absent(),
    this.dailyQuote = const Value.absent(),
    this.lastCachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodayDashboardCacheTableCompanion.insert({
    required String userId,
    required String dateString,
    this.caloriesTarget = const Value.absent(),
    this.caloriesConsumed = const Value.absent(),
    this.caloriesBurned = const Value.absent(),
    this.waterTargetMl = const Value.absent(),
    this.waterLoggedMl = const Value.absent(),
    this.readinessScore = const Value.absent(),
    this.readinessLabel = const Value.absent(),
    this.todayWorkoutTitle = const Value.absent(),
    this.todayWorkoutDurationMinutes = const Value.absent(),
    this.isWorkoutCompleted = const Value.absent(),
    this.dailyQuote = const Value.absent(),
    this.lastCachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        dateString = Value(dateString);
  static Insertable<TodayDashboardCacheTableData> custom({
    Expression<String>? userId,
    Expression<String>? dateString,
    Expression<int>? caloriesTarget,
    Expression<int>? caloriesConsumed,
    Expression<int>? caloriesBurned,
    Expression<int>? waterTargetMl,
    Expression<int>? waterLoggedMl,
    Expression<double>? readinessScore,
    Expression<String>? readinessLabel,
    Expression<String>? todayWorkoutTitle,
    Expression<int>? todayWorkoutDurationMinutes,
    Expression<bool>? isWorkoutCompleted,
    Expression<String>? dailyQuote,
    Expression<DateTime>? lastCachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (dateString != null) 'date_string': dateString,
      if (caloriesTarget != null) 'calories_target': caloriesTarget,
      if (caloriesConsumed != null) 'calories_consumed': caloriesConsumed,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
      if (waterTargetMl != null) 'water_target_ml': waterTargetMl,
      if (waterLoggedMl != null) 'water_logged_ml': waterLoggedMl,
      if (readinessScore != null) 'readiness_score': readinessScore,
      if (readinessLabel != null) 'readiness_label': readinessLabel,
      if (todayWorkoutTitle != null) 'today_workout_title': todayWorkoutTitle,
      if (todayWorkoutDurationMinutes != null)
        'today_workout_duration_minutes': todayWorkoutDurationMinutes,
      if (isWorkoutCompleted != null)
        'is_workout_completed': isWorkoutCompleted,
      if (dailyQuote != null) 'daily_quote': dailyQuote,
      if (lastCachedAt != null) 'last_cached_at': lastCachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodayDashboardCacheTableCompanion copyWith(
      {Value<String>? userId,
      Value<String>? dateString,
      Value<int>? caloriesTarget,
      Value<int>? caloriesConsumed,
      Value<int>? caloriesBurned,
      Value<int>? waterTargetMl,
      Value<int>? waterLoggedMl,
      Value<double>? readinessScore,
      Value<String>? readinessLabel,
      Value<String?>? todayWorkoutTitle,
      Value<int?>? todayWorkoutDurationMinutes,
      Value<bool>? isWorkoutCompleted,
      Value<String?>? dailyQuote,
      Value<DateTime>? lastCachedAt,
      Value<int>? rowid}) {
    return TodayDashboardCacheTableCompanion(
      userId: userId ?? this.userId,
      dateString: dateString ?? this.dateString,
      caloriesTarget: caloriesTarget ?? this.caloriesTarget,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      waterTargetMl: waterTargetMl ?? this.waterTargetMl,
      waterLoggedMl: waterLoggedMl ?? this.waterLoggedMl,
      readinessScore: readinessScore ?? this.readinessScore,
      readinessLabel: readinessLabel ?? this.readinessLabel,
      todayWorkoutTitle: todayWorkoutTitle ?? this.todayWorkoutTitle,
      todayWorkoutDurationMinutes:
          todayWorkoutDurationMinutes ?? this.todayWorkoutDurationMinutes,
      isWorkoutCompleted: isWorkoutCompleted ?? this.isWorkoutCompleted,
      dailyQuote: dailyQuote ?? this.dailyQuote,
      lastCachedAt: lastCachedAt ?? this.lastCachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (dateString.present) {
      map['date_string'] = Variable<String>(dateString.value);
    }
    if (caloriesTarget.present) {
      map['calories_target'] = Variable<int>(caloriesTarget.value);
    }
    if (caloriesConsumed.present) {
      map['calories_consumed'] = Variable<int>(caloriesConsumed.value);
    }
    if (caloriesBurned.present) {
      map['calories_burned'] = Variable<int>(caloriesBurned.value);
    }
    if (waterTargetMl.present) {
      map['water_target_ml'] = Variable<int>(waterTargetMl.value);
    }
    if (waterLoggedMl.present) {
      map['water_logged_ml'] = Variable<int>(waterLoggedMl.value);
    }
    if (readinessScore.present) {
      map['readiness_score'] = Variable<double>(readinessScore.value);
    }
    if (readinessLabel.present) {
      map['readiness_label'] = Variable<String>(readinessLabel.value);
    }
    if (todayWorkoutTitle.present) {
      map['today_workout_title'] = Variable<String>(todayWorkoutTitle.value);
    }
    if (todayWorkoutDurationMinutes.present) {
      map['today_workout_duration_minutes'] =
          Variable<int>(todayWorkoutDurationMinutes.value);
    }
    if (isWorkoutCompleted.present) {
      map['is_workout_completed'] = Variable<bool>(isWorkoutCompleted.value);
    }
    if (dailyQuote.present) {
      map['daily_quote'] = Variable<String>(dailyQuote.value);
    }
    if (lastCachedAt.present) {
      map['last_cached_at'] = Variable<DateTime>(lastCachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodayDashboardCacheTableCompanion(')
          ..write('userId: $userId, ')
          ..write('dateString: $dateString, ')
          ..write('caloriesTarget: $caloriesTarget, ')
          ..write('caloriesConsumed: $caloriesConsumed, ')
          ..write('caloriesBurned: $caloriesBurned, ')
          ..write('waterTargetMl: $waterTargetMl, ')
          ..write('waterLoggedMl: $waterLoggedMl, ')
          ..write('readinessScore: $readinessScore, ')
          ..write('readinessLabel: $readinessLabel, ')
          ..write('todayWorkoutTitle: $todayWorkoutTitle, ')
          ..write('todayWorkoutDurationMinutes: $todayWorkoutDurationMinutes, ')
          ..write('isWorkoutCompleted: $isWorkoutCompleted, ')
          ..write('dailyQuote: $dailyQuote, ')
          ..write('lastCachedAt: $lastCachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutCacheTableTable extends WorkoutCacheTable
    with TableInfo<$WorkoutCacheTableTable, WorkoutCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayOfWeekMeta =
      const VerificationMeta('dayOfWeek');
  @override
  late final GeneratedColumn<String> dayOfWeek = GeneratedColumn<String>(
      'day_of_week', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(45));
  static const VerificationMeta _muscleGroupsJsonMeta =
      const VerificationMeta('muscleGroupsJson');
  @override
  late final GeneratedColumn<String> muscleGroupsJson = GeneratedColumn<String>(
      'muscle_groups_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exercisesJsonMeta =
      const VerificationMeta('exercisesJson');
  @override
  late final GeneratedColumn<String> exercisesJson = GeneratedColumn<String>(
      'exercises_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _scheduledDateMeta =
      const VerificationMeta('scheduledDate');
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>('scheduled_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        dayOfWeek,
        durationMinutes,
        muscleGroupsJson,
        exercisesJson,
        isCompleted,
        scheduledDate,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_cache_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<WorkoutCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
          _dayOfWeekMeta,
          dayOfWeek.isAcceptableOrUnknown(
              data['day_of_week']!, _dayOfWeekMeta));
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('muscle_groups_json')) {
      context.handle(
          _muscleGroupsJsonMeta,
          muscleGroupsJson.isAcceptableOrUnknown(
              data['muscle_groups_json']!, _muscleGroupsJsonMeta));
    }
    if (data.containsKey('exercises_json')) {
      context.handle(
          _exercisesJsonMeta,
          exercisesJson.isAcceptableOrUnknown(
              data['exercises_json']!, _exercisesJsonMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
          _scheduledDateMeta,
          scheduledDate.isAcceptableOrUnknown(
              data['scheduled_date']!, _scheduledDateMeta));
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutCacheTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dayOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_of_week'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      muscleGroupsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}muscle_groups_json']),
      exercisesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercises_json']),
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      scheduledDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}scheduled_date'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WorkoutCacheTableTable createAlias(String alias) {
    return $WorkoutCacheTableTable(attachedDatabase, alias);
  }
}

class WorkoutCacheTableData extends DataClass
    implements Insertable<WorkoutCacheTableData> {
  final String id;
  final String userId;
  final String name;
  final String dayOfWeek;
  final int durationMinutes;
  final String? muscleGroupsJson;
  final String? exercisesJson;
  final bool isCompleted;
  final DateTime scheduledDate;
  final DateTime updatedAt;
  const WorkoutCacheTableData(
      {required this.id,
      required this.userId,
      required this.name,
      required this.dayOfWeek,
      required this.durationMinutes,
      this.muscleGroupsJson,
      this.exercisesJson,
      required this.isCompleted,
      required this.scheduledDate,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['day_of_week'] = Variable<String>(dayOfWeek);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    if (!nullToAbsent || muscleGroupsJson != null) {
      map['muscle_groups_json'] = Variable<String>(muscleGroupsJson);
    }
    if (!nullToAbsent || exercisesJson != null) {
      map['exercises_json'] = Variable<String>(exercisesJson);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorkoutCacheTableCompanion toCompanion(bool nullToAbsent) {
    return WorkoutCacheTableCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      dayOfWeek: Value(dayOfWeek),
      durationMinutes: Value(durationMinutes),
      muscleGroupsJson: muscleGroupsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(muscleGroupsJson),
      exercisesJson: exercisesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(exercisesJson),
      isCompleted: Value(isCompleted),
      scheduledDate: Value(scheduledDate),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkoutCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutCacheTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      dayOfWeek: serializer.fromJson<String>(json['dayOfWeek']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      muscleGroupsJson: serializer.fromJson<String?>(json['muscleGroupsJson']),
      exercisesJson: serializer.fromJson<String?>(json['exercisesJson']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'dayOfWeek': serializer.toJson<String>(dayOfWeek),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'muscleGroupsJson': serializer.toJson<String?>(muscleGroupsJson),
      'exercisesJson': serializer.toJson<String?>(exercisesJson),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorkoutCacheTableData copyWith(
          {String? id,
          String? userId,
          String? name,
          String? dayOfWeek,
          int? durationMinutes,
          Value<String?> muscleGroupsJson = const Value.absent(),
          Value<String?> exercisesJson = const Value.absent(),
          bool? isCompleted,
          DateTime? scheduledDate,
          DateTime? updatedAt}) =>
      WorkoutCacheTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        muscleGroupsJson: muscleGroupsJson.present
            ? muscleGroupsJson.value
            : this.muscleGroupsJson,
        exercisesJson:
            exercisesJson.present ? exercisesJson.value : this.exercisesJson,
        isCompleted: isCompleted ?? this.isCompleted,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WorkoutCacheTableData copyWithCompanion(WorkoutCacheTableCompanion data) {
    return WorkoutCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      muscleGroupsJson: data.muscleGroupsJson.present
          ? data.muscleGroupsJson.value
          : this.muscleGroupsJson,
      exercisesJson: data.exercisesJson.present
          ? data.exercisesJson.value
          : this.exercisesJson,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutCacheTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('muscleGroupsJson: $muscleGroupsJson, ')
          ..write('exercisesJson: $exercisesJson, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, dayOfWeek, durationMinutes,
      muscleGroupsJson, exercisesJson, isCompleted, scheduledDate, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutCacheTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.dayOfWeek == this.dayOfWeek &&
          other.durationMinutes == this.durationMinutes &&
          other.muscleGroupsJson == this.muscleGroupsJson &&
          other.exercisesJson == this.exercisesJson &&
          other.isCompleted == this.isCompleted &&
          other.scheduledDate == this.scheduledDate &&
          other.updatedAt == this.updatedAt);
}

class WorkoutCacheTableCompanion
    extends UpdateCompanion<WorkoutCacheTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> dayOfWeek;
  final Value<int> durationMinutes;
  final Value<String?> muscleGroupsJson;
  final Value<String?> exercisesJson;
  final Value<bool> isCompleted;
  final Value<DateTime> scheduledDate;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WorkoutCacheTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.muscleGroupsJson = const Value.absent(),
    this.exercisesJson = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutCacheTableCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String dayOfWeek,
    this.durationMinutes = const Value.absent(),
    this.muscleGroupsJson = const Value.absent(),
    this.exercisesJson = const Value.absent(),
    this.isCompleted = const Value.absent(),
    required DateTime scheduledDate,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        dayOfWeek = Value(dayOfWeek),
        scheduledDate = Value(scheduledDate);
  static Insertable<WorkoutCacheTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? dayOfWeek,
    Expression<int>? durationMinutes,
    Expression<String>? muscleGroupsJson,
    Expression<String>? exercisesJson,
    Expression<bool>? isCompleted,
    Expression<DateTime>? scheduledDate,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (muscleGroupsJson != null) 'muscle_groups_json': muscleGroupsJson,
      if (exercisesJson != null) 'exercises_json': exercisesJson,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutCacheTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String>? dayOfWeek,
      Value<int>? durationMinutes,
      Value<String?>? muscleGroupsJson,
      Value<String?>? exercisesJson,
      Value<bool>? isCompleted,
      Value<DateTime>? scheduledDate,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return WorkoutCacheTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      muscleGroupsJson: muscleGroupsJson ?? this.muscleGroupsJson,
      exercisesJson: exercisesJson ?? this.exercisesJson,
      isCompleted: isCompleted ?? this.isCompleted,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<String>(dayOfWeek.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (muscleGroupsJson.present) {
      map['muscle_groups_json'] = Variable<String>(muscleGroupsJson.value);
    }
    if (exercisesJson.present) {
      map['exercises_json'] = Variable<String>(exercisesJson.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('muscleGroupsJson: $muscleGroupsJson, ')
          ..write('exercisesJson: $exercisesJson, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NutritionCacheTableTable extends NutritionCacheTable
    with TableInfo<$NutritionCacheTableTable, NutritionCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateStringMeta =
      const VerificationMeta('dateString');
  @override
  late final GeneratedColumn<String> dateString = GeneratedColumn<String>(
      'date_string', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mealTypeMeta =
      const VerificationMeta('mealType');
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
      'meal_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodNameMeta =
      const VerificationMeta('foodName');
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
      'food_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caloriesMeta =
      const VerificationMeta('calories');
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
      'calories', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
      'carbs_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fatsGMeta = const VerificationMeta('fatsG');
  @override
  late final GeneratedColumn<double> fatsG = GeneratedColumn<double>(
      'fats_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _loggedAtMeta =
      const VerificationMeta('loggedAt');
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
      'logged_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        dateString,
        mealType,
        foodName,
        calories,
        proteinG,
        carbsG,
        fatsG,
        isSynced,
        loggedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_cache_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<NutritionCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('date_string')) {
      context.handle(
          _dateStringMeta,
          dateString.isAcceptableOrUnknown(
              data['date_string']!, _dateStringMeta));
    } else if (isInserting) {
      context.missing(_dateStringMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(_mealTypeMeta,
          mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta));
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('food_name')) {
      context.handle(_foodNameMeta,
          foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta));
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(_caloriesMeta,
          calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta));
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carbs_g')) {
      context.handle(_carbsGMeta,
          carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta));
    }
    if (data.containsKey('fats_g')) {
      context.handle(
          _fatsGMeta, fatsG.isAcceptableOrUnknown(data['fats_g']!, _fatsGMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('logged_at')) {
      context.handle(_loggedAtMeta,
          loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NutritionCacheTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionCacheTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      dateString: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_string'])!,
      mealType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_type'])!,
      foodName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_name'])!,
      calories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      carbsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_g'])!,
      fatsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fats_g'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      loggedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}logged_at'])!,
    );
  }

  @override
  $NutritionCacheTableTable createAlias(String alias) {
    return $NutritionCacheTableTable(attachedDatabase, alias);
  }
}

class NutritionCacheTableData extends DataClass
    implements Insertable<NutritionCacheTableData> {
  final String id;
  final String userId;
  final String dateString;
  final String mealType;
  final String foodName;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final bool isSynced;
  final DateTime loggedAt;
  const NutritionCacheTableData(
      {required this.id,
      required this.userId,
      required this.dateString,
      required this.mealType,
      required this.foodName,
      required this.calories,
      required this.proteinG,
      required this.carbsG,
      required this.fatsG,
      required this.isSynced,
      required this.loggedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['date_string'] = Variable<String>(dateString);
    map['meal_type'] = Variable<String>(mealType);
    map['food_name'] = Variable<String>(foodName);
    map['calories'] = Variable<int>(calories);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fats_g'] = Variable<double>(fatsG);
    map['is_synced'] = Variable<bool>(isSynced);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  NutritionCacheTableCompanion toCompanion(bool nullToAbsent) {
    return NutritionCacheTableCompanion(
      id: Value(id),
      userId: Value(userId),
      dateString: Value(dateString),
      mealType: Value(mealType),
      foodName: Value(foodName),
      calories: Value(calories),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatsG: Value(fatsG),
      isSynced: Value(isSynced),
      loggedAt: Value(loggedAt),
    );
  }

  factory NutritionCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionCacheTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      dateString: serializer.fromJson<String>(json['dateString']),
      mealType: serializer.fromJson<String>(json['mealType']),
      foodName: serializer.fromJson<String>(json['foodName']),
      calories: serializer.fromJson<int>(json['calories']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatsG: serializer.fromJson<double>(json['fatsG']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'dateString': serializer.toJson<String>(dateString),
      'mealType': serializer.toJson<String>(mealType),
      'foodName': serializer.toJson<String>(foodName),
      'calories': serializer.toJson<int>(calories),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatsG': serializer.toJson<double>(fatsG),
      'isSynced': serializer.toJson<bool>(isSynced),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  NutritionCacheTableData copyWith(
          {String? id,
          String? userId,
          String? dateString,
          String? mealType,
          String? foodName,
          int? calories,
          double? proteinG,
          double? carbsG,
          double? fatsG,
          bool? isSynced,
          DateTime? loggedAt}) =>
      NutritionCacheTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        dateString: dateString ?? this.dateString,
        mealType: mealType ?? this.mealType,
        foodName: foodName ?? this.foodName,
        calories: calories ?? this.calories,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatsG: fatsG ?? this.fatsG,
        isSynced: isSynced ?? this.isSynced,
        loggedAt: loggedAt ?? this.loggedAt,
      );
  NutritionCacheTableData copyWithCompanion(NutritionCacheTableCompanion data) {
    return NutritionCacheTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      dateString:
          data.dateString.present ? data.dateString.value : this.dateString,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatsG: data.fatsG.present ? data.fatsG.value : this.fatsG,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionCacheTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('dateString: $dateString, ')
          ..write('mealType: $mealType, ')
          ..write('foodName: $foodName, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatsG: $fatsG, ')
          ..write('isSynced: $isSynced, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, dateString, mealType, foodName,
      calories, proteinG, carbsG, fatsG, isSynced, loggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionCacheTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.dateString == this.dateString &&
          other.mealType == this.mealType &&
          other.foodName == this.foodName &&
          other.calories == this.calories &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatsG == this.fatsG &&
          other.isSynced == this.isSynced &&
          other.loggedAt == this.loggedAt);
}

class NutritionCacheTableCompanion
    extends UpdateCompanion<NutritionCacheTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> dateString;
  final Value<String> mealType;
  final Value<String> foodName;
  final Value<int> calories;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatsG;
  final Value<bool> isSynced;
  final Value<DateTime> loggedAt;
  final Value<int> rowid;
  const NutritionCacheTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.dateString = const Value.absent(),
    this.mealType = const Value.absent(),
    this.foodName = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatsG = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NutritionCacheTableCompanion.insert({
    required String id,
    required String userId,
    required String dateString,
    required String mealType,
    required String foodName,
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatsG = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        dateString = Value(dateString),
        mealType = Value(mealType),
        foodName = Value(foodName);
  static Insertable<NutritionCacheTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? dateString,
    Expression<String>? mealType,
    Expression<String>? foodName,
    Expression<int>? calories,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatsG,
    Expression<bool>? isSynced,
    Expression<DateTime>? loggedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (dateString != null) 'date_string': dateString,
      if (mealType != null) 'meal_type': mealType,
      if (foodName != null) 'food_name': foodName,
      if (calories != null) 'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatsG != null) 'fats_g': fatsG,
      if (isSynced != null) 'is_synced': isSynced,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NutritionCacheTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? dateString,
      Value<String>? mealType,
      Value<String>? foodName,
      Value<int>? calories,
      Value<double>? proteinG,
      Value<double>? carbsG,
      Value<double>? fatsG,
      Value<bool>? isSynced,
      Value<DateTime>? loggedAt,
      Value<int>? rowid}) {
    return NutritionCacheTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateString: dateString ?? this.dateString,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatsG: fatsG ?? this.fatsG,
      isSynced: isSynced ?? this.isSynced,
      loggedAt: loggedAt ?? this.loggedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (dateString.present) {
      map['date_string'] = Variable<String>(dateString.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatsG.present) {
      map['fats_g'] = Variable<double>(fatsG.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('dateString: $dateString, ')
          ..write('mealType: $mealType, ')
          ..write('foodName: $foodName, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatsG: $fatsG, ')
          ..write('isSynced: $isSynced, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _endpointMeta =
      const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
      'endpoint', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _httpMethodMeta =
      const VerificationMeta('httpMethod');
  @override
  late final GeneratedColumn<String> httpMethod = GeneratedColumn<String>(
      'http_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, endpoint, httpMethod, payloadJson, retryCount, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta,
          endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('http_method')) {
      context.handle(
          _httpMethodMeta,
          httpMethod.isAcceptableOrUnknown(
              data['http_method']!, _httpMethodMeta));
    } else if (isInserting) {
      context.missing(_httpMethodMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      endpoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      httpMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}http_method'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String endpoint;
  final String httpMethod;
  final String payloadJson;
  final int retryCount;
  final String status;
  final DateTime createdAt;
  const SyncQueueTableData(
      {required this.id,
      required this.endpoint,
      required this.httpMethod,
      required this.payloadJson,
      required this.retryCount,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['endpoint'] = Variable<String>(endpoint);
    map['http_method'] = Variable<String>(httpMethod);
    map['payload_json'] = Variable<String>(payloadJson);
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      endpoint: Value(endpoint),
      httpMethod: Value(httpMethod),
      payloadJson: Value(payloadJson),
      retryCount: Value(retryCount),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      httpMethod: serializer.fromJson<String>(json['httpMethod']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'endpoint': serializer.toJson<String>(endpoint),
      'httpMethod': serializer.toJson<String>(httpMethod),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueTableData copyWith(
          {int? id,
          String? endpoint,
          String? httpMethod,
          String? payloadJson,
          int? retryCount,
          String? status,
          DateTime? createdAt}) =>
      SyncQueueTableData(
        id: id ?? this.id,
        endpoint: endpoint ?? this.endpoint,
        httpMethod: httpMethod ?? this.httpMethod,
        payloadJson: payloadJson ?? this.payloadJson,
        retryCount: retryCount ?? this.retryCount,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      httpMethod:
          data.httpMethod.present ? data.httpMethod.value : this.httpMethod,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('endpoint: $endpoint, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, endpoint, httpMethod, payloadJson, retryCount, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.endpoint == this.endpoint &&
          other.httpMethod == this.httpMethod &&
          other.payloadJson == this.payloadJson &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> endpoint;
  final Value<String> httpMethod;
  final Value<String> payloadJson;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<DateTime> createdAt;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.httpMethod = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String endpoint,
    required String httpMethod,
    required String payloadJson,
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : endpoint = Value(endpoint),
        httpMethod = Value(httpMethod),
        payloadJson = Value(payloadJson);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? endpoint,
    Expression<String>? httpMethod,
    Expression<String>? payloadJson,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (endpoint != null) 'endpoint': endpoint,
      if (httpMethod != null) 'http_method': httpMethod,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? endpoint,
      Value<String>? httpMethod,
      Value<String>? payloadJson,
      Value<int>? retryCount,
      Value<String>? status,
      Value<DateTime>? createdAt}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      payloadJson: payloadJson ?? this.payloadJson,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (httpMethod.present) {
      map['http_method'] = Variable<String>(httpMethod.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('endpoint: $endpoint, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfilesTableTable userProfilesTable =
      $UserProfilesTableTable(this);
  late final $TodayDashboardCacheTableTable todayDashboardCacheTable =
      $TodayDashboardCacheTableTable(this);
  late final $WorkoutCacheTableTable workoutCacheTable =
      $WorkoutCacheTableTable(this);
  late final $NutritionCacheTableTable nutritionCacheTable =
      $NutritionCacheTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        userProfilesTable,
        todayDashboardCacheTable,
        workoutCacheTable,
        nutritionCacheTable,
        syncQueueTable
      ];
}

typedef $$UserProfilesTableTableCreateCompanionBuilder
    = UserProfilesTableCompanion Function({
  required String id,
  required String email,
  Value<String?> name,
  Value<String?> gender,
  Value<int?> age,
  Value<double?> heightCm,
  Value<double?> weightKg,
  Value<double?> targetWeightKg,
  Value<String?> workingToward,
  Value<String?> experienceLevel,
  Value<int?> daysPerWeek,
  Value<int?> workoutDuration,
  Value<String?> trainingLocation,
  Value<String?> equipmentJson,
  Value<String?> activityLevel,
  Value<String?> sleepDuration,
  Value<String?> eatingStyle,
  Value<String?> customEatingStyle,
  Value<String?> weeklyFoodBudget,
  Value<String?> limitationsJson,
  Value<int> currentStreak,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$UserProfilesTableTableUpdateCompanionBuilder
    = UserProfilesTableCompanion Function({
  Value<String> id,
  Value<String> email,
  Value<String?> name,
  Value<String?> gender,
  Value<int?> age,
  Value<double?> heightCm,
  Value<double?> weightKg,
  Value<double?> targetWeightKg,
  Value<String?> workingToward,
  Value<String?> experienceLevel,
  Value<int?> daysPerWeek,
  Value<int?> workoutDuration,
  Value<String?> trainingLocation,
  Value<String?> equipmentJson,
  Value<String?> activityLevel,
  Value<String?> sleepDuration,
  Value<String?> eatingStyle,
  Value<String?> customEatingStyle,
  Value<String?> weeklyFoodBudget,
  Value<String?> limitationsJson,
  Value<int> currentStreak,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserProfilesTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTableTable> {
  $$UserProfilesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workingToward => $composableBuilder(
      column: $table.workingToward, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysPerWeek => $composableBuilder(
      column: $table.daysPerWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get workoutDuration => $composableBuilder(
      column: $table.workoutDuration,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trainingLocation => $composableBuilder(
      column: $table.trainingLocation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipmentJson => $composableBuilder(
      column: $table.equipmentJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sleepDuration => $composableBuilder(
      column: $table.sleepDuration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eatingStyle => $composableBuilder(
      column: $table.eatingStyle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customEatingStyle => $composableBuilder(
      column: $table.customEatingStyle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weeklyFoodBudget => $composableBuilder(
      column: $table.weeklyFoodBudget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get limitationsJson => $composableBuilder(
      column: $table.limitationsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserProfilesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTableTable> {
  $$UserProfilesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workingToward => $composableBuilder(
      column: $table.workingToward,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysPerWeek => $composableBuilder(
      column: $table.daysPerWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workoutDuration => $composableBuilder(
      column: $table.workoutDuration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trainingLocation => $composableBuilder(
      column: $table.trainingLocation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipmentJson => $composableBuilder(
      column: $table.equipmentJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sleepDuration => $composableBuilder(
      column: $table.sleepDuration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eatingStyle => $composableBuilder(
      column: $table.eatingStyle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customEatingStyle => $composableBuilder(
      column: $table.customEatingStyle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weeklyFoodBudget => $composableBuilder(
      column: $table.weeklyFoodBudget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get limitationsJson => $composableBuilder(
      column: $table.limitationsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserProfilesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTableTable> {
  $$UserProfilesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg, builder: (column) => column);

  GeneratedColumn<String> get workingToward => $composableBuilder(
      column: $table.workingToward, builder: (column) => column);

  GeneratedColumn<String> get experienceLevel => $composableBuilder(
      column: $table.experienceLevel, builder: (column) => column);

  GeneratedColumn<int> get daysPerWeek => $composableBuilder(
      column: $table.daysPerWeek, builder: (column) => column);

  GeneratedColumn<int> get workoutDuration => $composableBuilder(
      column: $table.workoutDuration, builder: (column) => column);

  GeneratedColumn<String> get trainingLocation => $composableBuilder(
      column: $table.trainingLocation, builder: (column) => column);

  GeneratedColumn<String> get equipmentJson => $composableBuilder(
      column: $table.equipmentJson, builder: (column) => column);

  GeneratedColumn<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel, builder: (column) => column);

  GeneratedColumn<String> get sleepDuration => $composableBuilder(
      column: $table.sleepDuration, builder: (column) => column);

  GeneratedColumn<String> get eatingStyle => $composableBuilder(
      column: $table.eatingStyle, builder: (column) => column);

  GeneratedColumn<String> get customEatingStyle => $composableBuilder(
      column: $table.customEatingStyle, builder: (column) => column);

  GeneratedColumn<String> get weeklyFoodBudget => $composableBuilder(
      column: $table.weeklyFoodBudget, builder: (column) => column);

  GeneratedColumn<String> get limitationsJson => $composableBuilder(
      column: $table.limitationsJson, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfilesTableTable,
    UserProfilesTableData,
    $$UserProfilesTableTableFilterComposer,
    $$UserProfilesTableTableOrderingComposer,
    $$UserProfilesTableTableAnnotationComposer,
    $$UserProfilesTableTableCreateCompanionBuilder,
    $$UserProfilesTableTableUpdateCompanionBuilder,
    (
      UserProfilesTableData,
      BaseReferences<_$AppDatabase, $UserProfilesTableTable,
          UserProfilesTableData>
    ),
    UserProfilesTableData,
    PrefetchHooks Function()> {
  $$UserProfilesTableTableTableManager(
      _$AppDatabase db, $UserProfilesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<int?> age = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<double?> targetWeightKg = const Value.absent(),
            Value<String?> workingToward = const Value.absent(),
            Value<String?> experienceLevel = const Value.absent(),
            Value<int?> daysPerWeek = const Value.absent(),
            Value<int?> workoutDuration = const Value.absent(),
            Value<String?> trainingLocation = const Value.absent(),
            Value<String?> equipmentJson = const Value.absent(),
            Value<String?> activityLevel = const Value.absent(),
            Value<String?> sleepDuration = const Value.absent(),
            Value<String?> eatingStyle = const Value.absent(),
            Value<String?> customEatingStyle = const Value.absent(),
            Value<String?> weeklyFoodBudget = const Value.absent(),
            Value<String?> limitationsJson = const Value.absent(),
            Value<int> currentStreak = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfilesTableCompanion(
            id: id,
            email: email,
            name: name,
            gender: gender,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            targetWeightKg: targetWeightKg,
            workingToward: workingToward,
            experienceLevel: experienceLevel,
            daysPerWeek: daysPerWeek,
            workoutDuration: workoutDuration,
            trainingLocation: trainingLocation,
            equipmentJson: equipmentJson,
            activityLevel: activityLevel,
            sleepDuration: sleepDuration,
            eatingStyle: eatingStyle,
            customEatingStyle: customEatingStyle,
            weeklyFoodBudget: weeklyFoodBudget,
            limitationsJson: limitationsJson,
            currentStreak: currentStreak,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String email,
            Value<String?> name = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<int?> age = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<double?> targetWeightKg = const Value.absent(),
            Value<String?> workingToward = const Value.absent(),
            Value<String?> experienceLevel = const Value.absent(),
            Value<int?> daysPerWeek = const Value.absent(),
            Value<int?> workoutDuration = const Value.absent(),
            Value<String?> trainingLocation = const Value.absent(),
            Value<String?> equipmentJson = const Value.absent(),
            Value<String?> activityLevel = const Value.absent(),
            Value<String?> sleepDuration = const Value.absent(),
            Value<String?> eatingStyle = const Value.absent(),
            Value<String?> customEatingStyle = const Value.absent(),
            Value<String?> weeklyFoodBudget = const Value.absent(),
            Value<String?> limitationsJson = const Value.absent(),
            Value<int> currentStreak = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProfilesTableCompanion.insert(
            id: id,
            email: email,
            name: name,
            gender: gender,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            targetWeightKg: targetWeightKg,
            workingToward: workingToward,
            experienceLevel: experienceLevel,
            daysPerWeek: daysPerWeek,
            workoutDuration: workoutDuration,
            trainingLocation: trainingLocation,
            equipmentJson: equipmentJson,
            activityLevel: activityLevel,
            sleepDuration: sleepDuration,
            eatingStyle: eatingStyle,
            customEatingStyle: customEatingStyle,
            weeklyFoodBudget: weeklyFoodBudget,
            limitationsJson: limitationsJson,
            currentStreak: currentStreak,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$UserProfilesTableTable, UserProfilesTableData>(
                        table),
                    BaseReferences<_$AppDatabase, $UserProfilesTableTable,
                        UserProfilesTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfilesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfilesTableTable,
    UserProfilesTableData,
    $$UserProfilesTableTableFilterComposer,
    $$UserProfilesTableTableOrderingComposer,
    $$UserProfilesTableTableAnnotationComposer,
    $$UserProfilesTableTableCreateCompanionBuilder,
    $$UserProfilesTableTableUpdateCompanionBuilder,
    (
      UserProfilesTableData,
      BaseReferences<_$AppDatabase, $UserProfilesTableTable,
          UserProfilesTableData>
    ),
    UserProfilesTableData,
    PrefetchHooks Function()>;
typedef $$TodayDashboardCacheTableTableCreateCompanionBuilder
    = TodayDashboardCacheTableCompanion Function({
  required String userId,
  required String dateString,
  Value<int> caloriesTarget,
  Value<int> caloriesConsumed,
  Value<int> caloriesBurned,
  Value<int> waterTargetMl,
  Value<int> waterLoggedMl,
  Value<double> readinessScore,
  Value<String> readinessLabel,
  Value<String?> todayWorkoutTitle,
  Value<int?> todayWorkoutDurationMinutes,
  Value<bool> isWorkoutCompleted,
  Value<String?> dailyQuote,
  Value<DateTime> lastCachedAt,
  Value<int> rowid,
});
typedef $$TodayDashboardCacheTableTableUpdateCompanionBuilder
    = TodayDashboardCacheTableCompanion Function({
  Value<String> userId,
  Value<String> dateString,
  Value<int> caloriesTarget,
  Value<int> caloriesConsumed,
  Value<int> caloriesBurned,
  Value<int> waterTargetMl,
  Value<int> waterLoggedMl,
  Value<double> readinessScore,
  Value<String> readinessLabel,
  Value<String?> todayWorkoutTitle,
  Value<int?> todayWorkoutDurationMinutes,
  Value<bool> isWorkoutCompleted,
  Value<String?> dailyQuote,
  Value<DateTime> lastCachedAt,
  Value<int> rowid,
});

class $$TodayDashboardCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $TodayDashboardCacheTableTable> {
  $$TodayDashboardCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateString => $composableBuilder(
      column: $table.dateString, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get caloriesTarget => $composableBuilder(
      column: $table.caloriesTarget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get caloriesConsumed => $composableBuilder(
      column: $table.caloriesConsumed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get waterTargetMl => $composableBuilder(
      column: $table.waterTargetMl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get waterLoggedMl => $composableBuilder(
      column: $table.waterLoggedMl, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get readinessScore => $composableBuilder(
      column: $table.readinessScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get readinessLabel => $composableBuilder(
      column: $table.readinessLabel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get todayWorkoutTitle => $composableBuilder(
      column: $table.todayWorkoutTitle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get todayWorkoutDurationMinutes => $composableBuilder(
      column: $table.todayWorkoutDurationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWorkoutCompleted => $composableBuilder(
      column: $table.isWorkoutCompleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dailyQuote => $composableBuilder(
      column: $table.dailyQuote, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastCachedAt => $composableBuilder(
      column: $table.lastCachedAt, builder: (column) => ColumnFilters(column));
}

class $$TodayDashboardCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TodayDashboardCacheTableTable> {
  $$TodayDashboardCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateString => $composableBuilder(
      column: $table.dateString, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get caloriesTarget => $composableBuilder(
      column: $table.caloriesTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get caloriesConsumed => $composableBuilder(
      column: $table.caloriesConsumed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get waterTargetMl => $composableBuilder(
      column: $table.waterTargetMl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get waterLoggedMl => $composableBuilder(
      column: $table.waterLoggedMl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get readinessScore => $composableBuilder(
      column: $table.readinessScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get readinessLabel => $composableBuilder(
      column: $table.readinessLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get todayWorkoutTitle => $composableBuilder(
      column: $table.todayWorkoutTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get todayWorkoutDurationMinutes => $composableBuilder(
      column: $table.todayWorkoutDurationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWorkoutCompleted => $composableBuilder(
      column: $table.isWorkoutCompleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dailyQuote => $composableBuilder(
      column: $table.dailyQuote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastCachedAt => $composableBuilder(
      column: $table.lastCachedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$TodayDashboardCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodayDashboardCacheTableTable> {
  $$TodayDashboardCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get dateString => $composableBuilder(
      column: $table.dateString, builder: (column) => column);

  GeneratedColumn<int> get caloriesTarget => $composableBuilder(
      column: $table.caloriesTarget, builder: (column) => column);

  GeneratedColumn<int> get caloriesConsumed => $composableBuilder(
      column: $table.caloriesConsumed, builder: (column) => column);

  GeneratedColumn<int> get caloriesBurned => $composableBuilder(
      column: $table.caloriesBurned, builder: (column) => column);

  GeneratedColumn<int> get waterTargetMl => $composableBuilder(
      column: $table.waterTargetMl, builder: (column) => column);

  GeneratedColumn<int> get waterLoggedMl => $composableBuilder(
      column: $table.waterLoggedMl, builder: (column) => column);

  GeneratedColumn<double> get readinessScore => $composableBuilder(
      column: $table.readinessScore, builder: (column) => column);

  GeneratedColumn<String> get readinessLabel => $composableBuilder(
      column: $table.readinessLabel, builder: (column) => column);

  GeneratedColumn<String> get todayWorkoutTitle => $composableBuilder(
      column: $table.todayWorkoutTitle, builder: (column) => column);

  GeneratedColumn<int> get todayWorkoutDurationMinutes => $composableBuilder(
      column: $table.todayWorkoutDurationMinutes, builder: (column) => column);

  GeneratedColumn<bool> get isWorkoutCompleted => $composableBuilder(
      column: $table.isWorkoutCompleted, builder: (column) => column);

  GeneratedColumn<String> get dailyQuote => $composableBuilder(
      column: $table.dailyQuote, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCachedAt => $composableBuilder(
      column: $table.lastCachedAt, builder: (column) => column);
}

class $$TodayDashboardCacheTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TodayDashboardCacheTableTable,
    TodayDashboardCacheTableData,
    $$TodayDashboardCacheTableTableFilterComposer,
    $$TodayDashboardCacheTableTableOrderingComposer,
    $$TodayDashboardCacheTableTableAnnotationComposer,
    $$TodayDashboardCacheTableTableCreateCompanionBuilder,
    $$TodayDashboardCacheTableTableUpdateCompanionBuilder,
    (
      TodayDashboardCacheTableData,
      BaseReferences<_$AppDatabase, $TodayDashboardCacheTableTable,
          TodayDashboardCacheTableData>
    ),
    TodayDashboardCacheTableData,
    PrefetchHooks Function()> {
  $$TodayDashboardCacheTableTableTableManager(
      _$AppDatabase db, $TodayDashboardCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodayDashboardCacheTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$TodayDashboardCacheTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodayDashboardCacheTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> dateString = const Value.absent(),
            Value<int> caloriesTarget = const Value.absent(),
            Value<int> caloriesConsumed = const Value.absent(),
            Value<int> caloriesBurned = const Value.absent(),
            Value<int> waterTargetMl = const Value.absent(),
            Value<int> waterLoggedMl = const Value.absent(),
            Value<double> readinessScore = const Value.absent(),
            Value<String> readinessLabel = const Value.absent(),
            Value<String?> todayWorkoutTitle = const Value.absent(),
            Value<int?> todayWorkoutDurationMinutes = const Value.absent(),
            Value<bool> isWorkoutCompleted = const Value.absent(),
            Value<String?> dailyQuote = const Value.absent(),
            Value<DateTime> lastCachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodayDashboardCacheTableCompanion(
            userId: userId,
            dateString: dateString,
            caloriesTarget: caloriesTarget,
            caloriesConsumed: caloriesConsumed,
            caloriesBurned: caloriesBurned,
            waterTargetMl: waterTargetMl,
            waterLoggedMl: waterLoggedMl,
            readinessScore: readinessScore,
            readinessLabel: readinessLabel,
            todayWorkoutTitle: todayWorkoutTitle,
            todayWorkoutDurationMinutes: todayWorkoutDurationMinutes,
            isWorkoutCompleted: isWorkoutCompleted,
            dailyQuote: dailyQuote,
            lastCachedAt: lastCachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String dateString,
            Value<int> caloriesTarget = const Value.absent(),
            Value<int> caloriesConsumed = const Value.absent(),
            Value<int> caloriesBurned = const Value.absent(),
            Value<int> waterTargetMl = const Value.absent(),
            Value<int> waterLoggedMl = const Value.absent(),
            Value<double> readinessScore = const Value.absent(),
            Value<String> readinessLabel = const Value.absent(),
            Value<String?> todayWorkoutTitle = const Value.absent(),
            Value<int?> todayWorkoutDurationMinutes = const Value.absent(),
            Value<bool> isWorkoutCompleted = const Value.absent(),
            Value<String?> dailyQuote = const Value.absent(),
            Value<DateTime> lastCachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodayDashboardCacheTableCompanion.insert(
            userId: userId,
            dateString: dateString,
            caloriesTarget: caloriesTarget,
            caloriesConsumed: caloriesConsumed,
            caloriesBurned: caloriesBurned,
            waterTargetMl: waterTargetMl,
            waterLoggedMl: waterLoggedMl,
            readinessScore: readinessScore,
            readinessLabel: readinessLabel,
            todayWorkoutTitle: todayWorkoutTitle,
            todayWorkoutDurationMinutes: todayWorkoutDurationMinutes,
            isWorkoutCompleted: isWorkoutCompleted,
            dailyQuote: dailyQuote,
            lastCachedAt: lastCachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TodayDashboardCacheTableTable,
                        TodayDashboardCacheTableData>(table),
                    BaseReferences<
                        _$AppDatabase,
                        $TodayDashboardCacheTableTable,
                        TodayDashboardCacheTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TodayDashboardCacheTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TodayDashboardCacheTableTable,
        TodayDashboardCacheTableData,
        $$TodayDashboardCacheTableTableFilterComposer,
        $$TodayDashboardCacheTableTableOrderingComposer,
        $$TodayDashboardCacheTableTableAnnotationComposer,
        $$TodayDashboardCacheTableTableCreateCompanionBuilder,
        $$TodayDashboardCacheTableTableUpdateCompanionBuilder,
        (
          TodayDashboardCacheTableData,
          BaseReferences<_$AppDatabase, $TodayDashboardCacheTableTable,
              TodayDashboardCacheTableData>
        ),
        TodayDashboardCacheTableData,
        PrefetchHooks Function()>;
typedef $$WorkoutCacheTableTableCreateCompanionBuilder
    = WorkoutCacheTableCompanion Function({
  required String id,
  required String userId,
  required String name,
  required String dayOfWeek,
  Value<int> durationMinutes,
  Value<String?> muscleGroupsJson,
  Value<String?> exercisesJson,
  Value<bool> isCompleted,
  required DateTime scheduledDate,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$WorkoutCacheTableTableUpdateCompanionBuilder
    = WorkoutCacheTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String> dayOfWeek,
  Value<int> durationMinutes,
  Value<String?> muscleGroupsJson,
  Value<String?> exercisesJson,
  Value<bool> isCompleted,
  Value<DateTime> scheduledDate,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$WorkoutCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutCacheTableTable> {
  $$WorkoutCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get muscleGroupsJson => $composableBuilder(
      column: $table.muscleGroupsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exercisesJson => $composableBuilder(
      column: $table.exercisesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WorkoutCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutCacheTableTable> {
  $$WorkoutCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get muscleGroupsJson => $composableBuilder(
      column: $table.muscleGroupsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exercisesJson => $composableBuilder(
      column: $table.exercisesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutCacheTableTable> {
  $$WorkoutCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get muscleGroupsJson => $composableBuilder(
      column: $table.muscleGroupsJson, builder: (column) => column);

  GeneratedColumn<String> get exercisesJson => $composableBuilder(
      column: $table.exercisesJson, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorkoutCacheTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutCacheTableTable,
    WorkoutCacheTableData,
    $$WorkoutCacheTableTableFilterComposer,
    $$WorkoutCacheTableTableOrderingComposer,
    $$WorkoutCacheTableTableAnnotationComposer,
    $$WorkoutCacheTableTableCreateCompanionBuilder,
    $$WorkoutCacheTableTableUpdateCompanionBuilder,
    (
      WorkoutCacheTableData,
      BaseReferences<_$AppDatabase, $WorkoutCacheTableTable,
          WorkoutCacheTableData>
    ),
    WorkoutCacheTableData,
    PrefetchHooks Function()> {
  $$WorkoutCacheTableTableTableManager(
      _$AppDatabase db, $WorkoutCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutCacheTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> dayOfWeek = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String?> muscleGroupsJson = const Value.absent(),
            Value<String?> exercisesJson = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> scheduledDate = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutCacheTableCompanion(
            id: id,
            userId: userId,
            name: name,
            dayOfWeek: dayOfWeek,
            durationMinutes: durationMinutes,
            muscleGroupsJson: muscleGroupsJson,
            exercisesJson: exercisesJson,
            isCompleted: isCompleted,
            scheduledDate: scheduledDate,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            required String dayOfWeek,
            Value<int> durationMinutes = const Value.absent(),
            Value<String?> muscleGroupsJson = const Value.absent(),
            Value<String?> exercisesJson = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            required DateTime scheduledDate,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutCacheTableCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            dayOfWeek: dayOfWeek,
            durationMinutes: durationMinutes,
            muscleGroupsJson: muscleGroupsJson,
            exercisesJson: exercisesJson,
            isCompleted: isCompleted,
            scheduledDate: scheduledDate,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$WorkoutCacheTableTable, WorkoutCacheTableData>(
                        table),
                    BaseReferences<_$AppDatabase, $WorkoutCacheTableTable,
                        WorkoutCacheTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkoutCacheTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutCacheTableTable,
    WorkoutCacheTableData,
    $$WorkoutCacheTableTableFilterComposer,
    $$WorkoutCacheTableTableOrderingComposer,
    $$WorkoutCacheTableTableAnnotationComposer,
    $$WorkoutCacheTableTableCreateCompanionBuilder,
    $$WorkoutCacheTableTableUpdateCompanionBuilder,
    (
      WorkoutCacheTableData,
      BaseReferences<_$AppDatabase, $WorkoutCacheTableTable,
          WorkoutCacheTableData>
    ),
    WorkoutCacheTableData,
    PrefetchHooks Function()>;
typedef $$NutritionCacheTableTableCreateCompanionBuilder
    = NutritionCacheTableCompanion Function({
  required String id,
  required String userId,
  required String dateString,
  required String mealType,
  required String foodName,
  Value<int> calories,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatsG,
  Value<bool> isSynced,
  Value<DateTime> loggedAt,
  Value<int> rowid,
});
typedef $$NutritionCacheTableTableUpdateCompanionBuilder
    = NutritionCacheTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> dateString,
  Value<String> mealType,
  Value<String> foodName,
  Value<int> calories,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatsG,
  Value<bool> isSynced,
  Value<DateTime> loggedAt,
  Value<int> rowid,
});

class $$NutritionCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $NutritionCacheTableTable> {
  $$NutritionCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateString => $composableBuilder(
      column: $table.dateString, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodName => $composableBuilder(
      column: $table.foodName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatsG => $composableBuilder(
      column: $table.fatsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
      column: $table.loggedAt, builder: (column) => ColumnFilters(column));
}

class $$NutritionCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NutritionCacheTableTable> {
  $$NutritionCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateString => $composableBuilder(
      column: $table.dateString, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodName => $composableBuilder(
      column: $table.foodName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatsG => $composableBuilder(
      column: $table.fatsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
      column: $table.loggedAt, builder: (column) => ColumnOrderings(column));
}

class $$NutritionCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutritionCacheTableTable> {
  $$NutritionCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get dateString => $composableBuilder(
      column: $table.dateString, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatsG =>
      $composableBuilder(column: $table.fatsG, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);
}

class $$NutritionCacheTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NutritionCacheTableTable,
    NutritionCacheTableData,
    $$NutritionCacheTableTableFilterComposer,
    $$NutritionCacheTableTableOrderingComposer,
    $$NutritionCacheTableTableAnnotationComposer,
    $$NutritionCacheTableTableCreateCompanionBuilder,
    $$NutritionCacheTableTableUpdateCompanionBuilder,
    (
      NutritionCacheTableData,
      BaseReferences<_$AppDatabase, $NutritionCacheTableTable,
          NutritionCacheTableData>
    ),
    NutritionCacheTableData,
    PrefetchHooks Function()> {
  $$NutritionCacheTableTableTableManager(
      _$AppDatabase db, $NutritionCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionCacheTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionCacheTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> dateString = const Value.absent(),
            Value<String> mealType = const Value.absent(),
            Value<String> foodName = const Value.absent(),
            Value<int> calories = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatsG = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> loggedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NutritionCacheTableCompanion(
            id: id,
            userId: userId,
            dateString: dateString,
            mealType: mealType,
            foodName: foodName,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatsG: fatsG,
            isSynced: isSynced,
            loggedAt: loggedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String dateString,
            required String mealType,
            required String foodName,
            Value<int> calories = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatsG = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> loggedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NutritionCacheTableCompanion.insert(
            id: id,
            userId: userId,
            dateString: dateString,
            mealType: mealType,
            foodName: foodName,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatsG: fatsG,
            isSynced: isSynced,
            loggedAt: loggedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$NutritionCacheTableTable,
                        NutritionCacheTableData>(table),
                    BaseReferences<_$AppDatabase, $NutritionCacheTableTable,
                        NutritionCacheTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NutritionCacheTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NutritionCacheTableTable,
    NutritionCacheTableData,
    $$NutritionCacheTableTableFilterComposer,
    $$NutritionCacheTableTableOrderingComposer,
    $$NutritionCacheTableTableAnnotationComposer,
    $$NutritionCacheTableTableCreateCompanionBuilder,
    $$NutritionCacheTableTableUpdateCompanionBuilder,
    (
      NutritionCacheTableData,
      BaseReferences<_$AppDatabase, $NutritionCacheTableTable,
          NutritionCacheTableData>
    ),
    NutritionCacheTableData,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  required String endpoint,
  required String httpMethod,
  required String payloadJson,
  Value<int> retryCount,
  Value<String> status,
  Value<DateTime> createdAt,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  Value<String> endpoint,
  Value<String> httpMethod,
  Value<String> payloadJson,
  Value<int> retryCount,
  Value<String> status,
  Value<DateTime> createdAt,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get httpMethod => $composableBuilder(
      column: $table.httpMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get httpMethod => $composableBuilder(
      column: $table.httpMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get httpMethod => $composableBuilder(
      column: $table.httpMethod, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(
      _$AppDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> endpoint = const Value.absent(),
            Value<String> httpMethod = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            endpoint: endpoint,
            httpMethod: httpMethod,
            payloadJson: payloadJson,
            retryCount: retryCount,
            status: status,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String endpoint,
            required String httpMethod,
            required String payloadJson,
            Value<int> retryCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            endpoint: endpoint,
            httpMethod: httpMethod,
            payloadJson: payloadJson,
            retryCount: retryCount,
            status: status,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncQueueTableTable, SyncQueueTableData>(
                        table),
                    BaseReferences<_$AppDatabase, $SyncQueueTableTable,
                        SyncQueueTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfilesTableTableTableManager get userProfilesTable =>
      $$UserProfilesTableTableTableManager(_db, _db.userProfilesTable);
  $$TodayDashboardCacheTableTableTableManager get todayDashboardCacheTable =>
      $$TodayDashboardCacheTableTableTableManager(
          _db, _db.todayDashboardCacheTable);
  $$WorkoutCacheTableTableTableManager get workoutCacheTable =>
      $$WorkoutCacheTableTableTableManager(_db, _db.workoutCacheTable);
  $$NutritionCacheTableTableTableManager get nutritionCacheTable =>
      $$NutritionCacheTableTableTableManager(_db, _db.nutritionCacheTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
}
