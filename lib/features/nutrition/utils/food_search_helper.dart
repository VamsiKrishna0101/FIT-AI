import '../models/nutrition_diet_models.dart';

/// Helper for food search query normalization, stemming, and relevance ranking.
class FoodSearchHelper {
  FoodSearchHelper._();

  static final Map<String, String> _phraseAliases = {
    'egg': 'egg',
    'eggs': 'egg',
    'whole egg': 'egg',
    'whole eggs': 'egg',
    'raw egg': 'egg',
    'raw eggs': 'egg',
    'boiled egg': 'boiled egg',
    'boiled eggs': 'boiled egg',
    'hard boiled egg': 'boiled egg',
    'hard boiled eggs': 'boiled egg',
    'soft boiled egg': 'boiled egg',
    'soft boiled eggs': 'boiled egg',
    'scrambled egg': 'scrambled egg',
    'scrambled eggs': 'scrambled egg',
    'fried egg': 'fried egg',
    'fried eggs': 'fried egg',
    'sunny side up': 'fried egg',
    'over easy': 'fried egg',
    'poached egg': 'poached egg',
    'poached eggs': 'poached egg',
    'egg white': 'egg white',
    'egg whites': 'egg white',
    'white egg': 'egg white',
    'white eggs': 'egg white',
    'egg yolk': 'egg yolk',
    'egg yolks': 'egg yolk',
    'oatmeal': 'oat',
    'oats': 'oat',
    'porridge': 'oat',
    'pb': 'peanut butter',
    'peanutbutter': 'peanut butter',
    'peanut butter': 'peanut butter',
    'yoghurt': 'yogurt',
    'yoghurts': 'yogurt',
    'yogurt': 'yogurt',
    'yogurts': 'yogurt',
    'curd': 'yogurt',
    'eggplant': 'aubergine',
    'eggplants': 'aubergine',
    'brinjal': 'aubergine',
    'sweet potato': 'sweet potato',
    'sweet potatoes': 'sweet potato',
    'sweetpotato': 'sweet potato',
    'sweetpotatoes': 'sweet potato',
    'chicken breast': 'chicken breast',
    'chicken breasts': 'chicken breast',
    'chicken thigh': 'chicken thigh',
    'chicken thighs': 'chicken thigh',
  };

  static final Map<String, String> _wordAliases = {
    'eggs': 'egg',
    'apples': 'apple',
    'bananas': 'banana',
    'oranges': 'orange',
    'potatoes': 'potato',
    'tomatoes': 'tomato',
    'strawberries': 'strawberry',
    'blueberries': 'blueberry',
    'raspberries': 'raspberry',
    'blackberries': 'blackberry',
    'berries': 'berry',
    'peanuts': 'peanut',
    'almonds': 'almond',
    'walnuts': 'walnut',
    'cashews': 'cashew',
    'lentils': 'lentil',
    'beans': 'bean',
    'peas': 'pea',
    'carrots': 'carrot',
    'cucumbers': 'cucumber',
    'onions': 'onion',
    'mushrooms': 'mushroom',
    'oats': 'oat',
    'oatmeal': 'oat',
    'porridge': 'oat',
    'yoghurt': 'yogurt',
    'curd': 'yogurt',
    'eggplant': 'aubergine',
    'eggplants': 'aubergine',
    'brinjal': 'aubergine',
  };

  /// Normalizes a user query before sending to backend catalog API.
  /// Converts plurals and synonyms (e.g. 'eggs' -> 'egg', 'hard boiled eggs' -> 'boiled egg')
  /// so that even backends without stemming find the target foods.
  static String normalizeForCatalogQuery(String raw) {
    final query = raw.trim().toLowerCase();
    if (query.isEmpty) return '';

    if (_phraseAliases.containsKey(query)) {
      return _phraseAliases[query]!;
    }

    final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return query;

    final normalizedWords = words.map((w) {
      if (_wordAliases.containsKey(w)) {
        return _wordAliases[w]!;
      }
      return singularize(w);
    }).toList();

    final result = normalizedWords.join(' ');
    return _phraseAliases[result] ?? result;
  }

  /// English de-pluralization heuristic.
  static String singularize(String word) {
    if (word.length <= 3) return word;
    if (_wordAliases.containsKey(word)) return _wordAliases[word]!;
    if (word.endsWith('ies') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('oes') && word.length > 4) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('es') && word.length > 4) {
      final base = word.substring(0, word.length - 2);
      if (base.endsWith('s') ||
          base.endsWith('x') ||
          base.endsWith('z') ||
          base.endsWith('ch') ||
          base.endsWith('sh')) {
        return base;
      }
      return word.substring(0, word.length - 1);
    }
    if (word.endsWith('s') && !word.endsWith('ss') && word.length > 3) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  /// Generates search token variants for word-boundary matching.
  static List<String> variantsFor(String term) {
    final lower = term.toLowerCase().trim();
    final set = <String>{lower};

    if (_wordAliases.containsKey(lower)) {
      set.add(_wordAliases[lower]!);
    }
    final sing = singularize(lower);
    if (sing != lower) set.add(sing);

    if (lower.endsWith('y') && lower.length > 3) {
      set.add('${lower.substring(0, lower.length - 1)}ies');
    } else if (!lower.endsWith('s') && lower.length >= 2) {
      set.add('${lower}s');
    }

    if (lower == 'egg' || lower == 'eggs') {
      set.add('egg');
      set.add('eggs');
    }
    if (lower == 'aubergine' || lower == 'eggplant' || lower == 'eggplants') {
      set.add('aubergine');
      set.add('eggplant');
      set.add('eggplants');
      set.add('brinjal');
    }

    return set.toList();
  }

