import '../../../core/localization/fitness_copy.dart';

class FoodPortion {
  final String unit, label;
  final double gramsPerUnit;
  const FoodPortion(
      {required this.unit, required this.label, required this.gramsPerUnit});

  factory FoodPortion.fromJson(Map<String, dynamic> json) => FoodPortion(
      unit: json['unit'] as String,
      label: json['label'] as String,
      gramsPerUnit: (json['gramsPerUnit'] as num).toDouble());

  Map<String, dynamic> toJson() =>
      {'unit': unit, 'label': label, 'gramsPerUnit': gramsPerUnit};
}

// MARK: - Nutrition & Diet Models for Today Full Meal Plan

class NutritionFoodItemModel {
  final String id;
  final String canonicalName;
  String get name => foodDisplayName(id, canonicalName);
  final String? brand;
  final String category;
  final String? imageUrl;
  final String? sourceName, sourceVersion;
  final String? imageCreditsUrl, imageCredit;
  final List<FoodPortion> portions;
  final String defaultPortionUnit;
  final double servingSize;
  final String servingUnit;
  final double caloriesPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final double fiberPerServing;

  const NutritionFoodItemModel({
    required this.id,
    required String name,
    this.brand,
    required this.category,
    this.imageUrl,
    this.sourceName,
    this.sourceVersion,
    this.imageCreditsUrl,
    this.imageCredit,
    this.portions = const [],
    this.defaultPortionUnit = 'g',
    this.servingSize = 100.0,
    this.servingUnit = 'g',
    required this.caloriesPerServing,
    required this.proteinPerServing,
    required this.carbsPerServing,
    required this.fatPerServing,
    this.fiberPerServing = 0.0,
  }) : canonicalName = name;

  FoodPortion? get preferredPortion {
    for (final portion in portions) {
      if (portion.unit == defaultPortionUnit) return portion;
    }
    return null;
  }

  double get previewFactor => preferredPortion == null
      ? 1
      : (defaultPortionUnit == 'ml' ? 250 : 1) *
          preferredPortion!.gramsPerUnit /
          servingSize;

  String get previewQuantity => preferredPortion == null
      ? '${servingSize.toStringAsFixed(servingSize % 1 == 0 ? 0 : 1)} $servingUnit'
      : defaultPortionUnit == 'ml'
          ? '250 ml'
          : '1 ${preferredPortion!.label}';

