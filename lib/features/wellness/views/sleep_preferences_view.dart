import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/wellness_repository.dart';

class WearablePreferencePicker extends StatelessWidget {
  final String usage;
  final ValueChanged<String>? onChanged;

  const WearablePreferencePicker(
      {super.key, required this.usage, this.onChanged});

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(
            label: const FitnessText('I use a wearable'),
            selected: usage == 'WEARABLE',
            onSelected:
                onChanged == null ? null : (_) => onChanged!('WEARABLE')),
        ChoiceChip(
            label: const FitnessText('I don’t use a wearable'),
            selected: usage == 'NONE',
            onSelected: onChanged == null ? null : (_) => onChanged!('NONE')),
      ]);
}

class SleepPreferencesView extends StatefulWidget {
  final WellnessRepository? repository;
  const SleepPreferencesView({super.key, this.repository});

  @override
  State<SleepPreferencesView> createState() => _SleepPreferencesViewState();
}

class _SleepPreferencesViewState extends State<SleepPreferencesView> {
  WellnessRepository get repository =>
      widget.repository ?? WellnessRepository.shared;
  String _usage = 'UNKNOWN';
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final usage = await repository.wearableUsage();
      if (mounted) {
        setState(() {
          _usage = usage;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load sleep settings. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(String usage) async {
    if (_busy || _usage == usage) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.setWearableUsage(usage);
      if (mounted) setState(() => _usage = usage);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not save your wearable preference. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        appBar: AppBar(title: const FitnessText('Sleep preferences')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          const FitnessText('Your sleep setup',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const FitnessText(
              'Saved to your account. You can change this whenever you need.',
              style: TextStyle(
                  color: FitnessTheme.muted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          FitnessCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                WearablePreferencePicker(
                    usage: _usage, onChanged: _busy ? null : _choose),
                const SizedBox(height: 16),
                FitnessText(
                    _usage == 'WEARABLE'
                        ? 'Setcraft reads shared watch records through Health Connect or Apple Health. This choice does not pair a watch.'
                        : _usage == 'NONE'
                            ? 'Enter sleep manually and complete a daily check-in. On Android, phone estimation is an optional choice in Log sleep.'
                            : 'Choose your sleep setup. You can log sleep even when your watch has not shared a reading.',
                    style: const TextStyle(
                        color: FitnessTheme.muted, fontSize: 12, height: 1.5)),
              ])),
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 20),
                child: LinearProgressIndicator()),
          if (_error != null) ...[
            const SizedBox(height: 16),
            FitnessText(_error!),
            TextButton(
                onPressed: _busy ? null : _load,
                child: const FitnessText('Retry')),
          ],
        ])),
      ));
}
