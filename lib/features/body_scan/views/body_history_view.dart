import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/motion.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'widgets/body_controls.dart';
import 'widgets/private_body_photo.dart';

class BodyHistoryView extends StatefulWidget {
  final ValueChanged<BodyAssessment> onRecord;
  final BodyAssessmentRepository? repository;

  const BodyHistoryView({
    super.key,
    required this.onRecord,
    this.repository,
  });

  @override
  State<BodyHistoryView> createState() => _BodyHistoryViewState();
}

class _BodyHistoryViewState extends State<BodyHistoryView> {
  BodyAssessmentRepository get repository =>
      widget.repository ?? BodyAssessmentRepository.shared;
  List<BodyAssessment> _records = [];
  String _period = 'All scans';
  DateTimeRange? _range;
  bool _loading = true;
  String? _error;
  int _page = 1, _total = 0, _pageSize = 12, _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final request = ++_request;
    final owner = await CacheScope.userId();
    if (!mounted || request != _request) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (refresh) await repository.invalidate();
      final data = await repository.history(
        from: _range == null ? null : CacheScope.todayKey(_range!.start),
        to: CacheScope.todayKey(_range?.end ?? DateTime.now()),
        page: _page,
      );
      final currentOwner = await CacheScope.userId();
      if (!mounted || request != _request || currentOwner != owner) return;
      setState(() {
        _records = (data['records'] as List)
            .map((entry) => BodyAssessment.fromJson(
                Map<String, dynamic>.from(entry as Map)))
            .where((entry) => !entry.synthetic && entry.hasPhotoAssessment)
            .toList();
        _total = (data['total'] as num).toInt();
        _pageSize = (data['pageSize'] as num).toInt();
        _loading = false;
      });
    } catch (error) {
      if (!mounted ||
          request != _request ||
          await CacheScope.userId() != owner) {
        return;
      }
      setState(() {
        _error = BodyAssessmentRepository.message(error);
        _loading = false;
      });
    }
  }

  Future<void> _periodChanged(String period) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange? range;
    if (period == 'Custom dates') {
      range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: today,
        initialDateRange: _range,
      );
      if (!mounted || range == null) return;
    } else if (period == 'This week') {
      range = DateTimeRange(
          start:
              DateTime(today.year, today.month, today.day - today.weekday + 1),
          end: today);
    } else if (period == 'Last week') {
      final monday =
          DateTime(today.year, today.month, today.day - today.weekday + 1);
      range = DateTimeRange(
          start: DateTime(monday.year, monday.month, monday.day - 7),
          end: DateTime(monday.year, monday.month, monday.day - 1));
    } else if (period == 'Last month') {
      range = DateTimeRange(
          start: DateTime(today.year, today.month - 1),
          end: DateTime(today.year, today.month, 0));
    }
    setState(() {
      _period = period;
      _range = range;
      _page = 1;
      _records = [];
    });
    await _load();
  }

  void _pageChanged(int page) {
    setState(() {
      _page = page;
      _records = [];
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final pages = (_total / _pageSize).ceil();
    return FitnessTheme(
        child: Scaffold(
      backgroundColor: FitnessTheme.canvas,
      appBar: AppBar(
        title: const FitnessText('Scan history',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        color: FitnessTheme.silver,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const FitnessText('Your scans, over time.',
                style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.5)),
            const SizedBox(height: 18),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final period in [
                'All scans',
                'This week',
                'Last week',
                'Last month',
                'Custom dates'
              ])
                ChoiceChip(
                  label: FitnessText(period,
                      style: TextStyle(
                          fontSize: 11,
                          color: _period == period
                              ? FitnessTheme.canvas
                              : FitnessTheme.silver)),
                  selectedColor: FitnessTheme.silver,
                  backgroundColor: FitnessTheme.surface,
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: FitnessTheme.line),
                  selected: _period == period,
                  showCheckmark: false,
                  onSelected: _loading ? null : (_) => _periodChanged(period),
                ),
            ]),
            if (_range != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                    '${DateFormat.yMMMd(locale).format(_range!.start)} – ${DateFormat.yMMMd(locale).format(_range!.end)}',
                    style: const TextStyle(
                        fontSize: 11, color: FitnessTheme.muted)),
              ),
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(
                  child: FitnessText('Saved scans',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500))),
              Tooltip(
                message: 'Coming soon',
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(CupertinoIcons.arrow_left_right, size: 14),
                  label: const FitnessText('Compare',
                      style: TextStyle(fontSize: 11)),
                ),
              ),
            ]),
            const Align(
                alignment: Alignment.centerRight,
                child: FitnessText('Comparison coming soon',
                    style: TextStyle(fontSize: 10, color: FitnessTheme.muted))),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CupertinoActivityIndicator()))
            else if (_error != null)
              FitnessCard(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FitnessText(_error!, style: const TextStyle(fontSize: 12)),
                  TextButton(
                      onPressed: _load, child: const FitnessText('Retry')),
                ],
              ))
            else if (_records.isEmpty)
              FitnessCard(
                  child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(children: [
                  const Icon(CupertinoIcons.camera,
                      size: 26, color: FitnessTheme.muted),
                  const SizedBox(height: 14),
                  FitnessText(
                      _period == 'All scans'
                          ? 'No saved scans yet.'
                          : 'No scans in this date range.',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 7),
                  const FitnessText('Saved photo assessments will appear here.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: FitnessTheme.muted)),
                ]),
              ))
            else ...[
              for (final entry in _records)
                Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _scan(entry)),
              if (pages > 1)
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          tooltip: fitnessText(context, 'Previous'),
                          onPressed:
                              _page > 1 ? () => _pageChanged(_page - 1) : null,
                          icon: const Icon(CupertinoIcons.chevron_left,
                              size: 17)),
                      Text('$_page / $pages',
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.muted)),
                      IconButton(
                          tooltip: fitnessText(context, 'Next'),
                          onPressed: _page < pages
                              ? () => _pageChanged(_page + 1)
                              : null,
                          icon: const Icon(CupertinoIcons.chevron_right,
                              size: 17)),
                    ]),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _scan(BodyAssessment entry) => MotionPress(
        child: FitnessCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onTap: () => widget.onRecord(entry),
                leading: SizedBox(
                    width: 44,
                    height: 54,
                    child: entry.photos.isNotEmpty
                        ? PrivateBodyPhoto(
                            photo: entry.photos.first, fit: BoxFit.cover)
                        : Container(
                            decoration: BoxDecoration(
                                color: FitnessTheme.canvas,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(CupertinoIcons.doc_text,
                                size: 19, color: FitnessTheme.muted))),
                title: Text(bodyDate(entry.recordedDate),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: FitnessText(
                        entry.photos.isEmpty
                            ? 'Report only · Photos not saved'
                            : 'Private photos saved',
                        style: const TextStyle(
                            fontSize: 11, color: FitnessTheme.muted))),
                trailing: const Icon(CupertinoIcons.chevron_right,
                    size: 12, color: FitnessTheme.muted),
              ),
            )),
      );
}
