// MARK: - 3D Body Scan & Heatmap Data Models
import 'package:flutter/material.dart';

class BodyScanModel {
  final String id;
  final DateTime scanDate;
  final double chestCircumference;
  final double waistCircumference;
  final double hipCircumference;
  final double bicepLeftCircumference;
  final double bicepRightCircumference;
  final double thighLeftCircumference;
  final double thighRightCircumference;
  final double shoulderWidth;
  final int overallSymmetryScore;
  final double vTaperRatio;
  final List<String> laggingMuscles;
  final List<String> strongMuscles;
  final String? fullModelGlbUrl;
  final String? heatmapGlbUrl;
  final String? deltaGlbUrl;
  final String? scanSource;
  final double? heightCm;
  final int? viewsUsed;
  final Map<String, dynamic>? scanAnalysis;

  const BodyScanModel({
    required this.id,
    required this.scanDate,
    required this.chestCircumference,
    required this.waistCircumference,
    required this.hipCircumference,
    required this.bicepLeftCircumference,
    required this.bicepRightCircumference,
    required this.thighLeftCircumference,
    required this.thighRightCircumference,
    required this.shoulderWidth,
    required this.overallSymmetryScore,
    required this.vTaperRatio,
    this.laggingMuscles = const [],
    this.strongMuscles = const [],
    this.fullModelGlbUrl,
    this.heatmapGlbUrl,
    this.deltaGlbUrl,
    this.scanSource,
    this.heightCm,
    this.viewsUsed,
    this.scanAnalysis,
  });

  bool get hasScan => id.isNotEmpty && id != 'default-baseline';

  bool get hasTrainingFocusHeatmap {
    final focus = scanAnalysis?['trainingFocus'];
    return focus is Map &&
        focus['source'] == 'weekly_workout_plan' &&
        focus['regions'] is List;
  }

  bool get hasAnthropometricHeatmap {
    return scanAnalysis is Map &&
        (scanAnalysis?['heatmapMuscleColors'] is Map ||
            scanAnalysis?['ratios'] is Map);
  }

  AnthropometricScanAnalysisModel? get anthropometrics {
    if (scanAnalysis == null) return null;
    try {
      return AnthropometricScanAnalysisModel.fromJson(scanAnalysis!);
    } catch (_) {
      return null;
    }
  }

  List<TrainingFocusRegionModel> get trainingFocusRegions {
    final focus = scanAnalysis?['trainingFocus'];
    final regions = focus is Map ? focus['regions'] : null;
    if (regions is! List) return const [];
    return regions
        .whereType<Map>()
        .map((region) => TrainingFocusRegionModel.fromJson(
            Map<String, dynamic>.from(region)))
        .toList(growable: false);
  }

