import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../repositories/progress_repository.dart';
import 'progress_surface.dart';

class ExerciseOverviewControl extends StatefulWidget {
  final String exerciseId;
  final ProgressRepository? repository;
  const ExerciseOverviewControl(
      {super.key, required this.exerciseId, this.repository});
  @override
  State<ExerciseOverviewControl> createState() =>
      _ExerciseOverviewControlState();
}

class _ExerciseOverviewControlState extends State<ExerciseOverviewControl> {
  late final _repo = widget.repository ?? ProgressRepository.shared;
  bool _pinned = false, _loading = true, _saving = false, _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final pins = await _repo.pins();
      if (mounted) {
        setState(() {
          _pinned = pins.contains(widget.exerciseId);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _toggle() async {
    if (_saving || _loading) return;
    setState(() => _saving = true);
    try {
      await _repo.setPinned(widget.exerciseId, !_pinned);
      if (mounted) setState(() => _pinned = !_pinned);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fitnessText(
                context,
                error is FormatException
                    ? error.message
                    : 'Could not save. Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
          onPressed: _loading || _saving
              ? null
              : _failed
                  ? _load
                  : _toggle,
          style: TextButton.styleFrom(foregroundColor: progressSilver),
          child: Text(
              fitnessText(
                  context,
                  _failed
                      ? 'Retry overview setting'
                      : _pinned
                          ? 'Remove from overview'
                          : 'Show on overview'),
              style: const TextStyle(fontSize: 12))));
}
