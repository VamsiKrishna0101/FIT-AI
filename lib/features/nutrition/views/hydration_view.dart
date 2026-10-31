import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/liquid_water_visual.dart';
import '../components/water_intake_card.dart';
import '../models/nutrition_diet_models.dart';
import '../repositories/nutrition_repository.dart';

class HydrationView extends StatefulWidget {
  final DateTime? date;
  final int? initialConsumedMl, initialTargetMl;
  final Future<TodayDietPlanModel?> Function()? loader;
  final Future<bool> Function(int ml)? logWater;
  final DateTime Function()? clock;
  const HydrationView(
      {super.key,
      this.date,
      this.initialConsumedMl,
      this.initialTargetMl,
      this.loader,
      this.logWater,
      this.clock});
  @override
  State<HydrationView> createState() => _HydrationViewState();
}

class _HydrationViewState extends State<HydrationView> {
  late final DateTime _date;
  int? _consumed, _target;
  int _request = 0, _confirmedFloor = 0;
  bool _loading = true, _failed = false, _saving = false;
  StreamSubscription<TodayDietPlanModel?>? _updates;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  bool get _readOnly => !DateUtils.isSameDay(_date, _now);
  @override
  void initState() {
    super.initState();
    _date = widget.date ?? _now;
    _consumed = widget.initialConsumedMl;
    _target = widget.initialTargetMl;
    if (widget.loader == null) {
      _updates = NutritionRepository.shared.dietPlanStream.listen((plan) {
        if (mounted && !_readOnly && !_saving && plan != null) {
          setState(() => _accept(plan));
        }
      });
      AppDataMode.shared.addListener(_modeChanged);
    }
    _load();
  }

  void _accept(TodayDietPlanModel plan) {
    _consumed = math.max(plan.waterConsumed, _confirmedFloor);
    _target = plan.waterTarget;
    _failed = false;
    _loading = false;
  }

  void _modeChanged() {
    _request++;
    setState(() {
      _consumed = null;
      _target = null;
      _confirmedFloor = 0;
    });
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = _consumed == null;
      _failed = false;
    });
    try {
      final plan = await (widget.loader?.call() ??
          NutritionRepository.shared.loadDate(_date, forceRefresh: true));
      if (!mounted || request != _request) return;
      setState(() {
        if (plan != null) {
          _accept(plan);
        } else {
          _failed = true;
        }
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _add(int ml) async {
    if (_saving || _readOnly) return;
    final revision = AppDataMode.shared.revision;
    final baseline = _consumed ?? 0;
    setState(() => _saving = true);
    var saved = false;
    try {
      saved = await (widget.logWater?.call(ml) ??
          NutritionRepository.shared.logWater(ml));
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    if (revision != AppDataMode.shared.revision) {
      setState(() => _saving = false);
      return;
    }
    if (saved) {
      // This increment follows the server acknowledgement, so a refresh failure
      // does not make a committed entry look unsaved or invite a duplicate.
      setState(() {
        _confirmedFloor = baseline + ml;
        _consumed = _confirmedFloor;
      });
      _message('Water saved');
      await _load();
    } else {
      _message('Could not save. Try again.');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _message(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: FitnessText(text)));
  @override
  void dispose() {
    _updates?.cancel();
    AppDataMode.shared.removeListener(_modeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          appBar: AppBar(
              backgroundColor: DSColors.bg,
              surfaceTintColor: Colors.transparent,
              title: const FitnessText('Water',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
          body: RefreshIndicator(
              color: DSColors.silver,
              onRefresh: _load,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    Text(
                        DateFormat.MMMMEEEEd(
                                Localizations.localeOf(context).toLanguageTag())
                            .format(_date),
                        style: const TextStyle(
                            color: DSColors.muted, fontSize: 12)),
                    const SizedBox(height: 20),
                    if (_loading)
                      const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(child: CupertinoActivityIndicator()))
                    else
                      Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: DSColors.bgCard,
                              border:
                                  Border.all(color: DSColors.border, width: .7),
                              borderRadius: BorderRadius.circular(18)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LayoutBuilder(
                                    builder: (_, bounds) => ExcludeSemantics(
                                        child: LiquidWaterVisual(
                                            fraction: (_target ?? 0) > 0
                                                ? (_consumed ?? 0) / _target!
                                                : 0,
                                            size: Size(bounds.maxWidth, 136)))),
                                const SizedBox(height: 20),
                                Text(
                                    _consumed == null
                                        ? '—'
                                        : waterLitres(context, _consumed!),
                                    key: const ValueKey('hydration-total'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -1)),
                                if ((_target ?? 0) > 0)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                          '/ ${waterLitres(context, _target!)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: DSColors.muted,
                                              fontSize: 13))),
                                const SizedBox(height: 20),
                                if (_readOnly)
                                  const FitnessText('Read-only',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: DSColors.muted, fontSize: 12))
                                else
                                  LayoutBuilder(builder: (context, bounds) {
                                    Widget button(int ml) => OutlinedButton(
                                        key: ValueKey('add-water-$ml'),
                                        onPressed: _saving || _consumed == null
                                            ? null
                                            : () => _add(ml),
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor: DSColors.silver,
                                            minimumSize:
                                                const Size(double.infinity, 50),
                                            backgroundColor:
                                                const Color(0xFF292929),
                                            side: const BorderSide(
                                                color: DSColors.border),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                        child: Text('+ $ml ml',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)));
                                    return MediaQuery.textScalerOf(context)
                                                .scale(14) >
                                            22
                                        ? Column(children: [
                                            button(250),
                                            const SizedBox(height: 8),
                                            button(500)
                                          ])
                                        : Row(children: [
                                            Expanded(child: button(250)),
                                            const SizedBox(width: 10),
                                            Expanded(child: button(500))
                                          ]);
                                  }),
                                if (_saving)
                                  const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Center(
                                          child: CupertinoActivityIndicator())),
                              ])),
                    if (_failed)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(children: [
                            Expanded(
                                child: FitnessText(
                                    _consumed == null
                                        ? 'Could not load water.'
                                        : 'Showing last saved intake.',
                                    style: const TextStyle(
                                        color: DSColors.muted, fontSize: 12))),
                            TextButton(
                                onPressed: _saving ? null : _load,
                                child: const FitnessText('Retry'))
                          ])),
                  ]))));
}