  factory NutritionFoodItemModel.fromJson(Map<String, dynamic> json) {
    final attribution = json['imageAttribution'] is Map
        ? Map<String, dynamic>.from(json['imageAttribution'] as Map)
        : null;
    return NutritionFoodItemModel(
      id: (json['id'] ?? '').toString(),
      name: (json['canonicalName'] ?? json['name'] ?? 'Custom Food').toString(),
      brand: json['brand']?.toString(),
      category: (json['category'] ?? 'PROTEIN_SOURCE').toString(),
      imageUrl: json['imageUrl']?.toString(),
      sourceName: json['sourceName']?.toString(),
      sourceVersion: json['sourceVersion']?.toString(),
      imageCreditsUrl: attribution?['creditUrl']?.toString() ??
          json['imageCreditsUrl']?.toString(),
      imageCredit: attribution != null
          ? '${attribution['author']} · ${attribution['license']}'
          : json['imageCredit']?.toString(),
      portions: (json['portions'] as List? ?? [])
          .whereType<Map>()
          .map((p) => FoodPortion.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      defaultPortionUnit:
          (json['defaultPortionUnit'] ?? json['servingUnit'] ?? 'g').toString(),
      servingSize: (json['servingSize'] is num)
          ? (json['servingSize'] as num).toDouble()
          : 100.0,
      servingUnit: (json['servingUnit'] ?? 'g').toString(),
      caloriesPerServing: (json['caloriesPerServing'] is num)
          ? (json['caloriesPerServing'] as num).toDouble()
          : 0.0,
      proteinPerServing: (json['proteinPerServing'] is num)
          ? (json['proteinPerServing'] as num).toDouble()
          : 0.0,
      carbsPerServing: (json['carbsPerServing'] is num)
          ? (json['carbsPerServing'] as num).toDouble()
          : 0.0,
      fatPerServing: (json['fatPerServing'] is num)
          ? (json['fatPerServing'] as num).toDouble()
          : 0.0,
      fiberPerServing: (json['fiberPerServing'] is num)
          ? (json['fiberPerServing'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': canonicalName,
      'brand': brand,
      'category': category,
      'imageUrl': imageUrl,
      'sourceName': sourceName,
      'sourceVersion': sourceVersion,
      'imageCreditsUrl': imageCreditsUrl,
      'imageCredit': imageCredit,
      'portions': portions.map((p) => p.toJson()).toList(),
      'defaultPortionUnit': defaultPortionUnit,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'caloriesPerServing': caloriesPerServing,
      'proteinPerServing': proteinPerServing,
      'carbsPerServing': carbsPerServing,
      'fatPerServing': fatPerServing,
      'fiberPerServing': fiberPerServing,
    };
  }
}

class UserMealLogItemModel {
  final String id;
  final String mealType; // BREAKFAST, LUNCH, SNACK, DINNER, POST_WORKOUT
  final double servings;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String status; // LOGGED, PENDING, SKIPPED
  final DateTime? createdAt;
  final NutritionFoodItemModel food;

  const UserMealLogItemModel({
    required this.id,
    required this.mealType,
    this.servings = 1.0,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    required this.status,
    this.createdAt,
    required this.food,
  });

  bool get isLogged => status == 'LOGGED';
  bool get isPending => status == 'PENDING';
  bool get isSkipped => status == 'SKIPPED';

  UserMealLogItemModel copyWith({
    String? id,
    String? mealType,
    double? servings,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    String? status,
    DateTime? createdAt,
    NutritionFoodItemModel? food,
  }) {
    return UserMealLogItemModel(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      food: food ?? this.food,
    );
  }

  factory UserMealLogItemModel.fromJson(Map<String, dynamic> json) {
    final nutritionRaw = json['nutrition'] is Map<String, dynamic>
        ? json['nutrition'] as Map<String, dynamic>
        : <String, dynamic>{};

    return UserMealLogItemModel(
      id: (json['id'] ?? '').toString(),
      mealType: (json['mealType'] ?? 'LUNCH').toString(),
      servings: (json['servings'] is num)
          ? (json['servings'] as num).toDouble()
          : 1.0,
      calories: (json['calories'] is num)
          ? (json['calories'] as num).toDouble()
          : 0.0,
      protein:
          (json['protein'] is num) ? (json['protein'] as num).toDouble() : 0.0,
      carbs: (json['carbs'] is num) ? (json['carbs'] as num).toDouble() : 0.0,
      fat: (json['fat'] is num) ? (json['fat'] as num).toDouble() : 0.0,
      fiber: (json['fiber'] is num) ? (json['fiber'] as num).toDouble() : 0.0,
      status: (json['status'] ?? 'LOGGED').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      food: NutritionFoodItemModel.fromJson(nutritionRaw),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealType': mealType,
      'servings': servings,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'nutrition': food.toJson(),
    };
  }
}

class TodayDietPlanModel {
  final double fiberConsumed;
  final double caloriesConsumed;
  final double caloriesTarget;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatConsumed;
  final double fatTarget;
  final int waterConsumed;
  final int waterTarget;
  final List<UserMealLogItemModel> logs;

  const TodayDietPlanModel({
    this.fiberConsumed = 0,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatConsumed,
    required this.fatTarget,
    required this.waterConsumed,
    required this.waterTarget,
    required this.logs,
  });

  double get remainingCalories =>
      (caloriesTarget - caloriesConsumed).clamp(0.0, caloriesTarget);
  double get remainingProtein =>
      (proteinTarget - proteinConsumed).clamp(0.0, proteinTarget);
  double get proteinProgress => proteinTarget <= 0
      ? 0.0
      : (proteinConsumed / proteinTarget).clamp(0.0, 1.0);
  double get calorieProgress => caloriesTarget <= 0
      ? 0.0
      : (caloriesConsumed / caloriesTarget).clamp(0.0, 1.0);
  double get carbsProgress =>
      carbsTarget <= 0 ? 0.0 : (carbsConsumed / carbsTarget).clamp(0.0, 1.0);
  double get fatProgress =>
      fatTarget <= 0 ? 0.0 : (fatConsumed / fatTarget).clamp(0.0, 1.0);
  double get waterProgress =>
      waterTarget <= 0 ? 0.0 : (waterConsumed / waterTarget).clamp(0.0, 1.0);

  List<UserMealLogItemModel> get breakfastMeals =>
      logs.where((l) => l.mealType == 'BREAKFAST').toList();
  List<UserMealLogItemModel> get lunchMeals =>
      logs.where((l) => l.mealType == 'LUNCH').toList();
  List<UserMealLogItemModel> get dinnerMeals =>
      logs.where((l) => l.mealType == 'DINNER').toList();
  List<UserMealLogItemModel> get snackMeals => logs
      .where((l) =>
          l.mealType == 'SNACK' ||
          l.mealType == 'MORNING_SNACK' ||
          l.mealType == 'AFTERNOON_SNACK' ||
          l.mealType == 'POST_WORKOUT' ||
          l.mealType == 'LATE_SNACK')
      .toList();

  TodayDietPlanModel copyWith({
    double? fiberConsumed,
    double? caloriesConsumed,
    double? caloriesTarget,
    double? proteinConsumed,
    double? proteinTarget,
    double? carbsConsumed,
    double? carbsTarget,
    double? fatConsumed,
    double? fatTarget,
    int? waterConsumed,
    int? waterTarget,
    List<UserMealLogItemModel>? logs,
  }) {
    return TodayDietPlanModel(
      fiberConsumed: fiberConsumed ?? this.fiberConsumed,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      caloriesTarget: caloriesTarget ?? this.caloriesTarget,
      proteinConsumed: proteinConsumed ?? this.proteinConsumed,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      carbsConsumed: carbsConsumed ?? this.carbsConsumed,
      carbsTarget: carbsTarget ?? this.carbsTarget,
      fatConsumed: fatConsumed ?? this.fatConsumed,
      fatTarget: fatTarget ?? this.fatTarget,
      waterConsumed: waterConsumed ?? this.waterConsumed,
      waterTarget: waterTarget ?? this.waterTarget,
      logs: logs ?? this.logs,
    );
  }

  factory TodayDietPlanModel.fromJson(Map<String, dynamic> json) {
    final summary = json['dailySummary'] is Map<String, dynamic>
        ? json['dailySummary'] as Map<String, dynamic>
        : <String, dynamic>{};
    final targets = json['targets'] is Map<String, dynamic>
        ? json['targets'] as Map<String, dynamic>
        : <String, dynamic>{};
    final rawLogs = json['logs'] is List ? json['logs'] as List : [];
    final logsList = rawLogs
        .map((e) => UserMealLogItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    double loggedTotal(double Function(UserMealLogItemModel) valueOf) =>
        logsList
            .where((item) => item.isLogged)
            .fold(0.0, (total, item) => total + valueOf(item));

    return TodayDietPlanModel(
      fiberConsumed: (summary['totalFiber'] as num?)?.toDouble() ??
          loggedTotal((item) => item.fiber),
      caloriesConsumed: (summary['totalCalories'] is num)
          ? (summary['totalCalories'] as num).toDouble()
          : loggedTotal((item) => item.calories),
      caloriesTarget: (targets['calories'] is num)
          ? (targets['calories'] as num).toDouble()
          : 0.0,
      proteinConsumed: (summary['totalProtein'] is num)
          ? (summary['totalProtein'] as num).toDouble()
          : loggedTotal((item) => item.protein),
      proteinTarget: (targets['protein'] is num)
          ? (targets['protein'] as num).toDouble()
          : 0.0,
      carbsConsumed: (summary['totalCarbs'] is num)
          ? (summary['totalCarbs'] as num).toDouble()
          : loggedTotal((item) => item.carbs),
      carbsTarget: (targets['carbs'] is num)
          ? (targets['carbs'] as num).toDouble()
          : 0.0,
      fatConsumed: (summary['totalFat'] is num)
          ? (summary['totalFat'] as num).toDouble()
          : loggedTotal((item) => item.fat),
      fatTarget:
          (targets['fat'] is num) ? (targets['fat'] as num).toDouble() : 0.0,
      waterConsumed: (json['waterConsumed'] is num)
          ? (json['waterConsumed'] as num).toInt()
          : 0,
      waterTarget:
          (targets['water'] is num) ? (targets['water'] as num).toInt() : 0,
      logs: logsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailySummary': {
        'totalFiber': fiberConsumed,
        'totalCalories': caloriesConsumed,
        'totalProtein': proteinConsumed,
        'totalCarbs': carbsConsumed,
        'totalFat': fatConsumed,
      },
      'targets': {
        'calories': caloriesTarget,
        'protein': proteinTarget,
        'carbs': carbsTarget,
        'fat': fatTarget,
        'water': waterTarget,
      },
      'waterConsumed': waterConsumed,
      'logs': logs.map((l) => l.toJson()).toList(),
    };
  }
}
