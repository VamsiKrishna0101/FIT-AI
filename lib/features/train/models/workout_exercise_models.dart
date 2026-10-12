// MARK: - Workout & Exercise Models adhering to FitAI Exercise Schema

class WorkoutExerciseModel {
  final String id;
  final String name;
  String get displayName =>
      name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';
  final String? canonicalName;
  final String? contentLanguage;
  final String? bodyPartLabel;
  final String? targetLabel;
  final String? equipmentLabel;
  final String? difficultyLabel;
  final List<String>? secondaryMuscleLabels;
  final String bodyPart;
  final String target;
  final List<String> secondaryMuscles;
  final String equipment;
  final String difficulty;
  final String category;
  final String description;
  final List<String> instructions;
  final String? url;
  final String? thumbnailUrl;
  final int duration;
  final String? muscleGroup;
  final String? mediaId;
  final String? attribution;
  final Map<String, String>? instructionsByLang;
  final Map<String, List<String>>? instructionStepsByLang;

  const WorkoutExerciseModel({
    required this.id,
    required this.name,
    this.canonicalName,
    this.contentLanguage,
    this.bodyPartLabel,
    this.targetLabel,
    this.equipmentLabel,
    this.difficultyLabel,
    this.secondaryMuscleLabels,
    required this.bodyPart,
    required this.target,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    required this.category,
    required this.description,
    required this.instructions,
    this.url,
    this.thumbnailUrl,
    this.duration = 0,
    this.muscleGroup,
    this.mediaId,
    this.attribution,
    this.instructionsByLang,
    this.instructionStepsByLang,
  });

  /// True if the animation is an animated GIF
  bool get isGif {
    final u = (url ?? '').trim().toLowerCase();
    return u.endsWith('.gif') || u.contains('.gif?');
  }

  /// Returns a high-definition poster frame URL or high-res muscle fallback.
  String get effectiveThumbnailUrl {
    final thumb = thumbnailUrl?.trim() ?? '';
    if (thumb.isNotEmpty) {
      return thumb;
    }
    // If the animation URL has a gif or mp4 extension on Cloudflare R2, derive the image
    if (url != null && url!.isNotEmpty) {
      final clean = url!.trim();
      if (clean.contains('.gif') || clean.contains('.mp4')) {
        final lastSlash = clean.lastIndexOf('/');
        final filename =
            lastSlash != -1 ? clean.substring(lastSlash + 1) : clean;
        final base = lastSlash != -1 ? clean.substring(0, lastSlash) : '';
        final baseWithoutVideos = base.endsWith('/videos')
            ? base.substring(0, base.length - 7)
            : base.endsWith('/exercises')
                ? base.substring(0, base.length - 10)
                : base;
        final code = filename.replaceAll('.gif', '').replaceAll('.mp4', '');
        if (code.isNotEmpty) {
          return '$baseWithoutVideos/images/$code.jpg';
        }
      }
    }
    return fallbackMusclePoster(bodyPart.isNotEmpty ? bodyPart : target);
  }

  /// Returns localized instructions for a given locale code, falling back to default instructions.
  List<String> localizedInstructionSteps([String? langCode]) {
    if (langCode != null && instructionStepsByLang != null) {
      final steps = instructionStepsByLang![langCode] ??
          instructionStepsByLang![langCode.split('-').first];
      if (steps != null && steps.isNotEmpty) return steps;
    }
    return instructions;
  }

