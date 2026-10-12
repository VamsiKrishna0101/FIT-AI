import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/nutrition_diet_models.dart';

const foodCategories = <String, String>{
  'PROTEIN_SOURCE': 'Protein foods',
  'CARB_SOURCE': 'Grains & carbs',
  'VEGETABLE': 'Vegetables',
  'FRUIT': 'Fruit',
  'DAIRY': 'Dairy',
  'FAT_SOURCE': 'Fats & oils',
  'HEALTHY_FAT': 'Healthy fats',
  'MEAL': 'Prepared meals',
  'BEVERAGE': 'Drinks',
  'SUPPLEMENT': 'Supplements',
  'OTHER': 'Other foods',
};

/// Category artwork is a fallback, never represented as a product photograph.
class FoodArt extends StatelessWidget {
  final NutritionFoodItemModel food;
  final double size;
  const FoodArt({super.key, required this.food, this.size = 64});
  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (food.category) {
      'VEGETABLE' || 'FRUIT' => (Icons.eco_outlined, const Color(0xFFADC69F)),
      'DAIRY' => (CupertinoIcons.drop, const Color(0xFFB5C5DD)),
      'BEVERAGE' => (CupertinoIcons.drop_fill, const Color(0xFF9CC1D4)),
      'CARB_SOURCE' => (CupertinoIcons.sun_max, const Color(0xFFD0BC97)),
      'FAT_SOURCE' || 'HEALTHY_FAT' => (
          CupertinoIcons.drop,
          const Color(0xFFC8BA8F)
        ),
      'PROTEIN_SOURCE' => (CupertinoIcons.flame, const Color(0xFFCCA99B)),
      _ => (CupertinoIcons.circle_grid_3x3, const Color(0xFFB5ABCC)),
    };
    final fallback = Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              tint.withValues(alpha: .17),
              const Color(0xFF262626)
            ])),
        child: Center(child: Icon(icon, color: tint, size: size * .43)));
    final url = food.imageUrl;
    return Semantics(
        label: url == null
            ? '${foodCategories[food.category] ?? 'Food'} category icon'
            : food.name,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
                width: size,
                height: size,
                child: url == null || url.isEmpty
                    ? fallback
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        memCacheWidth: (size * 3).round(),
                        placeholder: (_, __) => fallback,
                        errorWidget: (_, __, ___) => fallback))));
  }
}