  /// Checks if token matches text with strict word boundaries so short tokens
  /// like 'egg' do not match inside 'aubergine', 'eggplant', etc.
  static bool matchWord(String text, String term) {
    final variants = variantsFor(term);
    for (final v in variants) {
      final esc = RegExp.escape(v);
      if (RegExp('(?:^|[^a-zA-Z0-9])$esc(?:\\\$|[^a-zA-Z0-9])',
              caseSensitive: false)
          .hasMatch(text)) {
        return true;
      }
      if (['berry', 'berries', 'nut', 'nuts', 'bean', 'beans', 'seed', 'seeds']
          .contains(v)) {
        if (RegExp('$esc(?:\\\$|[^a-zA-Z0-9])', caseSensitive: false)
            .hasMatch(text)) {
          return true;
        }
      }
      if (v.length >= 4 &&
          RegExp('(?:^|[^a-zA-Z0-9])$esc', caseSensitive: false)
              .hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// Computes relevance score for ranking.
  static double scoreFood(NutritionFoodItemModel food, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return 0.0;

    final normQuery = normalizeForCatalogQuery(query);
    final terms = query.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final normTerms = normQuery.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    final name = food.name.toLowerCase();
    final brand = (food.brand ?? '').toLowerCase();
    final combined = '$name $brand'.trim();

    final baseName = name.split(RegExp(r'[—–,-]'))[0].trim();

    double score = 0.0;

    // Special exact canonical checks (e.g. egg / eggs)
    if ((query == 'egg' || query == 'eggs' || normQuery == 'egg') &&
        baseName == 'egg') {
      score += 5000;
      if (name.contains('raw')) score += 500;
    } else if (baseName == query || baseName == normQuery) {
      score += 4000;
    } else if (name == query || name == normQuery) {
      score += 3500;
    } else if (name.startsWith(query) || name.startsWith(normQuery)) {
      score += 2500;
    } else if (baseName.startsWith(query) || baseName.startsWith(normQuery)) {
      score += 2200;
    }

    // Term matches
    final allTerms = {...terms, ...normTerms};
    int matchedCount = 0;
    for (final t in terms) {
      if (matchWord(combined, t)) {
        matchedCount++;
      }
    }
    if (matchedCount == terms.length && terms.isNotEmpty) {
      score += 1500;
    } else if (matchedCount > 0) {
      score += (matchedCount / terms.length) * 800;
    }

    // Culinary aliases
    if (query.contains('boiled') && name.contains('boiled')) score += 1000;
    if (query.contains('scrambled') && name.contains('scrambled')) score += 1000;
    if ((query.contains('fried') || query.contains('sunny')) &&
        name.contains('fried')) score += 1000;
    if (query.contains('poached') && name.contains('poached')) score += 1000;
    if (query.contains('white') && name.contains('white')) score += 1000;

    // Brevity bonus for concise food names
    if (score > 0) {
      score += (300 - (name.length * 3).clamp(0, 300));
    }

    return score;
  }

  /// Filters and ranks a list of foods.
  static List<NutritionFoodItemModel> filterAndRank({
    required List<NutritionFoodItemModel> foods,
    required String query,
    String? category,
    String focus = 'ALL',
    String sort = 'NAME',
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final normQuery = normalizeForCatalogQuery(cleanQuery);
    final terms = cleanQuery.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    final filtered = foods.where((f) {
      final per100 = f.servingUnit == 'g' && f.servingSize > 0
          ? 100 / f.servingSize
          : 0.0;
      final text = '${f.name} ${f.brand ?? ''}'.toLowerCase();
      final categoryOk = category == null || category == f.category;
      final focusOk = focus == 'ALL' ||
          (per100 > 0 &&
              switch (focus) {
                'PROTEIN' => f.proteinPerServing * per100 >= 15,
                'FIBRE' => f.fiberPerServing * per100 >= 3,
                _ => f.caloriesPerServing * per100 <= 100,
              });
      if (!categoryOk || !focusOk) return false;
      if (terms.isEmpty) return true;

      // Check if all terms or normalized terms match
      final matchAllRaw = terms.every((t) => matchWord(text, t));
      if (matchAllRaw) return true;

      final normTerms =
          normQuery.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      final matchAllNorm =
          normTerms.isNotEmpty && normTerms.every((t) => matchWord(text, t));
      return matchAllNorm;
    }).toList();

    double value(NutritionFoodItemModel f) =>
        f.servingUnit == 'g' && f.servingSize > 0
            ? (_sortValue(f, sort) * 100 / f.servingSize)
            : (sort == 'PROTEIN' ? double.negativeInfinity : double.infinity);

    filtered.sort((a, b) {
      if (cleanQuery.isNotEmpty && sort == 'NAME') {
        final sa = scoreFood(a, cleanQuery);
        final sb = scoreFood(b, cleanQuery);
        if (sb != sa) return sb.compareTo(sa);
      }
      final comparison = sort == 'NAME'
          ? 0
          : sort == 'PROTEIN'
              ? value(b).compareTo(value(a))
              : value(a).compareTo(value(b));
      return comparison != 0 ? comparison : a.name.compareTo(b.name);
    });

    return filtered;
  }

  static double _sortValue(NutritionFoodItemModel f, String sort) {
    if (sort == 'PROTEIN') return f.proteinPerServing;
    return f.caloriesPerServing;
  }
}
