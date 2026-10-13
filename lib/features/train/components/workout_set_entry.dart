import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/storage/local_cache.dart';
import 'training_widgets.dart';

class WorkoutSetEntry extends StatefulWidget {
  final String date, itemId;
  final int number;
  final Map<String, dynamic>? log;
  final String? targetLabel;
  final bool disabled;
  final Future<void> Function(int reps, double? weight, double? effort) onSave;
  final Future<void> Function() onDelete;
  const WorkoutSetEntry(
      {super.key,
      required this.date,
      required this.itemId,
      required this.number,
      this.log,
      this.targetLabel,
      required this.disabled,
      required this.onSave,
      required this.onDelete});
  @override
  State<WorkoutSetEntry> createState() => WorkoutSetEntryState();
}

class WorkoutSetEntryState extends State<WorkoutSetEntry> {
  final _reps = TextEditingController(), _weight = TextEditingController();
  String? _draftKey;
  Timer? _debounce;
  bool _busy = false;
  double? _effort;
  Future<void>? _pendingSave;
  @override
  void initState() {
    super.initState();
    _reps.text = widget.log?['reps']?.toString() ?? '';
    final weight = widget.log?['weight'];
    _weight.text = weight == null ? '' : '$weight';
    _effort = (widget.log?['rpe'] as num?)?.toDouble();
    _restore();
  }

  Future<void> _restore() async {
    final key = await CacheScope.userKey(
        'set_draft_${widget.date}_${widget.itemId}_${widget.number}');
    final draft = await LocalCache.shared.getJson(key);
    if (!mounted) return;
    _draftKey = key;
    if (draft != null) {
      _reps.text = draft['reps'] as String? ?? '';
      _weight.text = draft['weight'] as String? ?? '';
      _effort = (draft['rpe'] as num?)?.toDouble() ?? _effort;
    }
    setState(() {});
  }

  void _changed(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _persist);
  }

  void _persist() {
    final key = _draftKey;
    if (key != null) {
      unawaited(LocalCache.shared.saveJson(
          key, {'reps': _reps.text, 'weight': _weight.text, 'rpe': _effort}));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_dirty) _persist();
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? get _load => double.tryParse(_weight.text.replaceAll(',', '.'));
  bool get _dirty =>
      int.tryParse(_reps.text) != widget.log?['reps'] ||
      _load != widget.log?['weight'] ||
      _effort != widget.log?['rpe'];
  bool get hasPendingValues =>
      _dirty &&
      (_reps.text.isNotEmpty || _weight.text.isNotEmpty || widget.log != null);

  Future<void> savePending() async {
    if (_pendingSave != null) {
      await _pendingSave;
      return;
    }
    if (!hasPendingValues) return;
    final future = _commit();
    _pendingSave = future;
    try {
      await future;
    } finally {
      _pendingSave = null;
    }
  }

  Future<void> _commit() async {
    final reps = int.tryParse(_reps.text);
    final load = _load;
    if (reps == null ||
        reps < 1 ||
        reps > 1000 ||
        (_weight.text.isNotEmpty &&
            (load == null || load < 0 || load > 1000))) {
      throw const FormatException('Enter valid reps and load.');
    }
    setState(() => _busy = true);
    try {
      await widget.onSave(reps, load, _effort);
      _debounce?.cancel();
      if (_draftKey != null) await LocalCache.shared.remove(_draftKey!);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    try {
      if (_reps.text.isEmpty) {
        throw const FormatException('Enter valid reps and load.');
      }
      await savePending();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fitnessText(
                context,
                error is FormatException
                    ? 'Enter valid reps and load.'
                    : 'Not saved yet. Tap save to retry.'))));
      }
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await widget.onDelete();
      _debounce?.cancel();
      _reps.clear();
      _weight.clear();
      _effort = null;
      if (_draftKey != null) await LocalCache.shared.remove(_draftKey!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                fitnessText(context, 'Could not save. Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.log != null && !_dirty;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.targetLabel != null) ...[
            Text('${fitnessText(context, 'Target')} · ${widget.targetLabel}',
                style: const TextStyle(color: trainingSilver, fontSize: 12)),
            const SizedBox(height: 8),
          ],
          Row(children: [
            SizedBox(
                width: 28,
                child: Text('${widget.number}',
                    style:
                        const TextStyle(color: trainingMuted, fontSize: 13))),
            Expanded(
                child: TextField(
                    controller: _weight,
                    enabled: !widget.disabled && !_busy,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    ],
                    onChanged: _changed,
                    decoration: _decoration('kg', context))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _reps,
                    enabled: !widget.disabled && !_busy,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _changed,
                    decoration: _decoration('Reps', context))),
            const SizedBox(width: 6),
            IconButton(
                tooltip: fitnessText(context, saved ? 'Saved' : 'Save set'),
                onPressed: widget.disabled || _busy || saved ? null : _save,
                style: IconButton.styleFrom(
                    backgroundColor: saved
                        ? const Color(0xFF414141)
                        : const Color(0xFF303030)),
                icon: _busy
                    ? const CupertinoActivityIndicator()
                    : Icon(
                        saved ? CupertinoIcons.checkmark : CupertinoIcons.plus,
                        size: 17,
                        color: trainingSilver)),
            SizedBox(
                width: 36,
                child: widget.log == null
                    ? null
                    : IconButton(
                        tooltip: fitnessText(context, 'Delete set'),
                        onPressed: widget.disabled || _busy ? null : _delete,
                        icon: const Icon(CupertinoIcons.minus_circle,
                            size: 17, color: trainingMuted))),
          ]),
          DropdownButton<double>(
            value: _effort,
            hint: Text(fitnessText(context, 'Effort (optional)'),
                style: const TextStyle(fontSize: 11, color: trainingMuted)),
            isDense: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF292929),
            style: const TextStyle(fontSize: 12, color: trainingSilver),
            items: [
              for (final effort in [
                for (int value = 2; value <= 20; value++) value / 2
              ])
                DropdownMenuItem(value: effort, child: Text('$effort/10'))
            ],
            onChanged: widget.disabled || _busy
                ? null
                : (value) {
                    _effort = value;
                    _changed('');
                  },
          ),
          const SizedBox(height: 8),
        ]));
  }

  InputDecoration _decoration(String hint, BuildContext context) =>
      InputDecoration(
        hintText: fitnessText(context, hint),
        filled: true,
        fillColor: const Color(0xFF292929),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none),
      );
}
