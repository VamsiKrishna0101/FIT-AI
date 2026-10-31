import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../profile/repositories/settings_repository.dart';
import '../models/body_assessment_models.dart';
import '../models/body_measurement_baseline.dart';
import '../models/body_progress_summary.dart';
import '../repositories/body_assessment_repository.dart';

class BodyEntryView extends StatefulWidget {
  final BodyAssessment? existing;
  final BodyAssessmentRepository? repository;
  final Future<void> Function(Map<String, dynamic>)? onSubmit;
  final double? profileWeight;
  final bool weightOnly, requireBaseline;
  final BodyMeasurementBaseline? baseline;
  const BodyEntryView(
      {super.key,
      this.existing,
      this.repository,
      this.onSubmit,
      this.profileWeight,
      this.weightOnly = false,
      this.requireBaseline = false,
      this.baseline});

  @override
  State<BodyEntryView> createState() => _BodyEntryViewState();
}

class _BodyEntryViewState extends State<BodyEntryView> {
  final _controllers = <String, TextEditingController>{};
  final _sources = <String, String>{};
  final _fieldKeys = <String, GlobalKey>{};
  final _height = TextEditingController();
  final _fieldErrors = <String, String>{};
  late DateTime _date;
  String? _error, _owner;
  bool _saving = false;
  bool _heightEdited = false;
  bool get _saveHeight =>
      _needsHeight || (_heightEdited && _height.text.trim().isNotEmpty);
  bool get _needsHeight =>
      widget.requireBaseline && widget.baseline?.height == null;
  BodyAssessmentRepository get _repository =>
      widget.repository ?? BodyAssessmentRepository.shared;

