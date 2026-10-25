import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/components/neutral_schedule_chips.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/workout_schedule_repository.dart';
import '../repositories/training_repository.dart';

class RescheduleWorkoutSheet extends StatefulWidget {
  final String date;
  final WorkoutScheduleRepository? repository;
  const RescheduleWorkoutSheet(
      {super.key, required this.date, this.repository});
  @override
  State<RescheduleWorkoutSheet> createState() => _RescheduleWorkoutSheetState();
}

class _RescheduleWorkoutSheetState extends State<RescheduleWorkoutSheet> {
  late final _repo = widget.repository ?? WorkoutScheduleRepository();
  Map<String, dynamic>? _preview;
  String _action = 'SHIFT';
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({List<String>? dates}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await _repo.preview(widget.date,
          action: _action, availableDates: dates);
      if (mounted) setState(() => _preview = preview);
    } catch (error) {
      if (mounted) {
        setState(() {
          _preview = null;
          _error = TrainingRepository.errorMessage(
              error, 'Could not load your schedule. Please retry.');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final preview = _preview;
    if (_busy || preview == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.apply(widget.date, preview, _action);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _preview = null;
          _error = TrainingRepository.errorMessage(error,
              'Could not update your schedule. Review the dates and retry.');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    String dateLabel(String value) =>
        DateFormat.yMMMEd(locale).format(DateTime.parse(value));
    final changes =
        (_preview?['changes'] as List? ?? []).whereType<Map>().toList();
    final skipped = changes.where((row) => row['toDate'] == null).length;
    return NeutralScheduleChips(
        child: SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Row(children: [
                        const Expanded(
                            child: FitnessText('Rest today',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600))),
                        IconButton(
                            tooltip: 'Close',
                            onPressed:
                                _busy ? null : () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 20))
                      ]),
                      Text(dateLabel(widget.date),
                          style: const TextStyle(color: FitnessTheme.muted)),
                      const SizedBox(height: 18),
                      const FitnessText(
                          'Your unfinished workouts move forward in order. Completed workouts stay where they are.',
                          style: TextStyle(
                              color: FitnessTheme.muted, height: 1.5)),
                      const SizedBox(height: 18),
                      Wrap(spacing: 8, children: [
                        ChoiceChip(
                            label: const FitnessText('Move workouts'),
                            selected: _action == 'SHIFT',
                            onSelected: _busy
                                ? null
                                : (_) {
                                    _action = 'SHIFT';
                                    _load();
                                  }),
                        ChoiceChip(
                            label: const FitnessText('Skip today only'),
                            selected: _action == 'SKIP',
                            onSelected: _busy
                                ? null
                                : (_) {
                                    _action = 'SKIP';
                                    _load();
                                  }),
                      ]),
                      if (_preview != null && _action == 'SHIFT') ...[
                        const SizedBox(height: 20),
                        const FitnessText('Available training dates',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 7, runSpacing: 5, children: [
                          for (final value in List<String>.from(
                              _preview!['candidateDates'] as List))
                            FilterChip(
                                label: Text(dateLabel(value)),
                                selected: (_preview!['availableDates'] as List)
                                    .contains(value),
                                onSelected: _busy
                                    ? null
                                    : (selected) {
                                        final dates = List<String>.from(
                                            _preview!['availableDates']
                                                as List);
                                        if (selected) {
                                          dates.add(value);
                                        } else {
                                          dates.remove(value);
                                        }
                                        _load(dates: dates);
                                      })
                        ]),
                      ],
                      if (_busy)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: FitnessTheme.silver))),
                      for (final row in changes)
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: FitnessCard(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('${row['name']}',
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(
                                      '${dateLabel(row['fromDate'] as String)} → ${row['toDate'] == null ? 'Skip this workout' : dateLabel(row['toDate'] as String)}',
                                      style: const TextStyle(
                                          color: FitnessTheme.silver,
                                          fontSize: 13,
                                          height: 1.5)),
                                  if (row['reason'] != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text('${row['reason']}',
                                            style: const TextStyle(
                                                color: FitnessTheme.muted,
                                                fontSize: 12,
                                                height: 1.4))),
                                ]))),
                      if (skipped > 0)
                        Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: FitnessText(
                                'The $skipped listed ${skipped == 1 ? 'workout will' : 'workouts will'} be skipped. Nothing moves into next week.',
                                style: const TextStyle(
                                    color: FitnessTheme.silver,
                                    fontSize: 13,
                                    height: 1.5))),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: FitnessTheme.coral, height: 1.5))),
                      const SizedBox(height: 24),
                      if (_preview != null)
                        FitnessSubmit(
                            label: skipped > 0
                                ? 'Apply dates and confirm skips'
                                : 'Apply new dates',
                            busy: _busy,
                            onPressed: _busy ? null : _apply)
                      else if (!_busy)
                        TextButton(
                            onPressed: _load,
                            child: const FitnessText('Review schedule again')),
                    ])))));
  }
}
