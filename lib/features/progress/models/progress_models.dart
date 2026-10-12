import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import '../../../core/localization/fitness_copy.dart';

typedef ProgressJson = Map<String, dynamic>;

List<ProgressJson> progressRows(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
    : const [];

double? progressNumber(dynamic value) => value is num ? value.toDouble() : null;

String progressMuscleLabel(BuildContext context, ProgressJson muscle) {
  const labels = {
    'chest': 'Chest',
    'shoulders': 'Shoulders',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'forearms': 'Forearms',
    'upper_back': 'Upper back',
    'lats': 'Lats',
    'lower_back': 'Lower back',
    'core': 'Core',
    'glutes': 'Hips & glutes',
    'quads': 'Quads',
    'hamstrings': 'Hamstrings',
    'calves': 'Calves',
  };
  return fitnessText(
      context, labels[muscle['id']] ?? muscle['label'] as String? ?? '');
}

String progressValue(BuildContext context, num? value,
    {String unit = '', int digits = 1}) {
  if (value == null) return '—';
  final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag())
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = digits;
  final number = format.format(value);
  return unit.isEmpty ? number : '$number ${fitnessText(context, unit)}';
}

String progressDate(String? value, String locale, {bool year = false}) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) return '—';
  return (year ? DateFormat.yMMMd(locale) : DateFormat.MMMd(locale))
      .format(date);
}

class ProgressPoint {
  final DateTime date;
  final double value;
  const ProgressPoint(this.date, this.value);

  static List<ProgressPoint> parse(List<ProgressJson> rows, String key) {
    final points = <ProgressPoint>[];
    for (final row in rows) {
      final date = DateTime.tryParse(row['date']?.toString() ?? '');
      final value = progressNumber(row[key]);
      if (date != null &&
          date.toIso8601String().substring(0, 10) == row['date'] &&
          value != null &&
          value.isFinite) {
        points.add(ProgressPoint(date, value));
      }
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }
}

class ProgressOverview {
  final ProgressJson json;
  const ProgressOverview(this.json);
  ProgressJson get summary =>
      Map<String, dynamic>.from(json['summary'] as Map? ?? {});
  List<ProgressJson> get weeks => progressRows(json['weeks']);
  List<ProgressJson> get activity => progressRows(json['activity']);
  List<ProgressJson> get exercises => progressRows(json['exercises']);
  List<ProgressJson> get muscles => progressRows(json['muscles']);
  List<ProgressJson> get sessions => progressRows(json['recentSessions']);
  ProgressJson get body =>
      Map<String, dynamic>.from(json['body'] as Map? ?? {});
  ProgressJson get wellness =>
      Map<String, dynamic>.from(json['wellness'] as Map? ?? {});
}