  static String fallbackMusclePoster(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('chest')) {
      return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=800&q=80';
    } else if (m.contains('back')) {
      return 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?auto=format&fit=crop&w=800&q=80';
    } else if (m.contains('leg') ||
        m.contains('quad') ||
        m.contains('hamstring') ||
        m.contains('glute')) {
      return 'https://images.unsplash.com/photo-1434608519344-49d77a699e1d?auto=format&fit=crop&w=800&q=80';
    } else if (m.contains('shoulder') || m.contains('delt')) {
      return 'https://images.unsplash.com/photo-1532384748853-8f54a8f476e2?auto=format&fit=crop&w=800&q=80';
    } else if (m.contains('arm') ||
        m.contains('bicep') ||
        m.contains('tricep')) {
      return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=800&q=80';
    } else if (m.contains('core') || m.contains('abs')) {
      return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=800&q=80';
    } else if (m.contains('cardio') || m.contains('run')) {
      return 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?auto=format&fit=crop&w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=80';
  }

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parsedByLang;
    if (json['instructionsByLang'] is Map) {
      parsedByLang = (json['instructionsByLang'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }

    Map<String, List<String>>? parsedStepsByLang;
    if (json['instructionStepsByLang'] is Map) {
      parsedStepsByLang = (json['instructionStepsByLang'] as Map).map(
        (k, v) => MapEntry(
          k.toString(),
          (v is List) ? v.map((s) => s.toString()).toList() : <String>[],
        ),
      );
    }

    return WorkoutExerciseModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      canonicalName: json['canonicalName']?.toString(),
      contentLanguage: json['contentLanguage']?.toString(),
      bodyPartLabel: json['bodyPartLabel']?.toString(),
      targetLabel: json['targetLabel']?.toString(),
      equipmentLabel: json['equipmentLabel']?.toString(),
      difficultyLabel: json['difficultyLabel']?.toString(),
      secondaryMuscleLabels: (json['secondaryMuscleLabels'] is List)
          ? (json['secondaryMuscleLabels'] as List)
              .map((value) => value.toString())
              .toList()
          : null,
      bodyPart: (json['bodyPart'] ?? json['target'] ?? 'Chest').toString(),
      target: (json['target'] ?? json['bodyPart'] ?? 'Chest').toString(),
      secondaryMuscles: (json['secondaryMuscles'] is List)
          ? (json['secondaryMuscles'] as List).map((e) => e.toString()).toList()
          : <String>[],
      equipment: (json['equipment'] ?? 'None').toString(),
      difficulty: (json['difficulty'] ?? 'Beginner').toString(),
      category: (json['category'] ?? 'Strength').toString(),
      description: (json['description'] ?? '').toString(),
      instructions: (json['instructions'] is List)
          ? (json['instructions'] as List).map((e) => e.toString()).toList()
          : <String>[],
      url: (json['url'] ?? json['videoUrl'])?.toString(),
      thumbnailUrl: (json['thumbnailUrl'] ??
              json['posterUrl'] ??
              json['thumbnail'] ??
              json['image'])
          ?.toString(),
      duration:
          (json['duration'] is num) ? (json['duration'] as num).toInt() : 0,
      muscleGroup: json['muscleGroup']?.toString(),
      mediaId: json['mediaId']?.toString(),
      attribution: json['attribution']?.toString(),
      instructionsByLang: parsedByLang,
      instructionStepsByLang: parsedStepsByLang,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'canonicalName': canonicalName,
      'contentLanguage': contentLanguage,
      'bodyPartLabel': bodyPartLabel,
      'targetLabel': targetLabel,
      'equipmentLabel': equipmentLabel,
      'difficultyLabel': difficultyLabel,
      'secondaryMuscleLabels': secondaryMuscleLabels,
      'bodyPart': bodyPart,
      'target': target,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'difficulty': difficulty,
      'category': category,
      'description': description,
      'instructions': instructions,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'muscleGroup': muscleGroup,
      'mediaId': mediaId,
      'attribution': attribution,
      'instructionsByLang': instructionsByLang,
      'instructionStepsByLang': instructionStepsByLang,
    };
  }
}

class TodayPlanItemModel {
  final String id;
  final String dayOfWeek;
  final int orderIndex;
  final int targetSets;
  final String targetReps;
  final double targetWeight;
  final double? targetRpe;
  final int restSeconds;
  final String status; // "NOT_STARTED", "IN_PROGRESS", "COMPLETED", "SKIPPED"
  final DateTime? completedAt;
  final WorkoutExerciseModel exercise;