  factory BodyScanModel.fromJson(Map<String, dynamic> json) {
    return BodyScanModel(
      id: json['id'] as String? ?? '',
      scanDate: json['scanDate'] != null
          ? DateTime.tryParse(json['scanDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      chestCircumference: (json['chestCircumference'] as num?)?.toDouble() ?? 0,
      waistCircumference: (json['waistCircumference'] as num?)?.toDouble() ?? 0,
      hipCircumference: (json['hipCircumference'] as num?)?.toDouble() ?? 0,
      bicepLeftCircumference:
          (json['bicepLeftCircumference'] as num?)?.toDouble() ?? 0,
      bicepRightCircumference:
          (json['bicepRightCircumference'] as num?)?.toDouble() ?? 0,
      thighLeftCircumference:
          (json['thighLeftCircumference'] as num?)?.toDouble() ?? 0,
      thighRightCircumference:
          (json['thighRightCircumference'] as num?)?.toDouble() ?? 0,
      shoulderWidth: (json['shoulderWidth'] as num?)?.toDouble() ?? 0,
      overallSymmetryScore:
          (json['overallSymmetryScore'] as num?)?.toInt() ?? 0,
      vTaperRatio: (json['vTaperRatio'] as num?)?.toDouble() ?? 0,
      laggingMuscles: (json['laggingMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      strongMuscles: (json['strongMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      fullModelGlbUrl: json['fullModelGlbUrl'] as String?,
      heatmapGlbUrl: json['heatmapGlbUrl'] as String?,
      deltaGlbUrl: json['deltaGlbUrl'] as String?,
      scanSource: json['scanSource'] as String? ?? 'legacy',
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      viewsUsed: (json['viewsUsed'] as num?)?.toInt(),
      scanAnalysis: json['scanAnalysis'] is Map
          ? Map<String, dynamic>.from(json['scanAnalysis'] as Map)
          : null,
    );
  }

  String measurementLabel(String key, double value) {
    if (value <= 0) return '—';
    final estimates = scanAnalysis?['measurementEstimates'];
    final estimate = estimates is Map ? estimates[key] : null;
    if (estimate is Map && estimate['uncertaintyCm'] is num) {
      final uncertainty = (estimate['uncertaintyCm'] as num).toDouble();
      return '${value.toStringAsFixed(1)} ± ${uncertainty.toStringAsFixed(1)} cm*';
    }
    return '~${value.toStringAsFixed(1)} cm';
  }
}

class TrainingFocusRegionModel {
  final String id;
  final String label;
  final String status;
  final double plannedSets;
  final double setsDue;
  final double completedSets;
  final double? completionRatio;

  const TrainingFocusRegionModel({
    required this.id,
    required this.label,
    required this.status,
    required this.plannedSets,
    required this.setsDue,
    required this.completedSets,
    required this.completionRatio,
  });

  factory TrainingFocusRegionModel.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return TrainingFocusRegionModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      status: json['status'] as String? ?? 'no_plan',
      plannedSets: number('plannedSets'),
      setsDue: number('setsDue'),
      completedSets: number('completedSets'),
      completionRatio: (json['completionRatio'] as num?)?.toDouble(),
    );
  }
}

class HeatmapColorExplanationModel {
  final String region;
  final String color;
  final String meaning;

  const HeatmapColorExplanationModel({
    required this.region,
    required this.color,
    required this.meaning,
  });

  factory HeatmapColorExplanationModel.fromJson(Map<String, dynamic> json) {
    return HeatmapColorExplanationModel(
      region: json['region'] as String? ?? '',
      color: json['color'] as String? ?? 'Green',
      meaning: json['meaning'] as String? ?? '',
    );
  }
}

class PartBreakdownModel {
  final String partName;
  final double changeCm;
  final double beforeCm;
  final double afterCm;
  final double uncertaintyCm;
  final String? beforeVisualBand;
  final String? afterVisualBand;
  final String status;
  final String biologicalReason;

  const PartBreakdownModel({
    required this.partName,
    required this.changeCm,
    required this.beforeCm,
    required this.afterCm,
    required this.uncertaintyCm,
    this.beforeVisualBand,
    this.afterVisualBand,
    required this.status,
    required this.biologicalReason,
  });

  factory PartBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PartBreakdownModel(
      partName: json['partName'] as String? ?? '',
      changeCm: (json['changeCm'] as num?)?.toDouble() ?? 0.0,
      beforeCm: (json['beforeCm'] as num?)?.toDouble() ?? 0.0,
      afterCm: (json['afterCm'] as num?)?.toDouble() ?? 0.0,
      uncertaintyCm: (json['uncertaintyCm'] as num?)?.toDouble() ?? 0.0,
      beforeVisualBand: json['beforeVisualBand'] as String?,
      afterVisualBand: json['afterVisualBand'] as String?,
      status: json['status'] as String? ?? 'MAINTAINED',
      biologicalReason: json['biologicalReason'] as String? ?? '',
    );
  }
}

class HeatmapComparisonModel {
  final String scan1Id;
  final String scan2Id;
  final int daysBetween;
  final String executiveVerdict;
  final double transformationScore;
  final String summaryParagraph;
  final List<HeatmapColorExplanationModel> heatmapColorExplanations;
  final List<PartBreakdownModel> partBreakdowns;
  final String symmetryVerdict;
  final List<String> workoutAdjustments;
  final TrainingFocusComparisonModel trainingFocusComparison;

  const HeatmapComparisonModel({
    required this.scan1Id,
    required this.scan2Id,
    required this.daysBetween,
    required this.executiveVerdict,
    required this.transformationScore,
    required this.summaryParagraph,
    required this.heatmapColorExplanations,
    required this.partBreakdowns,
    required this.symmetryVerdict,
    required this.workoutAdjustments,
    this.trainingFocusComparison =
        const TrainingFocusComparisonModel.unavailable(),
  });

