import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/storage/local_cache.dart';
import 'workout_set_details.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import 'package:intl/intl.dart';

class WorkoutSetEntry extends StatefulWidget {
  final String date, itemId;
  final int number;
  final Map<String, dynamic>? log;
  final String? targetLabel;
  final int? suggestedReps;
  final double? suggestedWeight;
  final Future<Map<String, dynamic>>? previous;
  final bool disabled;
  final bool bodyweight, compact, active, showSaveAction, showDetailsAction;
  final VoidCallback? onActivate;
  final Future<void> Function(int reps, double? weight, double? effort) onSave;
  final Future<void> Function() onDelete;
  const WorkoutSetEntry(
      {super.key,
      required this.date,
      required this.itemId,
      required this.number,
      this.log,
      this.targetLabel,
      this.suggestedReps,
      this.suggestedWeight,
      this.previous,
      this.bodyweight = false,
      this.compact = false,
      this.active = true,
      this.showSaveAction = true,
      this.showDetailsAction = true,
      this.onActivate,
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
  bool _confirmed = false;
  bool _touched = false;
  double? _effort;
  Future<void>? _pendingSave;
  final _weightFocus = FocusNode(), _repsFocus = FocusNode();
  bool _detailsOpen = false, _addedLoad = false;
  String? _validation;
  bool get _showWeight => !widget.bodyweight || _addedLoad;
  @override
  void initState() {
    super.initState();
    _reps.text = widget.log?['reps']?.toString() ??
        widget.suggestedReps?.toString() ??
        '';
    // A target is guidance, never a recorded load.
    final weight = widget.log?['weight'];
    _addedLoad = weight is num && weight > 0;
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
    if (draft != null && !_touched && !_confirmed) {
      _touched = true;
      _reps.text = draft['reps'] as String? ?? '';
      final draftWeight = draft['weight'] as String? ?? '';
      // Older drafts could contain a target that the user never entered.
      final legacyTarget = draft['version'] != 2 &&
          widget.log?['weight'] == null &&
          double.tryParse(draftWeight.replaceAll(',', '.')) ==
              widget.suggestedWeight;
      _weight.text = legacyTarget ? '' : draftWeight;
      if (widget.bodyweight) {
        _addedLoad =
            (double.tryParse(_weight.text.replaceAll(',', '.')) ?? 0) > 0;
      }
      _effort = (draft['rpe'] as num?)?.toDouble() ?? _effort;
    }
    setState(() {});
  }

  void _changed(String _) {
    _validation = null;
    _confirmed = false;
    _touched = true;
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _persist);
  }

  void _persist() {
    final key = _draftKey;
    if (key != null) {
      unawaited(LocalCache.shared.saveJson(key, {
        'version': 2,
        'reps': _reps.text,
        'weight': _weight.text,
        'rpe': _effort
      }));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (hasPendingValues) _persist();
    _reps.dispose();
    _weight.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  double? get _load =>
      _showWeight ? double.tryParse(_weight.text.replaceAll(',', '.')) : null;
  bool get _dirty =>
      int.tryParse(_reps.text) != widget.log?['reps'] ||
      _load != widget.log?['weight'] ||
      _effort != widget.log?['rpe'];
  bool get hasPendingValues =>
      !_confirmed &&
      _touched &&
      _dirty &&
      (_reps.text.isNotEmpty || _weight.text.isNotEmpty || widget.log != null);

  Future<void> savePending({bool confirmSuggestion = false}) async {
    if (_pendingSave != null) {
      await _pendingSave;
      return;
    }
    if (confirmSuggestion) {
      _touched = true;
      if (!widget.bodyweight && (_load == null || _load! <= 0)) {
        _invalid('Enter the weight you lifted before saving this set.',
            weight: true);
      }
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

  Future<void> waitForSave() async {
    await _pendingSave;
  }

  Map<String, dynamic>? pendingSet() {
    if (!hasPendingValues) return null;
    final reps = int.tryParse(_reps.text);
    final load = _load;
    if (!widget.bodyweight && (load == null || load <= 0)) {
      _invalid('Enter the weight you lifted before saving this set.',
          weight: true);
    }
    if (reps == null ||
        reps < 1 ||
        reps > 1000 ||
        (_weight.text.isNotEmpty &&
            (load == null || load < 0 || load > 1000))) {
      _invalid('Enter valid reps and load.');
    }
    return {
      'setNumber': widget.number,
      'reps': reps,
      'weight': load,
      'rpe': _effort
    };
  }

  Never _invalid(String message, {bool weight = false}) {
    if (mounted) {
      setState(() => _validation = message);
      if (weight) _weightFocus.requestFocus();
      unawaited(Scrollable.ensureVisible(context,
          alignment: .35, duration: const Duration(milliseconds: 200)));
    }
    throw FormatException(message);
  }

  void confirmSaved() {
    _confirmed = true;
    _debounce?.cancel();
    if (_draftKey != null) {
      unawaited(LocalCache.shared.remove(_draftKey!));
    }
  }

  Future<void> _commit() async {
    final values = pendingSet();
    if (values == null) return;
    setState(() => _busy = true);
    try {
      await widget.onSave(values['reps'] as int, values['weight'] as double?,
          values['rpe'] as double?);
      _confirmed = true;
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
      await savePending(confirmSuggestion: true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fitnessText(
                context,
                error is FormatException
                    ? error.message
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
      _confirmed = true;
      _touched = false;
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

  void focusEditor() {
    if (!mounted || !widget.active) return;
    if (widget.bodyweight) {
      _repsFocus.requestFocus();
    } else {
      _weightFocus.requestFocus();
    }
  }

  Future<void> showDetails() async {
    if (widget.disabled || _busy || _detailsOpen) return;
    FocusScope.of(context).unfocus();
    _detailsOpen = true;
    final details = await showModalBottomSheet<WorkoutSetDetails>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: DSColors.bg,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: DSColors.border)),
        builder: (_) => WorkoutSetDetailsSheet(
            number: widget.number,
            bodyweight: widget.bodyweight,
            canDelete: widget.log != null,
            effort: _effort,
            weight: _weight.text));
    _detailsOpen = false;
    if (!mounted || details == null) return;
    if (details.delete) {
      await _delete();
      return;
    }
    _effort = details.effort;
    if (widget.bodyweight) {
      _weight.text = details.weight;
      _addedLoad = details.weight.isNotEmpty;
    }
    _changed('');
  }

  String _number(num value) => (NumberFormat.decimalPattern(
          Localizations.localeOf(context).toLanguageTag())
        ..maximumFractionDigits = 1)
      .format(value);

  Widget _previousValue() => FutureBuilder<Map<String, dynamic>>(
      future: widget.previous,
      builder: (context, snapshot) {
        final row = (snapshot.data?['sets'] as List? ?? [])
            .whereType<Map>()
            .where((row) => row['setNumber'] == widget.number)
            .firstOrNull;
        final weight = row?['weight'];
        final reps = row?['reps'];
        final value = row == null
            ? '—'
            : weight is num && weight > 0
                ? '${_number(weight)} × ${reps ?? '—'}'
                : reps == null
                    ? '—'
                    : '$reps ${fitnessText(context, 'reps')}';
        return Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, height: 1.4, color: DSColors.muted));
      });

  Widget _input(bool weight, {bool label = false}) {
    final field = TextField(
        key: ValueKey('set-${weight ? 'weight' : 'reps'}-${widget.number}'),
        controller: weight ? _weight : _reps,
        focusNode: weight ? _weightFocus : _repsFocus,
        enabled: !widget.disabled && !_busy,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: DSColors.silver),
        keyboardType: weight
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: [
          if (weight)
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          else
            FilteringTextInputFormatter.digitsOnly
        ],
        onChanged: _changed,
        decoration: InputDecoration(
            hintText: weight ? '—' : fitnessText(context, 'Reps'),
            semanticCounterText:
                fitnessText(context, weight ? 'Weight (kg)' : 'Reps'),
            filled: true,
            fillColor: const Color(0xFF0D0D0D),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: DSColors.border, width: .7)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: DSColors.silver, width: .7))));
    if (!label) return field;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(fitnessText(context, weight ? 'Weight (kg)' : 'Reps'),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 10, height: 1.4, color: DSColors.muted)),
      const SizedBox(height: 6),
      field,
    ]);
  }

  Widget _savedValue(bool weight) {
    final value = weight ? _weight.text : _reps.text;
    final number = num.tryParse(value.replaceAll(',', '.'));
    return Text(number == null ? '—' : _number(number),
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 15,
            color: widget.log == null ? DSColors.muted : DSColors.silver));
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.log != null &&
        !_dirty &&
        (widget.bodyweight || (_load != null && _load! > 0));
    final large = MediaQuery.textScalerOf(context).scale(14) > 20;
    final counter = Container(
        width: 28,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: widget.active ? DSColors.silver : Colors.transparent,
            borderRadius: BorderRadius.circular(7)),
        child: Text('${widget.number}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.active ? DSColors.bg : DSColors.muted)));
    final status = widget.showSaveAction
        ? IconButton(
            tooltip: fitnessText(
                context,
                saved
                    ? (widget.log?['pendingSync'] == true
                        ? 'Saved on this phone'
                        : 'Saved')
                    : 'Save set'),
            onPressed: widget.disabled || _busy || saved ? null : _save,
            icon: _busy
                ? const CupertinoActivityIndicator()
                : const Icon(CupertinoIcons.checkmark,
                    size: 17, color: DSColors.silver))
        : SizedBox(
            width: 18,
            child: saved
                ? const Icon(CupertinoIcons.checkmark,
                    size: 14, color: DSColors.silver)
                : const SizedBox.shrink());
    Widget values() => Row(children: [
          if (!widget.bodyweight) ...[
            Expanded(
                child: widget.active
                    ? _input(true, label: large)
                    : _savedValue(true)),
            const SizedBox(width: 8)
          ],
          Expanded(
              child: widget.active
                  ? _input(false, label: large)
                  : _savedValue(false)),
        ]);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
            color: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
                onTap: widget.disabled || _busy ? null : widget.onActivate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (large) ...[
                            Row(children: [
                              counter,
                              const SizedBox(width: 8),
                              Expanded(child: _previousValue()),
                              status
                            ]),
                            const SizedBox(height: 10),
                            values(),
                          ] else
                            Row(children: [
                              counter,
                              const SizedBox(width: 8),
                              Expanded(flex: 2, child: _previousValue()),
                              const SizedBox(width: 8),
                              Expanded(
                                  flex: widget.bodyweight ? 2 : 4,
                                  child: values()),
                              const SizedBox(width: 8),
                              status,
                            ]),
                          if (widget.active && _validation != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(fitnessText(context, _validation!),
                                    style: const TextStyle(
                                        color: Color(0xFFED927F),
                                        fontSize: 12,
                                        height: 1.4))),
                          if (widget.active &&
                              widget.showDetailsAction &&
                              widget.targetLabel != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    '${fitnessText(context, 'Target')} · ${widget.targetLabel}',
                                    style: const TextStyle(
                                        color: DSColors.muted,
                                        fontSize: 11,
                                        height: 1.4))),
                          if (widget.bodyweight &&
                              _addedLoad &&
                              _weight.text.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                    '${fitnessText(context, 'Added weight (kg)')} · ${_weight.text}',
                                    style: const TextStyle(
                                        fontSize: 11, color: DSColors.muted))),
                          if (widget.active && widget.showDetailsAction)
                            Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                    onPressed: widget.disabled || _busy
                                        ? null
                                        : showDetails,
                                    style: TextButton.styleFrom(
                                        foregroundColor: DSColors.muted),
                                    child: Text(
                                        fitnessText(context, 'Set details'),
                                        style: const TextStyle(fontSize: 11)))),
                        ])))));
  }
}
