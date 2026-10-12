import '../../../core/navigation/onboarding_page_route.dart';
import 'package:fitai_mobile/core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'body_estimate_view.dart';

class BodyEntryView extends StatefulWidget {
  final BodyAssessment? existing;
  final Future<void> Function(Map<String, dynamic>)? onSubmit;
  final double? profileWeight;
  final bool weightOnly;
  const BodyEntryView(
      {super.key,
      this.existing,
      this.onSubmit,
      this.profileWeight,
      this.weightOnly = false});
  @override
  State<BodyEntryView> createState() => _BodyEntryViewState();
}

class _BodyEntryViewState extends State<BodyEntryView> {
  final _controllers = <String, TextEditingController>{};
  final _sources = <String, String>{};
  late DateTime _date;
  String? _error, _owner;
  bool _saving = false, _saved = false, _more = false;
  bool _coaching = true;
  @override
  void initState() {
    super.initState();
    _date = DateTime.parse(
        widget.existing?.recordedDate ?? CacheScope.todayKey(DateTime.now()));
    for (final key in bodyMetricSpecs.keys) {
      final metric = widget.existing?.metrics[key];
      _sources[key] = metric?.source ??
          (key == 'weightKg'
              ? 'scale'
              : key == 'bodyFatPct'
                  ? 'manual_estimate'
                  : 'tape');
      _controllers[key] = TextEditingController(
          text: metric == null || metric.isPhotoEstimate
              ? ''
              : metric.value.toString());
    }
    if (widget.existing == null &&
        widget.profileWeight != null &&
        !widget.weightOnly) {
      _controllers['weightKg']!.text = widget.profileWeight!.toString();
      _sources['weightKg'] = 'profile';
    }
    CacheScope.userId().then((user) {
      if (mounted) _owner = user;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (widget.onSubmit == null && await CacheScope.userId() != _owner) {
      if (mounted) {
        setState(() => _error = 'Your session changed. Reopen this entry.');
      }
      return;
    }
    final metrics = <String, dynamic>{};
    for (final entry in bodyMetricSpecs.entries) {
      final key = entry.key, text = _controllers[key]!.text.trim();
      if (widget.weightOnly && key != 'weightKg') continue;
      if (_sources[key] == 'photo_estimate' ||
          _sources[key] == 'contour_estimate') {
        metrics[key] = widget.existing!.metrics[key]!.toJson();
        continue;
      }
      if (text.isEmpty) continue;
      final value = double.tryParse(text.replaceAll(',', '.'));
      if (value == null ||
          !value.isFinite ||
          value < entry.value.min ||
          value > entry.value.max) {
        setState(() => _error =
            'Enter ${entry.value.label.toLowerCase()} between ${entry.value.min.toInt()} and ${entry.value.max.toInt()} ${entry.value.unit}.');
        return;
      }
      metrics[key] = {'value': value, 'source': _sources[key]};
    }
    if (metrics.isEmpty) {
      setState(() => _error = 'Add at least one reading to save your entry.');
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'recordedDate': CacheScope.todayKey(_date),
        'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        'metrics': metrics,
        if (widget.existing == null)
          'requestCoaching': _coaching && !widget.weightOnly
      };
      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      } else if (widget.existing == null && _coaching && !widget.weightOnly) {
        if (!mounted) return;
        final route = AppPageRoute<bool>(
            page: BodyEstimateView(
                fromPhotos: false,
                estimate: (onStage, cancelled) async {
                  if (cancelled() || await CacheScope.userId() != _owner) {
                    throw StateError(
                        'Your session changed. Reopen this entry.');
                  }
                  onStage('focus');
                  final entry =
                      await BodyAssessmentRepository.shared.save(payload);
                  if (cancelled() || await CacheScope.userId() != _owner) {
                    throw StateError(
                        'Your session changed. Reopen Body to see your entries.');
                  }
                  return entry;
                }));
        final saved = await Navigator.of(context).push(route);
        await route.completed;
        if (saved != true) return;
      } else {
        await BodyAssessmentRepository.shared
            .save(payload, existing: widget.existing);
        if (await CacheScope.userId() != _owner) {
          if (mounted) {
            setState(() => _error =
                'Your session changed. Reopen Body to see your entries.');
          }
          return;
        }
      }
      _saved = true;
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
    final spec = bodyMetricSpecs[key]!, metric = widget.existing?.metrics[key];
    if (_sources[key] == 'photo_estimate' ||
        _sources[key] == 'contour_estimate') {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: FitnessText(spec.label,
                      style: const TextStyle(fontSize: 14))),
              FitnessText(metric!.display(spec.unit),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w500))
            ]),
            const SizedBox(height: 5),
            Row(children: [
              Expanded(
                  child: FitnessText(
                      '${bodySourceLabel(_sources[key]!)} · experimental',
                      style: const TextStyle(
                          fontSize: 11, color: FitnessTheme.muted))),
              TextButton(
                  onPressed: () => setState(() => _sources[key] =
                      key == 'bodyFatPct' ? 'manual_estimate' : 'tape'),
                  child: FitnessText(
                      key == 'bodyFatPct' ? 'Enter reading' : 'Use tape',
                      style: const TextStyle(fontSize: 12)))
            ])
          ]));
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          key: ValueKey('body-input-$key'),
          controller: _controllers[key],
          onChanged: key == 'weightKg'
              ? (_) => setState(() => _sources[key] = 'scale')
              : null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))
          ],
          decoration: InputDecoration(
              labelText: fitnessText(context, spec.label),
              suffixText: spec.unit,
              helperText: fitnessText(
                  context,
                  key == 'bodyFatPct'
                      ? bodySourceLabel(_sources[key]!)
                      : key == 'weightKg'
                          ? bodySourceLabel(_sources[key]!)
                          : 'Tape measurement'),
              fillColor: const Color(0xFF2B2B2B)),
        ));
  }

  Widget _group(String title, List<String> keys) => FitnessCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final key in keys) _field(key),
      ]));
  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: PopScope(
          canPop: !_saving,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop &&
                !_saved &&
                widget.existing?.status == 'REVIEW' &&
                widget.onSubmit == null) {
              unawaited(BodyAssessmentRepository.shared
                  .delete(widget.existing!.id)
                  .catchError((_) {}));
            }
          },
          child: Scaffold(
            backgroundColor: FitnessTheme.canvas,
            appBar: AppBar(
                backgroundColor: FitnessTheme.canvas,
                surfaceTintColor: Colors.transparent,
                title: FitnessText(
                    widget.existing?.status == 'REVIEW'
                        ? 'Review your estimate'
                        : widget.existing != null
                            ? 'Edit entry'
                            : widget.weightOnly
                                ? 'Log weight'
                                : 'Enter measurements',
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
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                          children: [
                        FitnessText(
                            widget.existing?.status == 'REVIEW'
                                ? 'Keep useful estimates. Replace them with readings when you have them.'
                                : 'A few readings make your changes easier to follow. Leave anything you have not measured blank.',
                            style: const TextStyle(
                                fontSize: 14,
                                color: FitnessTheme.muted,
                                height: 1.45)),
                        const SizedBox(height: 16),
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading:
                                const Icon(CupertinoIcons.calendar, size: 20),
                            title: FitnessText(
                                DateFormat(
                                        'MMMM d, y',
                                        Localizations.localeOf(context)
                                            .toLanguageTag())
                                    .format(_date),
                                style: const TextStyle(fontSize: 14)),
                            trailing: widget.existing == null
                                ? const Icon(CupertinoIcons.chevron_down,
                                    size: 14)
                                : null,
                            onTap:
                                widget.existing == null ? _datePicker : null),
                        if (widget.existing?.status == 'REVIEW') ...[
                          FitnessCard(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const FitnessText('Visual estimates',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 7),
                                const FitnessText(
                                    'Photo ranges are unvalidated estimates, not tape or body-composition measurements.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted,
                                        height: 1.4)),
                                if (widget.existing!.summary?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 10),
                                  FitnessText(widget.existing!.summary!,
                                      style: const TextStyle(
                                          fontSize: 13, height: 1.45))
                                ],
                                for (final note
                                    in widget.existing!.qualityNotes)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 7),
                                      child: FitnessText(note,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: FitnessTheme.muted))),
                              ])),
                          const SizedBox(height: 14),
                        ],
                        if (widget.weightOnly)
                          _group('Current scale reading', ['weightKg']),
                        if (!widget.weightOnly) ...[
                          _group('Weight & composition',
                              ['weightKg', 'bodyFatPct']),
                          if (_sources['bodyFatPct'] != 'photo_estimate')
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: DropdownButtonFormField<String>(
                                    initialValue: _sources['bodyFatPct'],
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                        labelText: fitnessText(
                                            context, 'Body-fat source')),
                                    items: [
                                      for (final source in [
                                        'manual_estimate',
                                        'smart_scale',
                                        'dexa',
                                        'calipers'
                                      ])
                                        DropdownMenuItem(
                                            value: source,
                                            child: FitnessText(
                                                bodySourceLabel(source),
                                                style: const TextStyle(
                                                    fontSize: 13)))
                                    ],
                                    onChanged: (source) => setState(() =>
                                        _sources['bodyFatPct'] = source!))),
                          const SizedBox(height: 14),
                          _group('Circumferences',
                              ['chestCm', 'waistCm', 'hipsCm']),
                          const SizedBox(height: 14),
                          _group('Left & right', [
                            'leftArmCm',
                            'rightArmCm',
                            'leftThighCm',
                            'rightThighCm'
                          ]),
                          const SizedBox(height: 14),
                          FitnessCard(
                              padding: EdgeInsets.zero,
                              child: ExpansionTile(
                                  initiallyExpanded: _more,
                                  title: const FitnessText('Calves & neck',
                                      style: TextStyle(fontSize: 15)),
                                  shape: const Border(),
                                  collapsedShape: const Border(),
                                  childrenPadding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  onExpansionChanged: (v) => _more = v,
                                  children: [
                                    _field('leftCalfCm'),
                                    _field('rightCalfCm'),
                                    _field('neckCm')
                                  ])),
                          const SizedBox(height: 14),
                          const FitnessText(
                              'Use the same measuring technique and similar conditions when comparing entries.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: FitnessTheme.muted,
                                  height: 1.4)),
                          if (widget.existing == null)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _coaching,
                              onChanged: _saving
                                  ? null
                                  : (v) => setState(() => _coaching = v!),
                              title: const FitnessText(
                                  'Suggest my training focus',
                                  style: TextStyle(fontSize: 13)),
                              subtitle: const FitnessText(
                                  'Send these measurements and your training context to AI. No photos required.',
                                  style: TextStyle(
                                      fontSize: 11, color: FitnessTheme.muted)),
                            ),
                        ],
                        if (widget.weightOnly)
                          const FitnessText(
                              'Weight updates your trend. It does not estimate regional fat or change your physique map.',
                              style: TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted)),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: FitnessText(_error!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: FitnessTheme.coral))),
                      ])),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: LiquidChromeButton(
                          title: widget.existing != null
                              ? 'Save entry'
                              : widget.weightOnly
                                  ? 'Save weight'
                                  : _coaching
                                      ? 'Save & get focus'
                                      : 'Save measurements',
                          isLoading: _saving,
                          onPressed: _saving ? null : _save)),
                ])),
          )));
}