  factory HeatmapComparisonModel.fromJson(Map<String, dynamic> json) {
    return HeatmapComparisonModel(
      scan1Id: json['scan1Id'] as String? ?? '',
      scan2Id: json['scan2Id'] as String? ?? '',
      daysBetween: (json['daysBetween'] as num?)?.toInt() ?? 0,
      executiveVerdict: json['executiveVerdict'] as String? ?? '',
      transformationScore:
          (json['transformationScore'] as num?)?.toDouble() ?? 0,
      summaryParagraph: json['summaryParagraph'] as String? ?? '',
      heatmapColorExplanations:
          (json['heatmapColorExplanations'] as List<dynamic>?)
                  ?.map((e) => HeatmapColorExplanationModel.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              const [],
      partBreakdowns: (json['partBreakdowns'] as List<dynamic>?)
              ?.map(
                  (e) => PartBreakdownModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      symmetryVerdict: json['symmetryVerdict'] as String? ?? '',
      workoutAdjustments: (json['workoutAdjustments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      trainingFocusComparison: TrainingFocusComparisonModel.fromJson(
          json['trainingFocusComparison']),
    );
  }
}

class TrainingFocusComparisonModel {
  final bool available;
  final String? beforeWeekLabel;
  final String? afterWeekLabel;
  final String note;
  final List<TrainingFocusRegionComparisonModel> regions;

  const TrainingFocusComparisonModel({
    required this.available,
    required this.beforeWeekLabel,
    required this.afterWeekLabel,
    required this.note,
    required this.regions,
  });

  const TrainingFocusComparisonModel.unavailable()
      : available = false,
        beforeWeekLabel = null,
        afterWeekLabel = null,
        note = '',
        regions = const [];

  factory TrainingFocusComparisonModel.fromJson(dynamic value) {
    if (value is! Map) return const TrainingFocusComparisonModel.unavailable();
    final json = Map<String, dynamic>.from(value);
    return TrainingFocusComparisonModel(
      available: json['available'] as bool? ?? false,
      beforeWeekLabel: json['beforeWeekLabel'] as String?,
      afterWeekLabel: json['afterWeekLabel'] as String?,
      note: json['note'] as String? ?? '',
      regions: (json['regions'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((region) => TrainingFocusRegionComparisonModel.fromJson(
                  Map<String, dynamic>.from(region)))
              .toList(growable: false) ??
          const [],
    );
  }
}

class TrainingFocusRegionComparisonModel {
  final String regionId;
  final String label;
  final String beforeStatus;
  final String afterStatus;
  final double? beforeCompletionRatio;
  final double? afterCompletionRatio;
  final double? completionRatioChange;
  final double beforePlannedSets;
  final double afterPlannedSets;
  final double beforeCompletedSets;
  final double afterCompletedSets;

  const TrainingFocusRegionComparisonModel({
    required this.regionId,
    required this.label,
    required this.beforeStatus,
    required this.afterStatus,
    required this.beforeCompletionRatio,
    required this.afterCompletionRatio,
    required this.completionRatioChange,
    required this.beforePlannedSets,
    required this.afterPlannedSets,
    required this.beforeCompletedSets,
    required this.afterCompletedSets,
  });

  factory TrainingFocusRegionComparisonModel.fromJson(
      Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    double? nullableNumber(String key) => (json[key] as num?)?.toDouble();
    return TrainingFocusRegionComparisonModel(
      regionId: json['regionId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      beforeStatus: json['beforeStatus'] as String? ?? 'no_plan',
      afterStatus: json['afterStatus'] as String? ?? 'no_plan',
      beforeCompletionRatio: nullableNumber('beforeCompletionRatio'),
      afterCompletionRatio: nullableNumber('afterCompletionRatio'),
      completionRatioChange: nullableNumber('completionRatioChange'),
      beforePlannedSets: number('beforePlannedSets'),
      afterPlannedSets: number('afterPlannedSets'),
      beforeCompletedSets: number('beforeCompletedSets'),
      afterCompletedSets: number('afterCompletedSets'),
    );
  }
}

// 3D Camera Target & Orbit definitions for deep anatomical part inspection
enum BodyPartZoom {
  fullBody,
  chest,
  waist,
  arms,
  lats,
  legs,
}

class BodyPartInspectionConfig {
  final BodyPartZoom part;
  final String label;
  final IconData icon;
  final double targetX;
  final double targetY;
  final double targetZ;
  final double orbitTheta;
  final double orbitPhi;
  final double orbitRadius;

  const BodyPartInspectionConfig({
    required this.part,
    required this.label,
    required this.icon,
    required this.targetX,
    required this.targetY,
    required this.targetZ,
    required this.orbitTheta,
    required this.orbitPhi,
    required this.orbitRadius,
  });

  static const List<BodyPartInspectionConfig> configs = [
    BodyPartInspectionConfig(
      part: BodyPartZoom.fullBody,
      label: 'Full Body',
      icon: Icons.accessibility_new_rounded,
      targetX: 0.0,
      targetY: 0.0,
      targetZ: 0.0,
      orbitTheta: 0.0,
      orbitPhi: 90.0,
      orbitRadius: 2.3,
    ),
    BodyPartInspectionConfig(
      part: BodyPartZoom.chest,
      label: 'Chest',
      icon: Icons.fitness_center_rounded,
      targetX: 0.0,
      targetY: 0.22,
      targetZ: 0.0,
      orbitTheta: 0.0,
      orbitPhi: 90.0,
      orbitRadius: 1.15,
    ),
    BodyPartInspectionConfig(
      part: BodyPartZoom.waist,
      label: 'Waist',
      icon: Icons.straighten_rounded,
      targetX: 0.0,
      targetY: -0.05,
      targetZ: 0.0,
      orbitTheta: 0.0,
      orbitPhi: 90.0,
      orbitRadius: 1.05,
    ),
    BodyPartInspectionConfig(
      part: BodyPartZoom.arms,
      label: 'Arms',
      icon: Icons.sports_martial_arts_rounded,
      targetX: 0.22,
      targetY: 0.15,
      targetZ: 0.0,
      orbitTheta: 40.0,
      orbitPhi: 90.0,
      orbitRadius: 0.95,
    ),
    BodyPartInspectionConfig(
      part: BodyPartZoom.lats,
      label: 'Lats & Back',
      icon: Icons.shield_moon_rounded,
      targetX: 0.0,
      targetY: 0.18,
      targetZ: 0.0,
      orbitTheta: 180.0, // 180-degree rotation to show back
      orbitPhi: 90.0,
      orbitRadius: 1.20,
    ),
    BodyPartInspectionConfig(
      part: BodyPartZoom.legs,
      label: 'Quads & Legs',
      icon: Icons.directions_run_rounded,
      targetX: 0.0,
      targetY: -0.40,
      targetZ: 0.0,
      orbitTheta: 0.0,
      orbitPhi: 90.0,
      orbitRadius: 1.25,
    ),
  ];
}

// ── Anthropometric 4-View & LLM Diagnostic Models ───────────────────────────

Color parseAnthropometricHex(String? hexString,
    {Color fallback = const Color(0xFF455A64)}) {
  if (hexString == null || hexString.isEmpty) return fallback;
  try {
    final hex = hexString.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  } catch (_) {}
  return fallback;
}

class AnthropometricScanAnalysisModel {
  final int schemaVersion;
  final String pipeline;
  final String gender;
  final PhysiqueRatiosModel ratios;
  final PhysiqueEvaluationsModel evaluations;
  final IdealBenchmarksModel benchmarks;
  final Map<String, MuscleHeatmapItemModel> heatmapMuscleColors;
  final PhysiqueSummaryModel physiqueSummary;
  final NextTargetsModel? nextTargets;
  final List<String> safetyNotes;
  final List<String> plausibilityWarnings;
  final AnthropometricComparisonModel? comparison;

  const AnthropometricScanAnalysisModel({
    required this.schemaVersion,
    required this.pipeline,
    required this.gender,
    required this.ratios,
    required this.evaluations,
    required this.benchmarks,
    required this.heatmapMuscleColors,
    required this.physiqueSummary,
    this.nextTargets,
    this.safetyNotes = const [],
    this.plausibilityWarnings = const [],
    this.comparison,
  });

  bool get isFemale => gender.toUpperCase() == 'FEMALE';

  factory AnthropometricScanAnalysisModel.fromJson(Map<String, dynamic> json) {
    final rawMuscles = json['heatmapMuscleColors'];
    final Map<String, MuscleHeatmapItemModel> muscles = {};
    if (rawMuscles is Map) {
      rawMuscles.forEach((key, val) {
        if (val is Map) {
          muscles[key.toString()] = MuscleHeatmapItemModel.fromJson(
            Map<String, dynamic>.from(val),
          );
        }
      });
    }

    final rawWarnings = json['plausibilityWarnings'];
    final List<String> warnings = [];
    if (rawWarnings is List) {
      for (final w in rawWarnings) {
        if (w != null) warnings.add(w.toString());
      }
    }

    final rawSafety = json['safetyNotes'];
    final List<String> safety = [];
    if (rawSafety is List) {
      for (final s in rawSafety) {
        if (s != null) safety.add(s.toString());
      }
    }

    final rawComparison = json['comparison'];

    return AnthropometricScanAnalysisModel(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 4,
      pipeline: json['pipeline'] as String? ?? 'anthropometric_4view',
      gender: json['gender'] as String? ?? 'MALE',
      ratios: PhysiqueRatiosModel.fromJson(
        json['ratios'] is Map
            ? Map<String, dynamic>.from(json['ratios'] as Map)
            : {},
      ),
      evaluations: PhysiqueEvaluationsModel.fromJson(
        json['evaluations'] is Map
            ? Map<String, dynamic>.from(json['evaluations'] as Map)
            : {},
      ),
      benchmarks: IdealBenchmarksModel.fromJson(
        json['benchmarks'] is Map
            ? Map<String, dynamic>.from(json['benchmarks'] as Map)
            : {},
      ),
      heatmapMuscleColors: muscles,
      physiqueSummary: PhysiqueSummaryModel.fromJson(
        json['physiqueSummary'] is Map
            ? Map<String, dynamic>.from(json['physiqueSummary'] as Map)
            : {},
      ),
      nextTargets: json['nextTargets'] is Map
          ? NextTargetsModel.fromJson(
              Map<String, dynamic>.from(json['nextTargets'] as Map))
          : null,
      safetyNotes: safety,
      plausibilityWarnings: warnings,
      comparison: rawComparison is Map
          ? AnthropometricComparisonModel.fromJson(
              Map<String, dynamic>.from(rawComparison))
          : null,
    );
  }
}

class PhysiqueRatiosModel {
  final double? vTaperRatio;
  final double waistToHipRatio;
  final double waistToHeightRatio;
  final double chestToWaistRatio;
  final double gluteToWaistRatio;
  final double armSymmetryDeltaCm;
  final double thighSymmetryDeltaCm;
  final int overallSymmetryScore;

  const PhysiqueRatiosModel({
    this.vTaperRatio,
    this.waistToHipRatio = 0.0,
    this.waistToHeightRatio = 0.0,
    this.chestToWaistRatio = 0.0,
    this.gluteToWaistRatio = 0.0,
    this.armSymmetryDeltaCm = 0.0,
    this.thighSymmetryDeltaCm = 0.0,
    this.overallSymmetryScore = 90,
  });

  factory PhysiqueRatiosModel.fromJson(Map<String, dynamic> json) {
    double numVal(String k) => (json[k] as num?)?.toDouble() ?? 0.0;
    return PhysiqueRatiosModel(
      vTaperRatio: (json['vTaperRatio'] as num?)?.toDouble(),
      waistToHipRatio: numVal('waistToHipRatio'),
      waistToHeightRatio: numVal('waistToHeightRatio'),
      chestToWaistRatio: numVal('chestToWaistRatio'),
      gluteToWaistRatio: numVal('gluteToWaistRatio'),
      armSymmetryDeltaCm: numVal('armSymmetryDeltaCm'),
      thighSymmetryDeltaCm: numVal('thighSymmetryDeltaCm'),
      overallSymmetryScore:
          (json['overallSymmetryScore'] as num?)?.toInt() ?? 90,
    );
  }
}

class PhysiqueEvaluationsModel {
  final String coreHealthStatus;
  final String upperBodyStructure;
  final String lowerBodyStructure;
  final String symmetryStatus;
  final String recommendedPhase;

  const PhysiqueEvaluationsModel({
    this.coreHealthStatus = 'healthy',
    this.upperBodyStructure = 'proportional',
    this.lowerBodyStructure = 'proportional',
    this.symmetryStatus = 'symmetric',
    this.recommendedPhase = 'recomposition',
  });

  factory PhysiqueEvaluationsModel.fromJson(Map<String, dynamic> json) {
    return PhysiqueEvaluationsModel(
      coreHealthStatus: json['coreHealthStatus'] as String? ?? 'healthy',
      upperBodyStructure:
          json['upperBodyStructure'] as String? ?? 'proportional',
      lowerBodyStructure:
          json['lowerBodyStructure'] as String? ?? 'proportional',
      symmetryStatus: json['symmetryStatus'] as String? ?? 'symmetric',
      recommendedPhase: json['recommendedPhase'] as String? ?? 'recomposition',
    );
  }
}

class IdealBenchmarksModel {
  final double idealChestCm;
  final double idealWaistCm;
  final double idealBicepCm;
  final double idealThighCm;
  final double idealHipCm;
  final double idealShoulderWidthCm;
  final double idealLatWidthCm;

  const IdealBenchmarksModel({
    this.idealChestCm = 0.0,
    this.idealWaistCm = 0.0,
    this.idealBicepCm = 0.0,
    this.idealThighCm = 0.0,
    this.idealHipCm = 0.0,
    this.idealShoulderWidthCm = 0.0,
    this.idealLatWidthCm = 0.0,
  });

  factory IdealBenchmarksModel.fromJson(Map<String, dynamic> json) {
    double numVal(String k) => (json[k] as num?)?.toDouble() ?? 0.0;
    return IdealBenchmarksModel(
      idealChestCm: numVal('idealChestCm'),
      idealWaistCm: numVal('idealWaistCm'),
      idealBicepCm: numVal('idealBicepCm'),
      idealThighCm: numVal('idealThighCm'),
      idealHipCm: numVal('idealHipCm'),
      idealShoulderWidthCm: numVal('idealShoulderWidthCm'),
      idealLatWidthCm: numVal('idealLatWidthCm'),
    );
  }
}

class MuscleHeatmapItemModel {
  final String muscleId;
  final String name;
  final String view;
  final String status;
  final String lifterLevel;
  final String hexColor;
  final double? currentCm;
  final double? benchmarkCm;
  final double? deltaFromBenchmarkCm;
  final String feedback;
  final String confidence;
  final bool isEstimated;
  final String measurementType;

  const MuscleHeatmapItemModel({
    required this.muscleId,
    required this.name,
    required this.view,
    required this.status,
    required this.lifterLevel,
    required this.hexColor,
    this.currentCm,
    this.benchmarkCm,
    this.deltaFromBenchmarkCm,
    required this.feedback,
    this.confidence = 'high',
    this.isEstimated = false,
    this.measurementType = 'circumference',
  });

  Color get color => parseAnthropometricHex(hexColor);

  String get statusDisplayLabel {
    switch (status.toLowerCase()) {
      case 'optimal':
        return 'OPTIMAL';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'needs_training':
        return 'NEEDS TRAINING';
      case 'strong':
        return 'STRONG';
      case 'asymmetric':
        return 'ASYMMETRIC';
      case 'not_measured':
        return 'SECONDARY';
      default:
        return status.toUpperCase();
    }
  }

  factory MuscleHeatmapItemModel.fromJson(Map<String, dynamic> json) {
    return MuscleHeatmapItemModel(
      muscleId: json['muscleId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      view: json['view'] as String? ?? 'front',
      status: json['status'] as String? ?? 'in_progress',
      lifterLevel: json['lifterLevel'] as String? ?? 'beginner',
      hexColor: json['hexColor'] as String? ?? '#FFD600',
      currentCm: (json['currentCm'] as num?)?.toDouble(),
      benchmarkCm: (json['benchmarkCm'] as num?)?.toDouble(),
      deltaFromBenchmarkCm: (json['deltaFromBenchmarkCm'] as num?)?.toDouble(),
      feedback: json['feedback'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'high',
      isEstimated: json['isEstimated'] as bool? ?? false,
      measurementType: json['measurementType'] as String? ?? 'circumference',
    );
  }
}

class PhysiqueSummaryModel {
  final String coachFeedback;
  final String upperBodyStructure;
  final String lowerBodyStructure;
  final String coreHealthStatus;
  final String recommendedPhase;

  const PhysiqueSummaryModel({
    this.coachFeedback = '',
    this.upperBodyStructure = '',
    this.lowerBodyStructure = '',
    this.coreHealthStatus = 'healthy',
    this.recommendedPhase = 'recomposition',
  });

  factory PhysiqueSummaryModel.fromJson(Map<String, dynamic> json) {
    return PhysiqueSummaryModel(
      coachFeedback: json['coachFeedback'] as String? ?? '',
      upperBodyStructure: json['upperBodyStructure'] as String? ?? '',
      lowerBodyStructure: json['lowerBodyStructure'] as String? ?? '',
      coreHealthStatus: json['coreHealthStatus'] as String? ?? 'healthy',
      recommendedPhase: json['recommendedPhase'] as String? ?? 'recomposition',
    );
  }
}

class NextTargetsModel {
  final double targetWaistCm;
  final double targetChestCm;
  final double targetBicepCm;
  final int timelineWeeks;
  final List<String> focusAreas;

  const NextTargetsModel({
    required this.targetWaistCm,
    required this.targetChestCm,
    required this.targetBicepCm,
    required this.timelineWeeks,
    this.focusAreas = const [],
  });

  factory NextTargetsModel.fromJson(Map<String, dynamic> json) {
    final rawFocus = json['focusAreas'];
    final List<String> focus = [];
    if (rawFocus is List) {
      for (final f in rawFocus) {
        if (f != null) focus.add(f.toString());
      }
    }
    return NextTargetsModel(
      targetWaistCm: (json['targetWaistCm'] as num?)?.toDouble() ?? 0.0,
      targetChestCm: (json['targetChestCm'] as num?)?.toDouble() ?? 0.0,
      targetBicepCm: (json['targetBicepCm'] as num?)?.toDouble() ?? 0.0,
      timelineWeeks: (json['timelineWeeks'] as num?)?.toInt() ?? 8,
      focusAreas: focus,
    );
  }
}

class AnthropometricComparisonModel {
  final int daysBetween;
  final int? progressScore;
  final String measurementProtocol;
  final String summaryText;
  final Map<String, double> deltas;
  final Map<String, MuscleDeltaItemModel> muscleDeltas;

  const AnthropometricComparisonModel({
    required this.daysBetween,
    required this.progressScore,
    required this.measurementProtocol,
    required this.summaryText,
    required this.deltas,
    required this.muscleDeltas,
  });

  bool get isRelaxedConfirmed => measurementProtocol == 'relaxed_confirmed';
  bool get hasUnverifiedArm =>
      measurementProtocol == 'unverified_technique' ||
      muscleDeltas.values.any((m) => m.tag == 'UNVERIFIED_MEASUREMENT');

  factory AnthropometricComparisonModel.fromJson(Map<String, dynamic> json) {
    final rawDeltas = json['deltas'];
    final Map<String, double> dMap = {};
    if (rawDeltas is Map) {
      rawDeltas.forEach((k, v) {
        if (v is num) dMap[k.toString()] = v.toDouble();
      });
    }

    final rawMuscles = json['muscleDeltas'];
    final Map<String, MuscleDeltaItemModel> mDeltas = {};
    if (rawMuscles is Map) {
      rawMuscles.forEach((k, v) {
        if (v is Map) {
          mDeltas[k.toString()] = MuscleDeltaItemModel.fromJson(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }

    return AnthropometricComparisonModel(
      daysBetween: (json['daysBetween'] as num?)?.toInt() ?? 0,
      progressScore: (json['progressScore'] as num?)?.toInt(),
      measurementProtocol:
          json['measurementProtocol'] as String? ?? 'unverified_technique',
      summaryText: json['summaryText'] as String? ?? '',
      deltas: dMap,
      muscleDeltas: mDeltas,
    );
  }
}

class MuscleDeltaItemModel {
  final String name;
  final double changeCm;
  final String tag;
  final String hexColor;
  final String feedback;
  final int? gapClosedPercent;
  final String? userConfirmationPrompt;

  const MuscleDeltaItemModel({
    required this.name,
    required this.changeCm,
    required this.tag,
    required this.hexColor,
    required this.feedback,
    this.gapClosedPercent,
    this.userConfirmationPrompt,
  });

  Color get color => parseAnthropometricHex(hexColor);

  factory MuscleDeltaItemModel.fromJson(Map<String, dynamic> json) {
    return MuscleDeltaItemModel(
      name: json['name'] as String? ?? '',
      changeCm: (json['changeCm'] as num?)?.toDouble() ?? 0.0,
      tag: json['tag'] as String? ?? 'MAINTAINED',
      hexColor: json['hexColor'] as String? ?? '#8E9AA8',
      feedback: json['feedback'] as String? ?? '',
      gapClosedPercent: (json['gapClosedPercent'] as num?)?.toInt(),
      userConfirmationPrompt: json['userConfirmationPrompt'] as String?,
    );
  }
}
