import 'package:intl/date_symbol_data_local.dart';
// Run on a connected device in profile mode, then restore lib/main.dart.
// No API calls, database writes, credential reads or app-data resets.
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:setcraft/core/components/liquid_silver_bottom_bar.dart';
import 'package:setcraft/core/theme/fitness_theme.dart';
import 'package:setcraft/features/today/components/today_dashboard.dart';
import 'package:setcraft/features/body_scan/views/body_training_view.dart';
import 'scroll_benchmark_legacy_dock.dart';
import 'scroll_benchmark_fixtures.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, home: _ScrollBenchmark()));
}

class _ScrollBenchmark extends StatefulWidget {
  const _ScrollBenchmark();
  @override
  State<_ScrollBenchmark> createState() => _ScrollBenchmarkState();
}

class _ScrollBenchmarkState extends State<_ScrollBenchmark> {
  int _mode = 0;
  bool _recording = false, _done = false;
  final _frames = <FrameTiming>[];
  final _results = <Map<String, Object>>[];
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_collect);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  void _collect(List<FrameTiming> timings) {
    if (_recording) _frames.addAll(timings);
  }

  ScrollPosition? _position() {
    ScrollPosition? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        final s = element.state as ScrollableState;
        if (s.position.hasContentDimensions &&
            s.position.maxScrollExtent > 100 &&
            axisDirectionToAxis(s.axisDirection) == Axis.vertical) {
          found = s.position;
          return;
        }
      }
      element.visitChildElements(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildElements(visit);
    return found;
  }

  Future<void> _scroll(ScrollPosition p) async {
    await p.animateTo(p.maxScrollExtent,
        duration: const Duration(milliseconds: 900), curve: Curves.linear);
    await p.animateTo(0,
        duration: const Duration(milliseconds: 900), curve: Curves.linear);
  }

  Future<void> _run() async {
    for (var mode = 0; mode < 4; mode++) {
      if (!mounted) return;
      setState(() => _mode = mode);
      await Future<void>.delayed(const Duration(seconds: 2));
      final p = _position();
      if (p == null) throw StateError('No benchmark scroll view');
      await _scroll(p); // Warm text, anatomy paths and image/raster caches.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _frames.clear();
      _recording = true;
      for (var i = 0; i < 3; i++) {
        await _scroll(p);
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _recording = false;
      final raster = _frames
          .map((f) => f.rasterDuration.inMicroseconds / 1000)
          .toList()
        ..sort();
      final ui = _frames
          .map((f) => f.buildDuration.inMicroseconds / 1000)
          .toList()
        ..sort();
      double pct(List<double> values, double fraction) => values[
          (values.length * fraction).floor().clamp(0, values.length - 1)];
      final result = <String, Object>{
        'case':
            '${mode < 2 ? 'Today' : 'Body'} ${mode.isEven ? 'previous blur' : 'consistent grouped glass'}',
        'frames': raster.length,
        'uiP90Ms': pct(ui, .9),
        'rasterP50Ms': pct(raster, .5),
        'rasterP90Ms': pct(raster, .9),
        'rasterP99Ms': pct(raster, .99),
        'rasterOver16_7Pct':
            raster.where((x) => x > 16.67).length * 100 / raster.length,
        'rasterOver8_3Pct':
            raster.where((x) => x > 8.33).length * 100 / raster.length
      };
      _results.add(result);
      // Machine-readable timing output only; fixture data never printed.
      debugPrint('FITAI_SCROLL_PROFILE ${jsonEncode(result)}');
    }
    if (mounted) setState(() => _done = true);
    debugPrint('FITAI_SCROLL_PROFILE_COMPLETE');
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_collect);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        backgroundColor: FitnessTheme.canvas,
        extendBody: true,
        body: MediaQuery(
            data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.paddingOf(context).copyWith(bottom: 0)),
            child: SafeArea(
                bottom: false,
                child: _done
                    ? Center(
                        child: Text(
                            'Scroll check complete\n${_results.length} cases measured\nNo data saved',
                            textAlign: TextAlign.center))
                    : _mode < 2
                        ? TodayDashboard(
                            key: ValueKey('today-$_mode'),
                            data: benchmarkHome,
                            now: DateTime(2026, 10, 6),
                            onRefresh: () async {},
                            onProfile: () {},
                            onSession: () {},
                            onTrain: () {},
                            onNutrition: () {})
                        : TrainingMapDashboard(
                            key: ValueKey('body-$_mode'),
                            data: benchmarkTraining,
                            onRefresh: () async {},
                            onCheckIn: (_, __) async {},
                            onPreferences: () {},
                            onProfile: () {},
                            onTrain: () {}))),
        bottomNavigationBar: _mode.isEven
            ? LegacySilverBottomBar(
                selectedIndex: _mode < 2 ? 0 : 2,
                labels: const ['Today', 'Train', 'Body', 'Progress'],
                onTabSelected: (_) {},
                onCreate: () {})
            : LiquidSilverBottomBar(
                selectedIndex: _mode < 2 ? 0 : 2,
                labels: const ['Today', 'Train', 'Body', 'Progress'],
                onTabSelected: (_) {}),
      ));
}
