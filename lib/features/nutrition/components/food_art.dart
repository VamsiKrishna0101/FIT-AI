import '../../../core/localization/fitness_copy.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/nutrition_diet_models.dart';

String foodPortionLabel(BuildContext context, NutritionFoodItemModel food) {
  final portion = food.preferredPortion;
  if (portion == null || portion.unit == 'ml') return food.previewQuantity;
  return '1 ${fitnessText(context, portion.label)}';
}

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
                    : url.startsWith('/api/nutrition/me/custom-foods/')
                        ? _PrivateFoodPhoto(
                            url: url, fallback: fallback, size: size)
                        : CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            memCacheWidth: (size * 3).round(),
                            placeholder: (_, __) => fallback,
                            errorWidget: (_, __, ___) => fallback))));
  }
}

class _PrivateFoodPhoto extends StatefulWidget {
  final String url;
  final Widget fallback;
  final double size;
  const _PrivateFoodPhoto(
      {required this.url, required this.fallback, required this.size});
  @override
  State<_PrivateFoodPhoto> createState() => _PrivateFoodPhotoState();
}

class _PrivateFoodPhotoState extends State<_PrivateFoodPhoto> {
  late Future<Uint8List?> _photo;
  @override
  void initState() {
    super.initState();
    _photo = _load();
  }

  @override
  void didUpdateWidget(covariant _PrivateFoodPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) _photo = _load();
  }

  Future<Uint8List?> _load() async {
    try {
      final response = await ApiClient.shared.client.get<List<int>>(widget.url,
          options: Options(responseType: ResponseType.bytes));
      return response.data == null ? null : Uint8List.fromList(response.data!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
      future: _photo,
      builder: (_, snapshot) => snapshot.data == null
          ? widget.fallback
          : Image.memory(snapshot.data!,
              fit: BoxFit.cover,
              cacheWidth: (widget.size * 3).round(),
              errorBuilder: (_, __, ___) => widget.fallback));
}