  const TodayPlanItemModel({
    required this.id,
    required this.dayOfWeek,
    required this.orderIndex,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    this.targetRpe,
    required this.restSeconds,
    required this.status,
    this.completedAt,
    required this.exercise,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isSkipped => status == 'SKIPPED';
  bool get isPending => !isCompleted && !isSkipped;

  TodayPlanItemModel copyWith({
    String? id,
    String? dayOfWeek,
    int? orderIndex,
    int? targetSets,
    String? targetReps,
    double? targetWeight,
    double? targetRpe,
    int? restSeconds,
    String? status,
    DateTime? completedAt,
    WorkoutExerciseModel? exercise,
  }) {
    return TodayPlanItemModel(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      orderIndex: orderIndex ?? this.orderIndex,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetRpe: targetRpe ?? this.targetRpe,
      restSeconds: restSeconds ?? this.restSeconds,
      status: status ?? this.status,
      completedAt: status != null && status != 'COMPLETED'
          ? null
          : completedAt ?? this.completedAt,
      exercise: exercise ?? this.exercise,
    );
  }

  factory TodayPlanItemModel.fromJson(Map<String, dynamic> json) {
    final workoutData = json['workout'] is Map<String, dynamic>
        ? json['workout'] as Map<String, dynamic>
        : <String, dynamic>{};

    return TodayPlanItemModel(
      id: (json['id'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? '').toString(),
      orderIndex:
          (json['orderIndex'] is num) ? (json['orderIndex'] as num).toInt() : 0,
      targetSets:
          (json['targetSets'] is num) ? (json['targetSets'] as num).toInt() : 3,
      targetReps: (json['targetReps'] ?? '8-12').toString(),
      targetWeight: (json['targetWeight'] is num)
          ? (json['targetWeight'] as num).toDouble()
          : 0.0,
      targetRpe: (json['targetRpe'] is num)
          ? (json['targetRpe'] as num).toDouble()
          : null,
      restSeconds: (json['restSeconds'] is num)
          ? (json['restSeconds'] as num).toInt()
          : 60,
      status: (json['status'] ?? 'NOT_STARTED').toString(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      exercise: WorkoutExerciseModel.fromJson(workoutData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'orderIndex': orderIndex,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'targetRpe': targetRpe,
      'restSeconds': restSeconds,
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'workout': exercise.toJson(),
    };
  }
}

class TodayPlanModel {
  final String id;
  final String weekLabel;
  final String status;
  final String? aiNote;
  final List<TodayPlanItemModel> items;

  const TodayPlanModel({
    required this.id,
    required this.weekLabel,
    required this.status,
    this.aiNote,
    required this.items,
  });

  int get completedCount => items.where((i) => i.isCompleted).length;
  int get skippedCount => items.where((i) => i.isSkipped).length;
  int get totalCount => items.length;
  double get progress =>
      totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);
  int get estimatedDurationMinutes => items.fold<int>(
        0,
        (sum, item) =>
            sum + (item.exercise.duration > 0 ? item.exercise.duration : 0),
      );

  TodayPlanModel copyWith({
    String? id,
    String? weekLabel,
    String? status,
    String? aiNote,
    List<TodayPlanItemModel>? items,
  }) {
    return TodayPlanModel(
      id: id ?? this.id,
      weekLabel: weekLabel ?? this.weekLabel,
      status: status ?? this.status,
      aiNote: aiNote ?? this.aiNote,
      items: items ?? this.items,
    );
  }

  factory TodayPlanModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] is List ? json['items'] as List : [];
    final itemsList = rawItems
        .map((e) => TodayPlanItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return TodayPlanModel(
      id: (json['id'] ?? '').toString(),
      weekLabel: (json['weekLabel'] ?? 'Week 1').toString(),
      status: (json['status'] ?? 'IN_PROGRESS').toString(),
      aiNote: json['aiNote']?.toString(),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekLabel': weekLabel,
      'status': status,
      'aiNote': aiNote,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
