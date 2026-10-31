import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'widgets/body_controls.dart';
import 'widgets/body_progress_style.dart';

class BodyHistoryView extends StatefulWidget {
  final FutureOr<void> Function(BodyAssessment) onRecord;
  final BodyAssessmentRepository? repository;
  const BodyHistoryView({super.key, required this.onRecord, this.repository});
  @override
  State<BodyHistoryView> createState() => _BodyHistoryViewState();
}

class _BodyHistoryViewState extends State<BodyHistoryView> {
  BodyAssessmentRepository get _repository =>
      widget.repository ?? BodyAssessmentRepository.shared;
  List<BodyAssessment> _records = [];
  int _page = 1, _total = 0, _pageSize = 12, _request = 0;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool refresh = false}) async {
    final request = ++_request, owner = await CacheScope.userId();
    if (!mounted || request != _request) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (refresh) await _repository.invalidate();
      final data =
          await _repository.history(page: _page, to: CacheScope.todayKey());
      if (!mounted ||
          request != _request ||
          await CacheScope.userId() != owner) {
        return;
      }
      setState(() {
        _records = (data['records'] as List)
            .map((e) =>
                BodyAssessment.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((entry) =>
                !entry.synthetic &&
                entry.status == 'SAVED' &&
                entry.metrics.values.any((metric) => [
                      'scale',
                      'smart_scale',
                      'tape',
                      'dexa',
                      'calipers'
                    ].contains(metric.source)))
            .toList();
        _total = (data['total'] as num).toInt();
        _pageSize = (data['pageSize'] as num).toInt();
        _loading = false;
      });
    } catch (error) {
      if (mounted &&
          request == _request &&
          await CacheScope.userId() == owner) {
        setState(() {
          _error = BodyAssessmentRepository.message(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _record(BodyAssessment entry) async {
    await widget.onRecord(entry);
    if (mounted) await _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        appBar: AppBar(
            title: const FitnessText('Measurement history',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        body: RefreshIndicator(
            onRefresh: () => _load(refresh: true),
            color: FitnessTheme.silver,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (_loading)
                  const Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(child: CupertinoActivityIndicator()))
                else if (_error != null)
                  FitnessCard(
                      child: Column(children: [
                    FitnessText(_error!,
                        style: const TextStyle(
                            fontSize: 13, color: FitnessTheme.muted)),
                    TextButton(
                        onPressed: _load, child: const FitnessText('Retry')),
                  ]))
                else if (_records.isEmpty)
                  const BodyProgressCard(
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Column(children: [
                            Icon(CupertinoIcons.resize,
                                size: 30, color: FitnessTheme.muted),
                            SizedBox(height: 16),
                            FitnessText('No measurements yet',
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w500)),
                          ])))
                else ...[
                  for (final entry in _records)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _record(entry),
                              borderRadius: BorderRadius.circular(24),
                              child: BodyProgressCard(
                                  child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(bodyDate(entry.recordedDate),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                          spacing: 14,
                                          runSpacing: 6,
                                          children: [
                                            for (final key in [
                                              'weightKg',
                                              'waistCm'
                                            ])
                                              if (entry.metrics[key]
                                                  case final metric?)
                                                if (!metric.isPhotoEstimate &&
                                                    metric.source != 'profile')
                                                  Text(
                                                      '${fitnessText(context, bodyMetricSpecs[key]!.label)} · ${metric.display(bodyMetricSpecs[key]!.unit)}',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: FitnessTheme
                                                              .muted)),
                                          ]),
                                    ])),
                                const SizedBox(width: 12),
                                const Icon(CupertinoIcons.chevron_right,
                                    size: 14, color: FitnessTheme.muted),
                              ])),
                            ))),
                  if (_total > _pageSize)
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              tooltip: fitnessText(context, 'Previous'),
                              onPressed: _page <= 1
                                  ? null
                                  : () {
                                      _page--;
                                      _load();
                                    },
                              icon: const Icon(CupertinoIcons.chevron_left)),
                          Text('$_page / ${(_total / _pageSize).ceil()}',
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted)),
                          IconButton(
                              tooltip: fitnessText(context, 'Next'),
                              onPressed: _page * _pageSize >= _total
                                  ? null
                                  : () {
                                      _page++;
                                      _load();
                                    },
                              icon: const Icon(CupertinoIcons.chevron_right)),
                        ]),
                ],
              ],
            )),
      ));
}
