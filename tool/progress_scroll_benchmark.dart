// Run with flutter run --profile -t tool/progress_scroll_benchmark.dart.
// Synthetic data only; leaves the member's stored data and credentials intact.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:setcraft/core/components/liquid_silver_bottom_bar.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';
import 'package:setcraft/features/progress/views/progress_overview_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Benchmark()));
}

ProgressOverview _data(int days) {
  final end = DateTime(2026, 10, 30);
  String date(int index) => end
      .subtract(Duration(days: days - index - 1))
      .toIso8601String()
      .substring(0, 10);
  return ProgressOverview({
    'range': {'start': date(0), 'end': date(days - 1)},
    'summary': {
      'workouts': days ~/ 2,
      'sets': days * 8,
      'trainingDays': days ~/ 2
    },
    'activity': [
      for (var i = 0; i < days; i += 2)
        {'date': date(i), 'sets': 16, 'completed': true}
    ],
    'muscles': [
      for (final entry in [
        'chest',
        'shoulders',
        'biceps',
        'triceps',
        'forearms',
        'upper_back',
        'lats',
        'lower_back',
        'core',
        'glutes',
        'quads',
        'hamstrings',
        'calves'
      ].indexed)
        {'id': entry.$2, 'label': entry.$2, 'directSets': 26 - entry.$1 * 2}
    ],
    'exercises': [
      for (final entry in [
        'Bench press',
        'Seated cable row',
        'Squat',
        'Romanian deadlift',
        'Shoulder press',
        'Biceps curl'
      ].indexed)
        {
          'id': 'exercise-${entry.$1}',
          'name': entry.$2,
          'metric': 'load',
          'latest': {'date': date(days - 1), 'weight': 60, 'reps': 8},
          'loggedSets': days,
          'totalReps': days * 8,
          'volume': days * 480,
          'sparkline': [
            for (var i = 0; i < days; i += 2)
              {'date': date(i), 'value': 40 + i * .5 + entry.$1}
          ]
        }
    ],
    'body': {
      'metrics': [
        {
          'id': 'weightKg',
          'label': 'Weight',
          'unit': 'kg',
          'series': [
            {
              'source': 'scale',
              'points': [
                for (var i = 0; i < days; i++)
                  {'date': date(i), 'value': 78 - i * .05}
              ]
            }
          ]
        }
      ]
    },
    'wellness': {
      'nutrition': [
        for (var i = 0; i < days; i++)
          {
            'date': date(i),
            'calories': 2100 + i * 15,
            'protein': 130 + i,
            'carbs': 220 + i,
            'fat': 65 + i * .5,
            'mealLogs': 3
          }
      ],
      'sleep': [
        for (var i = 0; i < days; i++)
          {'date': date(i), 'sleep': 7 + i % 3 * .3}
      ]
    },
    'planHistory': []
  });
}

class _Benchmark extends StatefulWidget {
  const _Benchmark();
  @override
  State<_Benchmark> createState() => _BenchmarkState();
}

class _BenchmarkState extends State<_Benchmark> {
  static const _phase =
      String.fromEnvironment('PROGRESS_PERF_PHASE', defaultValue: 'before');
  static const _cases = [(7, true), (28, true), (28, false)];
  int _case = 0;
  bool _recording = false, _done = false;
  final _frames = <FrameTiming>[];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_collect);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  void _collect(List<FrameTiming> frames) {
    if (_recording) _frames.addAll(frames);
  }

  ScrollPosition _position() {
    ScrollPosition? result;
    void visit(Element element) {
      if (result != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        final scroll = element.state as ScrollableState;
        if (axisDirectionToAxis(scroll.axisDirection) == Axis.vertical &&
            scroll.position.hasContentDimensions &&
            scroll.position.maxScrollExtent > 100) {
          result = scroll.position;
          return;
        }
      }
      element.visitChildElements(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildElements(visit);
    return result ?? (throw StateError('Progress has no scroll position'));
  }

  Future<void> _scroll(ScrollPosition position) async {
    // Multiple segments also visit cards that are lazily created while scrolling.
    for (var i = 0; i < 4; i++) {
      await position.animateTo(position.maxScrollExtent * (i + 1) / 4,
          duration: const Duration(milliseconds: 400), curve: Curves.linear);
    }
    await position.animateTo(0,
        duration: const Duration(milliseconds: 1600), curve: Curves.linear);
  }

  void _report(String pass) {
    if (_frames.isEmpty) throw StateError('No device frame timings collected');
    final ui = _frames
        .map((f) => f.buildDuration.inMicroseconds / 1000)
        .toList()
      ..sort();
    final raster = _frames
        .map((f) => f.rasterDuration.inMicroseconds / 1000)
        .toList()
      ..sort();
    final refresh = View.of(context).display.refreshRate;
    final budget = 1000 / refresh;
    double percentile(List<double> values, double p) =>
        values[((values.length - 1) * p).round()];
    debugPrint('FITAI_PROGRESS_PROFILE ${jsonEncode({
          'phase': _phase,
          'days': _cases[_case].$1,
          'dock': _cases[_case].$2,
          'pass': pass,
          'refreshHz': refresh,
          'frames': _frames.length,
          'uiP90Ms': percentile(ui, .9),
          'uiP99Ms': percentile(ui, .99),
          'rasterP90Ms': percentile(raster, .9),
          'rasterP99Ms': percentile(raster, .99),
          'overBudgetPct': _frames
                  .where((f) =>
                      f.buildDuration.inMicroseconds / 1000 > budget ||
                      f.rasterDuration.inMicroseconds / 1000 > budget)
                  .length *
              100 /
              _frames.length,
          'over16_7Pct': _frames
                  .where((f) =>
                      f.buildDuration.inMicroseconds > 16667 ||
                      f.rasterDuration.inMicroseconds > 16667)
                  .length *
              100 /
              _frames.length,
        })}');
  }

  Future<void> _run() async {
    for (var index = 0; index < _cases.length; index++) {
      if (!mounted) return;
      setState(() => _case = index);
      await Future<void>.delayed(const Duration(seconds: 2));
      final position = _position();
      _frames.clear();
      _recording = true;
      await _scroll(position);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _recording = false;
      _report('first');
      _frames.clear();
      _recording = true;
      for (var repeat = 0; repeat < 3; repeat++) {
        await _scroll(position);
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _recording = false;
      _report('warm');
    }
    if (mounted) setState(() => _done = true);
    debugPrint('FITAI_PROGRESS_PROFILE_COMPLETE');
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_collect);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      extendBody: true,
      body: _done
          ? const Center(child: Text('Progress scroll check complete'))
          : ProgressOverviewView(
              key: ValueKey(_case),
              initial: _data(_cases[_case].$1),
              clock: () => DateTime(2026, 10, 30)),
      bottomNavigationBar: _cases[_case].$2
          ? LiquidSilverBottomBar(
              selectedIndex: 3,
              labels: const ['Today', 'Train', 'Body', 'Progress'],
              onTabSelected: (_) {})
          : null);
}