  @override
  void initState() {
    super.initState();
    _height.text = widget.baseline?.height?.toStringAsFixed(0) ?? '';
    _date =
        DateTime.parse(widget.existing?.recordedDate ?? CacheScope.todayKey());
    for (final key in bodyMetricSpecs.keys) {
      final metric = widget.existing?.metrics[key];
      _sources[key] = metric != null && !metric.isPhotoEstimate
          ? metric.source
          : key == 'weightKg'
              ? 'scale'
              : key == 'bodyFatPct'
                  ? 'manual_estimate'
                  : 'tape';
      _controllers[key] = TextEditingController(
          text: metric == null || metric.isPhotoEstimate
              ? ''
              : metric.value.toString());
      _fieldKeys[key] = GlobalKey();
    }
    unawaited(CacheScope.userId().then((user) {
      if (mounted) _owner = user;
    }));
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _height.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (widget.onSubmit == null &&
        (_owner == null || await CacheScope.userId() != _owner)) {
      if (mounted) {
        setState(() => _error = 'Your session changed. Reopen this entry.');
      }
      return;
    }
    if (!mounted) return;
    final metrics = <String, dynamic>{};
    _fieldErrors.clear();
    for (final entry in bodyMetricSpecs.entries) {
      final key = entry.key, text = _controllers[key]!.text.trim();
      if (widget.weightOnly && key != 'weightKg') continue;
      final required = widget.requireBaseline &&
          ['weightKg', 'waistCm'].contains(key) &&
          widget.baseline?.latest(key) == null;
      if (text.isEmpty) {
        if (required) {
          _fieldErrors[key] = fitnessText(context, 'Required for your plan');
        }
        continue;
      }
      final value = double.tryParse(text.replaceAll(',', '.'));
      if (value == null ||
          !value.isFinite ||
          value < entry.value.min ||
          value > entry.value.max) {
        _fieldErrors[key] =
            '${entry.value.min.toInt()}–${entry.value.max.toInt()} ${entry.value.unit}';
      } else {
        metrics[key] = {'value': value, 'source': _sources[key]};
      }
    }
    final height = double.tryParse(_height.text.replaceAll(',', '.'));
    if (_saveHeight &&
        (height == null || !height.isFinite || height < 100 || height > 250)) {
      _fieldErrors['height'] = '100–250 cm';
    }
    if (_fieldErrors.isNotEmpty) {
      setState(() => _error = null);
      final target = _fieldKeys[_fieldErrors.keys.first]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target, alignment: .2);
      }
      return;
    }
    if (metrics.isEmpty && !_saveHeight) {
      setState(() => _error = 'Add a reading to save your measurements.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_saveHeight) {
        final settings = SettingsRepository();
        await settings.profile();
        await settings.saveProfile({'height': height});
        await _repository.invalidate();
      }
      if (metrics.isNotEmpty) {
        final payload = <String, dynamic>{
          'recordedDate': CacheScope.todayKey(_date),
          'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
          'metrics': metrics,
          if (widget.existing == null) 'requestCoaching': false,
        };
        if (widget.onSubmit != null) {
          await widget.onSubmit!(payload);
        } else {
          await _repository.save(payload, existing: widget.existing);
        }
      }
      if (widget.onSubmit == null && await CacheScope.userId() != _owner) {
        if (mounted) {
          setState(() => _error =
              'Your session changed. Reopen Body to see your entries.');
        }
        return;
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _datePicker() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2000),
        lastDate: DateTime.now());
    if (date != null && mounted) setState(() => _date = date);
  }

  Widget _field(String key) {
    final spec = bodyMetricSpecs[key]!;
    final last = widget.baseline == null
        ? null
        : BodyProgressSummary(widget.baseline!.overview)
            .measuredTrend(key)
            .lastOrNull;
    return _inputRow(
        label: spec.label,
        unit: spec.unit,
        controller: _controllers[key]!,
        fieldKey: ValueKey('body-input-$key'),
        wrapperKey: _fieldKeys[key],
        error: _fieldErrors[key],
        previous: last == null
            ? null
            : '${last.metric.display(spec.unit)} · ${DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(DateTime.parse(last.date))}',
        onChanged: (_) => setState(() {
              _fieldErrors.remove(key);
              if (key == 'weightKg') _sources[key] = 'scale';
            }));
  }

  Widget _inputRow(
      {required String label,
      required String unit,
      required TextEditingController controller,
      required Key fieldKey,
      Key? wrapperKey,
      String? previous,
      String? error,
      required ValueChanged<String> onChanged}) {
    final title =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FitnessText(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      if (previous != null)
        Padding(
            padding: const EdgeInsets.only(top: 5),
            child: FitnessText('Last · {reading}',
                values: {'reading': previous},
                style: const TextStyle(
                    fontSize: 10, color: FitnessTheme.muted, height: 1.4))),
    ]);
    final input = Semantics(
        label: fitnessText(context, label),
        child: Row(children: [
          Expanded(
              child: TextField(
            key: fieldKey,
            controller: controller,
            enabled: !_saving,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))
            ],
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: '—',
                errorText: error,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10)),
          )),
          const SizedBox(width: 8),
          Text(unit,
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted))
        ]));
    return Container(
        key: wrapperKey,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Color(0x16FFFFFF), width: .5))),
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(13) > 20) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, input]);
          }
          return Row(children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            SizedBox(width: error == null ? 112 : 140, child: input)
          ]);
        }));
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: PopScope(
        canPop: !_saving,
        child: Scaffold(
          appBar: AppBar(
              title: FitnessText(
                  widget.existing != null
                      ? 'Edit measurements'
                      : widget.weightOnly
                          ? 'Log weight'
                          : 'Update measurements',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600))),
          body: SafeArea(
              top: false,
              child: Column(children: [
                Expanded(
                    child: ListView(
                  key: const ValueKey('body-entry-scroll'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (widget.requireBaseline) ...[
                      const FitnessText('Complete your baseline',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      const FitnessText(
                          'Add the missing measurements to create your plan.',
                          style: TextStyle(
                              fontSize: 12, color: FitnessTheme.muted)),
                      const SizedBox(height: 12),
                    ],
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(CupertinoIcons.calendar,
                            size: 19, color: FitnessTheme.silver),
                        title: Text(
                            DateFormat.yMMMd(Localizations.localeOf(context)
                                    .toLanguageTag())
                                .format(_date),
                            style: const TextStyle(fontSize: 13)),
                        trailing: const Icon(CupertinoIcons.chevron_down,
                            size: 12, color: FitnessTheme.muted),
                        onTap: _saving || widget.existing != null
                            ? null
                            : _datePicker),
                    if (!widget.weightOnly && widget.existing == null)
                      _inputRow(
                          label: 'Height',
                          unit: 'cm',
                          controller: _height,
                          fieldKey: const ValueKey('body-input-height'),
                          error: _fieldErrors['height'],
                          onChanged: (_) => setState(() {
                                _heightEdited = true;
                                _fieldErrors.remove('height');
                              })),
                    for (final key in [
                      'weightKg',
                      'waistCm',
                      ...bodyMetricSpecs.keys.where(
                          (key) => !['weightKg', 'waistCm'].contains(key))
                    ])
                      if (!widget.weightOnly || key == 'weightKg') _field(key),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                              liveRegion: true,
                              child: FitnessText(_error!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: FitnessTheme.coral)))),
                  ],
                )),
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: LiquidChromeButton(
                        title: widget.weightOnly
                            ? 'Save weight'
                            : 'Save measurements',
                        solid: true,
                        showArrow: false,
                        isLoading: _saving,
                        onPressed: _saving ? null : _save)),
              ])),
        ),
      ));
}
