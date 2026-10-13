import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/health/phone_sleep_service.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/wellness_repository.dart';
import 'sleep_preferences_view.dart';

class SleepEntryView extends StatefulWidget {
  final DateTime? initialDate;
  final WellnessRepository? repository;
  final PhoneSleepService? phoneSleep;
  const SleepEntryView(
      {super.key, this.initialDate, this.repository, this.phoneSleep});
  @override
  State<SleepEntryView> createState() => _SleepEntryViewState();
}

class _SleepEntryViewState extends State<SleepEntryView> {
  WellnessRepository get repository =>
      widget.repository ?? WellnessRepository.shared;
  PhoneSleepService get phone => widget.phoneSleep ?? PhoneSleepService.shared;
  final _hours = TextEditingController(),
      _minutes = TextEditingController(text: '0');
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String _usage = 'UNKNOWN';
  int? _energy, _rested, _soreness;
  bool _loading = true, _saving = false, _changing = false, _tracking = false;
  String? _error, _phoneMessage;
  PhoneSleepEstimate? _suggested, _accepted;
  TimeOfDay? _bedtime, _wake;
  int _request = 0;
  bool get _fallback => _usage == 'NONE';
  bool get _busy => _saving || _changing;
  bool get _completeCheckIn =>
      _fallback && _rested != null && _energy != null && _soreness != null;

  @override
  void initState() {
    super.initState();
    _date = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _hours.addListener(_durationChanged);
    _minutes.addListener(_durationChanged);
    _load();
  }

  void _durationChanged() {
    final estimate = _accepted;
    final total = (inputNumber(_hours.text) ?? -1) * 60 +
        (inputNumber(_minutes.text) ?? -1);
    if (estimate != null && total != estimate.minutes && mounted) {
      setState(() => _accepted = null);
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _accepted = null;
      _suggested = null;
      _bedtime = null;
      _wake = null;
    });
    try {
      if (AppDataMode.shared.preview) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final owner = await CacheScope.userId();
      final usage = await repository.wearableUsage();
      final entry = await repository.load(CacheScope.todayKey(_date));
      PhoneSleepEstimate? suggested;
      var tracking = false;
      if (usage == 'NONE' && phone.supported) {
        try {
          tracking = await phone.enabled();
          suggested = await phone.estimate(CacheScope.todayKey(_date));
        } catch (_) {/* Manual check-in remains available. */}
      }
      if (!mounted ||
          request != _request ||
          owner != await CacheScope.userId()) {
        return;
      }
      final total = (entry?['sleepMinutes'] as num?)?.toInt();
      setState(() {
        _usage = usage;
        _hours.text = total == null ? '' : (total ~/ 60).toString();
        _minutes.text = total == null ? '0' : (total % 60).toString();
        _energy = (entry?['energy'] as num?)?.toInt();
        _rested = (entry?['rested'] as num?)?.toInt();
        _soreness = (entry?['soreness'] as num?)?.toInt();
        _tracking = tracking;
        _suggested = total == null ? suggested : null;
        if (entry?['source'] == 'phone_estimate_confirmed') {
          final start =
              DateTime.tryParse(entry?['sleepStartedAt'] as String? ?? '');
          final end =
              DateTime.tryParse(entry?['sleepEndedAt'] as String? ?? '');
          if (start != null && end != null) {
            _accepted = PhoneSleepEstimate(start.toLocal(), end.toLocal());
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = 'Could not load sleep settings. Try again.';
        });
      }
    }
  }

