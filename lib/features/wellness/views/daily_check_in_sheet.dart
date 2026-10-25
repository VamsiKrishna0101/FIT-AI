import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/wellness_repository.dart';

Future<Map<String, dynamic>?> showDailyCheckInSheet(BuildContext context,
        {required DateTime date,
        Map<String, dynamic>? entry,
        int? syncedSleepMinutes,
        WellnessRepository? repository}) =>
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: FitnessTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DailyCheckInSheet(
          date: date,
          entry: entry,
          syncedSleepMinutes: syncedSleepMinutes,
          repository: repository),
    );

class DailyCheckInSheet extends StatefulWidget {
  final DateTime date;
  final Map<String, dynamic>? entry;
  final int? syncedSleepMinutes;
  final WellnessRepository? repository;
  const DailyCheckInSheet(
      {super.key,
      required this.date,
      this.entry,
      this.syncedSleepMinutes,
      this.repository});
  @override
  State<DailyCheckInSheet> createState() => _DailyCheckInSheetState();
}

class _DailyCheckInSheetState extends State<DailyCheckInSheet> {
  late final _hours = TextEditingController();
  late final _minutes = TextEditingController();
  int? _rested, _energy, _soreness;
  bool _saving = false;
  String? _error;
  late final Future<String> _owner = CacheScope.userId();
  @override
  void initState() {
    super.initState();
    final minutes = (widget.entry?['sleepMinutes'] as num?)?.toInt() ??
        widget.syncedSleepMinutes;
    _hours.text = minutes == null ? '' : '${minutes ~/ 60}';
    _minutes.text = minutes == null ? '0' : '${minutes % 60}';
    _rested = (widget.entry?['rested'] as num?)?.toInt();
    _energy = (widget.entry?['energy'] as num?)?.toInt();
    _soreness = (widget.entry?['soreness'] as num?)?.toInt();
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final hours = int.tryParse(_hours.text.trim());
    final minutes = int.tryParse(_minutes.text.trim());
    if (hours == null ||
        minutes == null ||
        hours < 0 ||
        minutes < 0 ||
        minutes > 59 ||
        hours * 60 + minutes > 1440) {
      setState(() => _error = 'Enter a valid sleep duration.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (await _owner != await CacheScope.userId()) {
        throw StateError('Session changed');
      }
      final saved = await (widget.repository ?? WellnessRepository.shared).save(
          CacheScope.todayKey(widget.date), hours * 60 + minutes, _energy,
          rested: _rested, soreness: _soreness);
      if (mounted) Navigator.pop(context, saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your check-in. Try again.';
        });
      }
    }
  }

  Widget _rating(String title, String field, List<String> labels, int? selected,
          ValueChanged<int> change) =>
      Padding(
          padding: const EdgeInsets.only(top: 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FitnessText(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                    key: ValueKey('check-in-$field-${i * 2 + 1}'),
                    label: FitnessText(labels[i],
                        style: const TextStyle(fontSize: 12)),
                    selected: selected == i * 2 + 1,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF484848),
                    backgroundColor: FitnessTheme.canvas,
                    side: const BorderSide(color: FitnessTheme.line),
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => change(i * 2 + 1))),
            ]),
          ]));

  @override
  Widget build(BuildContext context) => FitnessTheme(
        child: PopScope(
            canPop: !_saving,
            child: SafeArea(
              top: false,
              child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .88),
                    child: SingleChildScrollView(
                        key: const ValueKey('daily-check-in-sheet'),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(children: [
                                const Expanded(
                                    child: FitnessText(
                                        'How are you feeling today?',
                                        style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -.4))),
                                IconButton(
                                    key: const ValueKey('daily-check-in-close'),
                                    tooltip: fitnessText(context, 'Close'),
                                    onPressed: _saving
                                        ? null
                                        : () => Navigator.pop(context),
                                    icon: const Icon(CupertinoIcons.xmark,
                                        size: 20, color: FitnessTheme.muted)),
                              ]),
                              const SizedBox(height: 6),
                              const FitnessText(
                                  'Optional · Save sleep on its own, or add how you feel for a readiness estimate.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: FitnessTheme.muted,
                                      height: 1.5)),
                              const SizedBox(height: 22),
                              const FitnessText('Sleep duration',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                    child: FitnessInput(
                                        label: 'Hours',
                                        controller: _hours,
                                        numeric: true)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: FitnessInput(
                                        label: 'Minutes',
                                        controller: _minutes,
                                        numeric: true)),
                              ]),
                              _rating(
                                  'How rested do you feel?',
                                  'rest',
                                  [
                                    'Not rested',
                                    'Somewhat rested',
                                    'Well rested'
                                  ],
                                  _rested,
                                  (value) => _rested = value),
                              _rating(
                                  'How is your energy?',
                                  'energy',
                                  ['Low energy', 'Okay', 'Energized'],
                                  _energy,
                                  (value) => _energy = value),
                              _rating(
                                  'How sore are you?',
                                  'soreness',
                                  [
                                    'Little soreness',
                                    'Some soreness',
                                    'Very sore'
                                  ],
                                  _soreness,
                                  (value) => _soreness = value),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: FitnessText(_error!,
                                        style: const TextStyle(
                                            color: FitnessTheme.coral,
                                            fontSize: 12))),
                              const SizedBox(height: 24),
                              FilledButton(
                                  key: const ValueKey('daily-check-in-save'),
                                  onPressed: _saving ? null : _save,
                                  style: FilledButton.styleFrom(
                                      backgroundColor: FitnessTheme.silver,
                                      foregroundColor: FitnessTheme.canvas,
                                      minimumSize: const Size.fromHeight(48)),
                                  child: _saving
                                      ? const CupertinoActivityIndicator()
                                      : const FitnessText('Save check-in')),
                              const SizedBox(height: 10),
                              const FitnessText(
                                  'Based on your answers · a fitness estimate, not measured recovery.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      height: 1.5,
                                      color: FitnessTheme.muted)),
                            ])),
                  )),
            )),
      );
}
