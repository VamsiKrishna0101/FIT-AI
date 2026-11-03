import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/motion.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/ds_motion.dart';
import '../models/progress_models.dart';

class ProgressDateFilter extends StatelessWidget {
  final String period;
  final DateTimeRange? custom;
  final String? rangeLabel;
  final bool compact;
  final double? controlWidth;
  final void Function(String, DateTimeRange?) onChanged;

  const ProgressDateFilter({
    super.key,
    required this.period,
    this.custom,
    this.rangeLabel,
    this.compact = false,
    this.controlWidth,
    required this.onChanged,
  });

  static const _options = {
    '4w': '4 weeks',
    '3m': '3 months',
    '1y': '1 year',
    'all': 'All time',
    'custom': 'Custom range',
  };

  String _currentLabel(BuildContext context) {
    if (period == 'custom' && custom != null) {
      final locale = Localizations.localeOf(context).toLanguageTag();
      final start = progressDate(
          custom!.start.toIso8601String().substring(0, 10), locale);
      final end =
          progressDate(custom!.end.toIso8601String().substring(0, 10), locale);
      return compact ? '$start–$end' : '$start – $end';
    }
    return fitnessText(context, _options[period] ?? _options['4w']!);
  }

  Future<void> _openPicker(BuildContext context) async {
    HapticFeedback.selectionClick();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
      backgroundColor: DSColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    fitnessText(context, 'Time range'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.3,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark,
                        size: 16, color: DSColors.muted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final entry in _options.entries) ...[
                Builder(builder: (itemCtx) {
                  final isSelected = entry.key == period;
                  return MotionPress(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(color: DSColors.borderHi, width: 0.7)
                            : null,
                      ),
                      child: ListTile(
                        tileColor: isSelected ? DSColors.bgRaised : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        title: Text(
                          fitnessText(context, entry.value),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : DSColors.silver,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(CupertinoIcons.checkmark_alt,
                                size: 18, color: DSColors.accent)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(entry.key),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        )),
      ),
    );

    if (chosen == null || !context.mounted) return;
    if (chosen != 'custom') {
      onChanged(chosen, null);
      return;
    }

    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: custom ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 27)),
            end: now,
          ),
      helpText: fitnessText(context, 'Custom range'),
      saveText: fitnessText(context, 'Apply'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: DSColors.accent,
            onPrimary: Colors.black,
            surface: DSColors.bgCard,
            onSurface: Colors.white,
          ),
          dialogTheme:
              const DialogThemeData(backgroundColor: DSColors.bgElevated),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged('custom', picked);
  }

  @override
  Widget build(BuildContext context) {
    final label = _currentLabel(context);

    final pill = MotionPress(
      child: GestureDetector(
        onTap: () => _openPicker(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DSColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DSColors.border, width: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DSColors.silver,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(CupertinoIcons.chevron_down,
                  size: 10, color: DSColors.muted),
            ],
          ),
        ),
      ),
    );

    if (compact || controlWidth != null) {
      return SizedBox(
        width: controlWidth,
        child: pill,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        pill,
        if (period != 'custom' && rangeLabel != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                rangeLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: DSColors.muted, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}