  Future<void> _chooseUsage(String usage) async {
    if (_busy || usage == _usage) return;
    setState(() {
      _changing = true;
      _error = null;
    });
    try {
      await repository.setWearableUsage(usage);
      if (usage != 'NONE' && phone.supported) {
        try {
          await phone.stop();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _usage = usage;
        if (!_fallback) {
          _rested = null;
          _soreness = null;
          _accepted = null;
          _suggested = null;
          _tracking = false;
        }
      });
      if (_fallback && phone.supported) {
        final estimate = await phone.estimate(CacheScope.todayKey(_date));
        if (mounted) setState(() => _suggested = estimate);
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not save your wearable preference. Try again.');
      }
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  Future<void> _toggleTracking(bool enabled) async {
    if (!_fallback || _busy) return;
    setState(() {
      _changing = true;
      _phoneMessage = null;
    });
    try {
      if (enabled) {
        final granted = await phone.start();
        if (mounted) {
          setState(() {
            _tracking = granted;
            _phoneMessage = granted
                ? 'Estimation is on. Check here after your next night.'
                : 'Permission was not granted. You can enter sleep instead.';
          });
        }
      } else {
        await phone.stop();
        if (mounted) {
          setState(() {
            _tracking = false;
            _suggested = null;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tracking = false;
          _phoneMessage =
              'Phone estimation is unavailable. You can enter sleep instead.';
        });
      }
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2000),
        lastDate: DateTime.now());
    if (date == null || !mounted) return;
    setState(() => _date = date);
    await _load();
  }

  Future<void> _pickTime(bool bedtime) async {
    final chosen = await showTimePicker(
        context: context,
        initialTime: bedtime
            ? (_bedtime ?? const TimeOfDay(hour: 22, minute: 0))
            : (_wake ?? const TimeOfDay(hour: 7, minute: 0)));
    if (chosen == null || !mounted) return;
    setState(() {
      if (bedtime) {
        _bedtime = chosen;
      } else {
        _wake = chosen;
      }
      _accepted = null;
      if (_bedtime != null && _wake != null) {
        final total = (_wake!.hour * 60 +
                _wake!.minute -
                _bedtime!.hour * 60 -
                _bedtime!.minute +
                1440) %
            1440;
        _hours.text = (total ~/ 60).toString();
        _minutes.text = (total % 60).toString();
      }
    });
  }

  void _confirmEstimate() {
    final estimate = _suggested;
    if (estimate == null || !_fallback) return;
    setState(() {
      _hours.text = (estimate.minutes ~/ 60).toString();
      _minutes.text = (estimate.minutes % 60).toString();
      _accepted = estimate;
      _suggested = null;
    });
  }

  void _showError(String message) {
    setState(() => _error = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: FitnessText(message)));
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final hours = inputNumber(_hours.text),
        minutes =
            _minutes.text.trim().isEmpty ? 0.0 : inputNumber(_minutes.text);
    if (hours == null ||
        minutes == null ||
        hours != hours.round() ||
        minutes != minutes.round() ||
        hours < 0 ||
        hours > 24 ||
        minutes < 0 ||
        minutes > 59 ||
        hours * 60 + minutes > 1440) {
      _showError('Enter hours from 0 to 24 and minutes from 0 to 59.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final entry = await repository.save(
          CacheScope.todayKey(_date), (hours * 60 + minutes).round(), _energy,
          rested: _fallback ? _rested : null,
          soreness: _fallback ? _soreness : null,
          estimate: _fallback ? _accepted : null);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: FitnessText('Sleep saved')));
        Navigator.pop(context, entry);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        final body = error is DioException ? error.response?.data : null;
        final message = error is StateError
            ? error.message.toString()
            : body is Map && body['error'] is String
                ? body['error'] as String
                : 'Could not save. Your entry is still here. Try again.';
        _showError(message);
      }
    }
  }

  Widget _rating(String title, String low, String middle, String high,
          int? selected, ValueChanged<int?> onChanged) =>
      Padding(
          padding: const EdgeInsets.only(top: 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FitnessText(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final option in [(1, low), (3, middle), (5, high)])
                ChoiceChip(
                    label: FitnessText(option.$2),
                    selected: selected == option.$1,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => onChanged(
                            selected == option.$1 ? null : option.$1)))
            ])
          ]));
  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          appBar: AppBar(
              backgroundColor: FitnessTheme.canvas,
              surfaceTintColor: Colors.transparent,
              title: FitnessText(
                  _fallback ? 'Sleep & daily check-in' : 'Log sleep',
                  style: const TextStyle(fontSize: 19))),
          bottomNavigationBar: _loading || AppDataMode.shared.preview
              ? null
              : SafeArea(
                  top: false,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: FitnessSubmit(
                          label:
                              _completeCheckIn ? 'Save check-in' : 'Save sleep',
                          busy: _saving,
                          onPressed: _changing ? null : _save))),
          body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(CupertinoIcons.moon_stars,
                            color: FitnessTheme.violet, size: 36),
                        const SizedBox(height: 16),
                        const FitnessText('Your night, logged',
                            style: TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.8)),
                        const SizedBox(height: 8),
                        FitnessText(
                            _fallback
                                ? 'Sleep, rest and energy. A quick check-in without a wearable.'
                                : 'Add missing sleep. Synced sleep is used when available.',
                            style: const TextStyle(
                                color: FitnessTheme.muted,
                                fontSize: 14,
                                height: 1.5)),
                        const SizedBox(height: 22),
                        if (AppDataMode.shared.preview)
                          const FitnessText(
                              'Preview is read-only. Switch to real data to save an entry.')
                        else if (_loading)
                          const Center(child: CupertinoActivityIndicator())
                        else ...[
                          if (_usage == 'UNKNOWN')
                            FitnessCard(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const FitnessText('Choose your sleep setup',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 10),
                                  WearablePreferencePicker(
                                      usage: _usage,
                                      onChanged: _busy ? null : _chooseUsage),
                                  if (_changing)
                                    const Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: CupertinoActivityIndicator()),
                                ]))
                          else
                            FitnessCard(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  FitnessText(
                                      _fallback
                                          ? 'Manual sleep & check-in'
                                          : 'Using a wearable',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  FitnessText(
                                      _fallback
                                          ? 'Your setup is saved. Phone estimation stays optional.'
                                          : 'Your watch shares readings through your health app. You can enter missing sleep here.',
                                      style: const TextStyle(
                                          color: FitnessTheme.muted,
                                          fontSize: 12,
                                          height: 1.4)),
                                  TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () async {
                                              await Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          SleepPreferencesView(
                                                              repository:
                                                                  repository)));
                                              if (mounted) await _load();
                                            },
                                      child: const FitnessText(
                                          'Sleep preferences')),
                                ])),
                          if (_fallback && phone.supported) ...[
                            const SizedBox(height: 14),
                            FitnessCard(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Material(
                                      color: Colors.transparent,
                                      child: SwitchListTile.adaptive(
                                          contentPadding: EdgeInsets.zero,
                                          title: const FitnessText(
                                              'Estimate my sleep'),
                                          subtitle: const FitnessText(
                                              'Uses phone motion and light. You confirm before saving.'),
                                          value: _tracking,
                                          onChanged:
                                              _busy ? null : _toggleTracking)),
                                  const FitnessText(
                                      'May confuse phone inactivity with sleep. No sleep stages or heart readings.',
                                      style: TextStyle(
                                          color: FitnessTheme.muted,
                                          fontSize: 12,
                                          height: 1.4)),
                                  if (_phoneMessage != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: FitnessText(_phoneMessage!,
                                            style:
                                                const TextStyle(fontSize: 12))),
                                ])),
                          ],
                          if (_fallback && _suggested != null) ...[
                            const SizedBox(height: 14),
                            FitnessCard(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const FitnessText('Estimated sleep',
                                      style: TextStyle(
                                          color: FitnessTheme.muted,
                                          fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text(
                                      '${_suggested!.minutes ~/ 60} h ${_suggested!.minutes % 60} m',
                                      style: const TextStyle(fontSize: 26)),
                                  Text(
                                      '${TimeOfDay.fromDateTime(_suggested!.start).format(context)} – ${TimeOfDay.fromDateTime(_suggested!.end).format(context)}',
                                      style: const TextStyle(
                                          color: FitnessTheme.muted)),
                                  TextButton(
                                      onPressed:
                                          _busy ? null : _confirmEstimate,
                                      child: const FitnessText(
                                          'Confirm estimated sleep')),
                                  const FitnessText(
                                      'Or enter a different duration below.',
                                      style: TextStyle(
                                          color: FitnessTheme.muted,
                                          fontSize: 12)),
                                ])),
                          ],
                          const SizedBox(height: 18),
                          FitnessCard(
                              child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                          CupertinoIcons.calendar,
                                          size: 20),
                                      title: const FitnessText('Wake-up date',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: FitnessTheme.muted)),
                                      subtitle: Text(DateFormat.yMMMd(
                                              Localizations.localeOf(context)
                                                  .toLanguageTag())
                                          .format(_date)),
                                      trailing: const Icon(
                                          CupertinoIcons.chevron_down,
                                          size: 14),
                                      onTap: _busy ? null : _pickDate))),
                          if (_fallback) ...[
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 6, children: [
                              OutlinedButton(
                                  onPressed:
                                      _busy ? null : () => _pickTime(true),
                                  child: FitnessText(
                                      _bedtime == null
                                          ? 'Set bedtime'
                                          : 'Bedtime: {time}',
                                      values: {
                                        'time': _bedtime?.format(context) ?? ''
                                      })),
                              OutlinedButton(
                                  onPressed:
                                      _busy ? null : () => _pickTime(false),
                                  child: FitnessText(
                                      _wake == null
                                          ? 'Set wake-up'
                                          : 'Wake-up: {time}',
                                      values: {
                                        'time': _wake?.format(context) ?? ''
                                      })),
                            ]),
                            const FitnessText(
                                'Or enter the time you actually slept.',
                                style: TextStyle(
                                    color: FitnessTheme.muted, fontSize: 12)),
                          ],
                          const SizedBox(height: 14),
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
                                    numeric: true))
                          ]),
                          if (_fallback)
                            _rating(
                                'How rested do you feel?',
                                'Not rested',
                                'Somewhat rested',
                                'Well rested',
                                _rested,
                                (v) => _rested = v),
                          if (_fallback)
                            _rating('How is your energy?', 'Low energy', 'Okay',
                                'Energized', _energy, (v) => _energy = v),
                          if (_fallback)
                            _rating(
                                'How sore are you?',
                                'Little soreness',
                                'Some soreness',
                                'Very sore',
                                _soreness,
                                (v) => _soreness = v),
                          const SizedBox(height: 20),
                          FitnessText(
                              _accepted == null
                                  ? 'Self-reported'
                                  : 'Phone estimate · confirmed',
                              style: const TextStyle(
                                  color: FitnessTheme.muted, fontSize: 12)),
                          const SizedBox(height: 6),
                          FitnessText(
                              _fallback
                                  ? (_completeCheckIn
                                      ? 'Your check-in is complete. Save to see your daily estimate.'
                                      : 'Sleep can be saved now. Answer rest, energy and soreness to see your daily estimate.')
                                  : 'Entered sleep can support a readiness estimate when heart readings are available.',
                              style: const TextStyle(
                                  color: FitnessTheme.muted,
                                  fontSize: 12,
                                  height: 1.5)),
                          const SizedBox(height: 24),
                        ],
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: FitnessText(_error!,
                                  style: const TextStyle(
                                      color: FitnessTheme.coral,
                                      fontSize: 13))),
                        if (!_loading && _error != null)
                          TextButton(
                              onPressed: _busy ? null : _load,
                              child: const FitnessText('Retry')),
                      ])))));
}
