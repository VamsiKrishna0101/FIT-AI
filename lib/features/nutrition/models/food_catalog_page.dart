import 'nutrition_diet_models.dart';

class FoodCatalogPage {
  final List<NutritionFoodItemModel> foods;
  final int page, total, totalPages;
  const FoodCatalogPage(
      {required this.foods,
      required this.page,
      required this.total,
      required this.totalPages});
  factory FoodCatalogPage.fromJson(Map<String, dynamic> json) =>
      FoodCatalogPage(
          foods: (json['foods'] as List)
              .map((row) => NutritionFoodItemModel.fromJson(
                  Map<String, dynamic>.from(row as Map)))
              .toList(),
          page: (json['page'] as num).toInt(),
          total: (json['total'] as num).toInt(),
          totalPages: (json['totalPages'] as num).toInt());
}
