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
import '../../../core/navigation/onboarding_page_route.dart';
import 'body_comparison_view.dart';

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
  List<BodyAssessment> _baselines = [];
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
        _baselines = (data['comparisonBaselines'] as List? ?? [])
            .whereType<Map>()
            .map((e) => BodyAssessment.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => !e.synthetic && e.hasPhotoAssessment)
            .toList();
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
    final comparisonRecords = [..._records, ..._baselines];
    final comparable = _records
        .where((entry) => comparisonRecords.any(entry.canComparePhotosWith))
        .firstOrNull;
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
            const FitnessText('Your progress. In focus.',
                style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.5)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: FitnessText(
                      '$_total saved ${_total == 1 ? 'scan' : 'scans'}',
                      style: const TextStyle(
                          fontSize: 12, color: FitnessTheme.muted))),
              PopupMenuButton<String>(
                  enabled: !_loading,
                  initialValue: _period,
                  onSelected: _periodChanged,
                  itemBuilder: (_) => [
                        for (final period in [
                          'All scans',
                          'This week',
                          'Last week',
                          'Last month',
                          'Custom dates'
                        ])
                          PopupMenuItem(
                              value: period, child: FitnessText(period))
                      ],
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        FitnessText(_period,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 7),
                        const Icon(CupertinoIcons.chevron_down, size: 12)
                      ])))
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
              if (comparable != null)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      AppPageRoute<void>(
                          page: BodyComparisonView(
                              current: comparable,
                              baselines: comparisonRecords
                                  .where(comparable.canComparePhotosWith)
                                  .toList(),
                              repository: repository))),
                  icon: const Icon(CupertinoIcons.arrow_left_right, size: 14),
                  label: const FitnessText('Compare',
                      style: TextStyle(fontSize: 11)),
                ),
            ]),
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
              LayoutBuilder(
                  builder: (context, constraints) => GridView.count(
                      crossAxisCount: constraints.maxWidth < 270 ||
                              MediaQuery.textScalerOf(context).scale(14) > 21
                          ? 1
                          : 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: .70,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [for (final entry in _records) _scan(entry)])),
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

  Widget _scan(BodyAssessment entry) {
    final photo = entry.photos.where((p) => p.view == 'front').firstOrNull ??
        entry.photos.firstOrNull;
    final score = entry.dashboard.score;
    return MotionPress(
        child: Semantics(
            button: true,
            label: 'Scan ${bodyDate(entry.recordedDate)}',
            child: Material(
                color: FitnessTheme.surface,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                    key: ValueKey('scan-history-${entry.id}'),
                    onTap: () => widget.onRecord(entry),
                    child: Stack(fit: StackFit.expand, children: [
                      if (photo != null)
                        PrivateBodyPhoto(
                            photo: photo, fit: BoxFit.cover, cacheWidth: 640)
                      else
                        const Center(
                            child: Icon(CupertinoIcons.doc_text,
                                size: 34, color: FitnessTheme.muted)),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            Colors.transparent,
                            Color(0x33000000),
                            Color(0xF5000000)
                          ],
                                  stops: [
                            0,
                            .45,
                            1
                          ]))),
                      Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .55),
                                  borderRadius: BorderRadius.circular(7)),
                              child: const Icon(CupertinoIcons.lock_fill,
                                  size: 11, color: Color(0xFFC1D7F6)))),
                      Positioned(
                          left: 14,
                          right: 12,
                          bottom: 14,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (score != null)
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('${score.round()}',
                                            style: const TextStyle(
                                                fontSize: 31,
                                                height: 1.1,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white)),
                                        const SizedBox(width: 4),
                                        const Text('/100',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF9EB7DA)))
                                      ]),
                                if (score != null)
                                  const Padding(
                                      padding: EdgeInsets.only(bottom: 9),
                                      child: FitnessText('VISUAL INDEX',
                                          style: TextStyle(
                                              fontSize: 8,
                                              letterSpacing: 1,
                                              color: Color(0xFF9EB7DA)))),
                                Text(bodyDate(entry.recordedDate),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 5),
                                FitnessText(
                                    photo == null
                                        ? 'Report only'
                                        : '${entry.photos.length} ${entry.photos.length == 1 ? 'view' : 'views'}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFADB8C8))),
                              ])),
                    ])))));
  }
}
