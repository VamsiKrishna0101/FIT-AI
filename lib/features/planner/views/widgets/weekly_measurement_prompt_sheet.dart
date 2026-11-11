import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/cache/cache_scope.dart';
import '../../../../core/components/liquid_chrome_button.dart';
import '../../../../core/components/premium_surface.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../body_scan/models/body_assessment_models.dart';
import '../../../body_scan/models/body_measurement_baseline.dart';
import '../../../body_scan/repositories/body_assessment_repository.dart';

class WeeklyMeasurementPromptSheet extends StatefulWidget {
  final BodyOverview overview;
  final BodyMeasurementBaseline baseline;
  final Future<void> Function() onOpenFullUpdate;

  const WeeklyMeasurementPromptSheet({
    super.key,
    required this.overview,
    required this.baseline,
    required this.onOpenFullUpdate,
  });

  @override
  State<WeeklyMeasurementPromptSheet> createState() =>
      _WeeklyMeasurementPromptSheetState();
}

class _WeeklyMeasurementPromptSheetState
    extends State<WeeklyMeasurementPromptSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _waistController;
  late final TextEditingController _weightController;

  BodyMetric? _latestWaist;
  BodyMetric? _latestWeight;
  DateTime? _waistDate;
  bool _saving = false;
  String? _error;

  bool get _hasPrevious => _latestWaist != null;

  @override
  void initState() {
    super.initState();
    _latestWaist = widget.baseline.latest('waistCm');
    _latestWeight = widget.baseline.latest('weightKg');

    for (final record in widget.overview.records) {
      if (record.status == 'SAVED' &&
          !record.synthetic &&
          record.metrics.containsKey('waistCm')) {
        final d = DateTime.tryParse(record.recordedDate);
        if (d != null && (_waistDate == null || d.isAfter(_waistDate!))) {
          _waistDate = d;
        }
      }
    }

    final initialWaist = _latestWaist?.value;
    final initialWeight = _latestWeight?.value ??
        (widget.overview.profile?['weight'] as num?)?.toDouble();

    _waistController = TextEditingController(
      text: initialWaist != null
          ? initialWaist.toStringAsFixed(initialWaist % 1 == 0 ? 0 : 1)
          : '',
    );

    _weightController = TextEditingController(
      text: initialWeight != null
          ? initialWeight.toStringAsFixed(initialWeight % 1 == 0 ? 0 : 1)
          : '',
    );
  }

  @override
  void dispose() {
    _waistController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double? _parseNumber(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _submitNew() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final waistVal = _parseNumber(_waistController.text);
    final weightVal = _parseNumber(_weightController.text);

    if (waistVal == null || weightVal == null) {
      setState(() => _error = 'Please enter valid waist and weight values.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final payload = <String, dynamic>{
        'recordedDate': CacheScope.todayKey(DateTime.now()),
        'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        'metrics': {
          'waistCm': {'value': waistVal, 'source': 'tape'},
          'weightKg': {'value': weightVal, 'source': 'scale'},
        },
        'photos': [],
        'savePhotos': false,
        'requestCoaching': false,
      };

      await BodyAssessmentRepository.shared.save(payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not save measurements. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _continueWithPrevious() async {
    if (_saving || !_hasPrevious) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final waistVal = _latestWaist!.value;
      final weightVal = _latestWeight?.value ??
          (widget.overview.profile?['weight'] as num?)?.toDouble() ??
          75.0;

      final payload = <String, dynamic>{
        'recordedDate': CacheScope.todayKey(DateTime.now()),
        'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        'metrics': {
          'waistCm': {'value': waistVal, 'source': 'tape'},
          'weightKg': {'value': weightVal, 'source': 'scale'},
        },
        'photos': [],
        'savePhotos': false,
        'requestCoaching': false,
      };

      await BodyAssessmentRepository.shared.save(payload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // If network fails to re-stamp, previous reading still satisfies baseline
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysAgo = _waistDate != null
        ? DateTime.now().difference(_waistDate!).inDays
        : null;

    final dateLabel = daysAgo != null
        ? (daysAgo == 0
            ? 'Recorded today'
            : daysAgo == 1
                ? 'Recorded yesterday'
                : 'Recorded $daysAgo days ago')
        : null;

    return FitnessTheme(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FitnessText(
                      _hasPrevious
                          ? 'Weekly Body Check-in'
                          : 'Body Measurements Required',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.4,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancel',
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, size: 20, color: FitnessTheme.muted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FitnessText(
                _hasPrevious
                    ? 'Confirm your measurements to calibrate your AI workout plan for the upcoming week.'
                    : 'Setcraft AI needs your waist measurement to calibrate body composition and mechanical loads.',
                style: const TextStyle(
                  fontSize: 13,
                  color: FitnessTheme.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              if (_hasPrevious) ...[
                PremiumSurface(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FitnessText(
                              'Previous readings',
                              style: TextStyle(
                                fontSize: 11,
                                color: FitnessTheme.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Waist: ${_latestWaist!.value.toStringAsFixed(1)} cm'
                              '${_latestWeight != null ? '   ·   Weight: ${_latestWeight!.value.toStringAsFixed(1)} kg' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: FitnessTheme.silver,
                              ),
                            ),
                            if (dateLabel != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FitnessTheme.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _waistController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Waist (cm)',
                        hintText: 'e.g. 82.0',
                        helperText: 'Around navel',
                        helperStyle: const TextStyle(
                          fontSize: 11,
                          color: FitnessTheme.muted,
                        ),
                        filled: true,
                        fillColor: FitnessTheme.canvas,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      validator: (text) {
                        final val = _parseNumber(text ?? '');
                        if (val == null || val < 30 || val > 250) {
                          return 'Enter 30–250 cm';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        hintText: 'e.g. 78.5',
                        helperText: 'Scale reading',
                        helperStyle: const TextStyle(
                          fontSize: 11,
                          color: FitnessTheme.muted,
                        ),
                        filled: true,
                        fillColor: FitnessTheme.canvas,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      validator: (text) {
                        final val = _parseNumber(text ?? '');
                        if (val == null || val < 20 || val > 500) {
                          return 'Enter 20–500 kg';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _saving ? null : widget.onOpenFullUpdate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FitnessTheme.canvas,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 16,
                          color: FitnessTheme.silver,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FitnessText(
                                'Open full measurements screen',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              FitnessText(
                                'Log chest, hips, arms, or DEXA readings',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: FitnessTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: FitnessTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                FitnessText(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              LiquidChromeButton(
                title: _hasPrevious
                    ? 'Update & Generate Plan'
                    : 'Save & Generate Plan',
                onPressed: _saving ? null : _submitNew,
                isLoading: _saving,
              ),
              if (_hasPrevious) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : _continueWithPrevious,
                  child: FitnessText(
                    'Continue with previous (${_latestWaist!.value.toStringAsFixed(1)} cm)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: FitnessTheme.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
