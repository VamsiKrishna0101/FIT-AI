import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../body_scan/models/body_map_models.dart';
import 'progress_models.dart';

Map<String, dynamic> progressSelectionQuery(BodyDateSelection selection) {
  final dates = (selection.dates.isEmpty ? [selection.end] : selection.dates)
      .map(CacheScope.todayKey)
      .toSet()
      .toList()
    ..sort();
  final multiple =
      selection.mode == BodyDateMode.day || selection.mode == BodyDateMode.days;
  return {
    'dataset': 'real',
    'date': CacheScope.todayKey(selection.end),
    if (selection.mode != BodyDateMode.all) ...{
      'start': multiple
          ? dates.first
          : CacheScope.todayKey(selection.start ?? selection.end),
      'end': CacheScope.todayKey(selection.end),
      if (multiple) 'dates': dates.join(','),
    },
  };
}

List<DateTime> progressCalendarDays(ProgressOverview data) {
  final range = data.json['range'] as Map? ?? {};
  final selected =
      (range['selectedDates'] as List?)?.whereType<String>().toList();
  if (selected != null && selected.isNotEmpty) {
    return selected.map(DateTime.parse).toSet().toList()..sort();
  }
  final start = DateTime.tryParse(range['start'] as String? ?? '');
  final end = DateTime.tryParse(range['end'] as String? ?? '');
  if (start == null || end == null || end.isBefore(start)) return [];
  final count = DateTime.utc(end.year, end.month, end.day)
          .difference(DateTime.utc(start.year, start.month, start.day))
          .inDays +
      1;
  return List.generate(
      count, (i) => DateTime(start.year, start.month, start.day + i));
}

class ProgressBarDatum {
  final DateTime date;
  final double? value;
  final int readings;
  const ProgressBarDatum(this.date, this.value, {this.readings = 0});
}

List<ProgressBarDatum> progressDailyBars(
    List<DateTime> days, List<ProgressJson> rows, String metric) {
  final points = {
    for (final point in ProgressPoint.parse(rows, metric))
      CacheScope.todayKey(point.date): point.value,
  };
  if (days.length <= 14) {
    return days.map((day) {
      final value = points[CacheScope.todayKey(day)];
      return ProgressBarDatum(day, value, readings: value == null ? 0 : 1);
    }).toList();
  }
  final buckets = <DateTime, List<double>>{};
  for (final day in days) {
    final week = bodyMapWeek(day);
    final values = buckets.putIfAbsent(week, () => []);
    final value = points[CacheScope.todayKey(day)];
    if (value != null) {
      values.add(value);
    }
  }
  return buckets.entries
      .map((entry) => ProgressBarDatum(
          entry.key,
          entry.value.isEmpty
              ? null
              : entry.value.reduce((a, b) => a + b) / entry.value.length,
          readings: entry.value.length))
      .toList();
}

String progressShortValue(BuildContext context, num? value) {
  if (value == null || !value.isFinite) return '—';
  if (value.abs() < 1000) return progressValue(context, value);
  return NumberFormat.compact(
          locale: Localizations.localeOf(context).toLanguageTag())
      .format(value);
}

class ProgressMacros {
  final List<double> grams;
  final int days;
  const ProgressMacros(this.grams, this.days);
  List<double> get calories => [grams[0] * 4, grams[1] * 4, grams[2] * 9];
  double get total => calories.fold(0, (a, b) => a + b);
  List<double> get dailyGrams =>
      [for (final g in grams) days == 0 ? g : g / days];
  double get dailyTotal => days == 0 ? total : total / days;
  factory ProgressMacros.fromRows(List<ProgressJson> rows) {
    final complete = <String, List<double>>{};
    for (final row in rows) {
      final date = row['date'] as String?;
      if (ProgressPoint.parse([
        {'date': date, 'value': 0}
      ], 'value')
          .isEmpty) {
        continue;
      }
      final values = [
        for (final key in ['protein', 'carbs', 'fat']) progressNumber(row[key])
      ];
      if (values.any((v) => v == null || !v.isFinite || v < 0)) continue;
      complete[date!] = values.cast<double>();
    }
    return ProgressMacros(
        List.generate(
            3,
            (i) => complete.values
                .fold<double>(0, (sum, values) => sum + values[i])),
        complete.length);
  }
}
