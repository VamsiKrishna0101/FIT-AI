import 'package:flutter/material.dart';
import '../../../../core/cache/cache_scope.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/ds_motion.dart';
import '../../../../core/theme/fitness_theme.dart';

Future<Map<String, dynamic>?> showCompositionReadings(BuildContext context,
        {Map<String, dynamic>? initial, String? scanDate}) =>
    showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        backgroundColor: FitnessTheme.surface,
        builder: (_) => _Readings(
            initial: initial, scanDate: scanDate ?? CacheScope.todayKey()));

class _Readings extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final String scanDate;
  const _Readings({this.initial, required this.scanDate});
  @override
  State<_Readings> createState() => _ReadingsState();
}

class _ReadingsState extends State<_Readings> {
  final _form = GlobalKey<FormState>();
  late final _fat = TextEditingController(
      text: widget.initial?['bodyFatPct']?.toString() ?? '');
  late final _muscle = TextEditingController(
      text: widget.initial?['muscleMassKg']?.toString() ?? '');
  late String _source = widget.initial?['source'] as String? ?? 'smart_scale';
  late String _date =
      widget.initial?['recordedDate'] as String? ?? widget.scanDate;
  String? _error;
  double? _number(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
  @override
  void dispose() {
    _fat.dispose();
    _muscle.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final latest = DateTime.parse(widget.scanDate);
    final date = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: latest,
        initialDate: DateTime.parse(_date));
    if (date != null && mounted) {
      setState(() => _date = CacheScope.todayKey(date));
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    if (_fat.text.trim().isEmpty && _muscle.text.trim().isEmpty) {
      setState(() => _error = 'Add at least one reading.');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'source': _source,
      'recordedDate': _date,
      if (_fat.text.trim().isNotEmpty) 'bodyFatPct': _number(_fat.text),
      if (_muscle.text.trim().isNotEmpty) 'muscleMassKg': _number(_muscle.text)
    });
  }

  Widget _field(TextEditingController controller, String label, double min,
          double max) =>
      Padding(
          padding: const EdgeInsets.only(top: 14),
          child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: label),
              validator: (text) {
                if (text == null || text.trim().isEmpty) return null;
                final value = _number(text);
                return value == null ||
                        !value.isFinite ||
                        value < min ||
                        value > max
                    ? 'Enter a value between $min and $max.'
                    : null;
              }));
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 4, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
          key: _form,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FitnessText('Your composition readings',
                    style:
                        TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const FitnessText(
                    'Optional. Copy readings from your scale or report. They are shown separately from photo estimates.',
                    style: TextStyle(
                        fontSize: 13, height: 1.5, color: FitnessTheme.muted)),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'smart_scale',
                          label: FitnessText('Smart scale')),
                      ButtonSegment(
                          value: 'dexa', label: FitnessText('DEXA report'))
                    ],
                    selected: {
                      _source
                    },
                    onSelectionChanged: (value) =>
                        setState(() => _source = value.first)),
                _field(_fat, 'Body fat (%)', 2, 75),
                _field(_muscle, 'Skeletal muscle mass (kg)', 5, 150),
                const SizedBox(height: 10),
                const FitnessText(
                    'Use skeletal muscle mass only. Fat-free mass, lean mass and appendicular lean mass are different readings.',
                    style: TextStyle(
                        fontSize: 11, height: 1.5, color: FitnessTheme.muted)),
                TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_date)),
                if (_error != null)
                  FitnessText(_error!,
                      style: const TextStyle(color: FitnessTheme.coral)),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _save,
                        child: const FitnessText('Use these readings'))),
              ])));
}
