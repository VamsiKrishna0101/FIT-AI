import '../../../core/components/content_transition.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/weekly_plan_repository.dart';

class WeeklyPlanHistoryView extends StatefulWidget {
  final WeeklyPlanRepository repository;

  const WeeklyPlanHistoryView({super.key, required this.repository});

  @override
  State<WeeklyPlanHistoryView> createState() => _WeeklyPlanHistoryViewState();
}

class _WeeklyPlanHistoryViewState extends State<WeeklyPlanHistoryView> {
  List<Map<String, dynamic>> _plans = [];
  String? _nextCursor;
  String? _error;
  String? _openingId;
  bool _loading = true;
  bool _loadingMore = false;
  int _requestNumber = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  String _message(Object error) {
    final data = error is DioException ? error.response?.data : null;
    return data is Map && data['error'] is String
        ? data['error'] as String
        : 'Couldn’t load your saved weeks. Please try again.';
  }

  Future<bool> _sameOwner(String? owner) async {
    final currentOwner = await CacheScope.userId();
    if (!mounted) return false;
    if (currentOwner != owner) {
      setState(() {
        _plans = [];
        _nextCursor = null;
        _loading = false;
        _loadingMore = false;
        _error = 'Your account changed. Reopen plan history.';
      });
      return false;
    }
    return true;
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore && !reset) return;
    final request = ++_requestNumber;
    final owner = await CacheScope.userId();
    if (!mounted || request != _requestNumber) return;
    setState(() {
      _loadingMore = !reset;
      _error = null;
    });

    try {
      final page =
          await widget.repository.history(cursor: reset ? null : _nextCursor);
      if (request != _requestNumber || !await _sameOwner(owner)) return;
      final items = (page['items'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      setState(() {
        _plans = reset ? items : [..._plans, ...items];
        _nextCursor = page['nextCursor'] as String?;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (request != _requestNumber || !await _sameOwner(owner)) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _openPlan(String id) async {
    if (_openingId != null) return;
    setState(() {
      _openingId = id;
      _error = null;
    });
    final owner = await CacheScope.userId();
    try {
      final plan = await widget.repository.savedPlan(id);
      if (!await _sameOwner(owner)) return;
      if (mounted) Navigator.of(context).pop(plan);
    } catch (error) {
      if (await _sameOwner(owner) && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        appBar: AppBar(
          title:
              const FitnessText('Plan history', style: TextStyle(fontSize: 17)),
          backgroundColor: FitnessTheme.canvas,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (!_loading && _plans.isEmpty && _error == null)
                    const SliverToBoxAdapter(
                        child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 44),
                      child: Column(children: [
                        Icon(CupertinoIcons.calendar,
                            size: 36, color: FitnessTheme.muted),
                        SizedBox(height: 20),
                        FitnessText('No saved weeks yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        SizedBox(height: 10),
                        FitnessText(
                            'Generate a weekly plan and it will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: FitnessTheme.muted,
                                fontSize: 13,
                                height: 1.5)),
                      ]),
                    )),
                  if (_loading)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                          child: LoadingPlaceholder(cards: 2)),
                    ),
                  SliverAnimatedOpacity(
                    opacity: _loading ? 0 : 1,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : ContentTransition.duration,
                    curve: Curves.easeOutCubic,
                    sliver: SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: _plans.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _planCard(_plans[index]),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: FitnessTheme.coral,
                                    fontSize: 13,
                                    height: 1.5)),
                            const SizedBox(height: 10),
                            TextButton(
                                onPressed: () => _load(reset: _plans.isEmpty),
                                child: const FitnessText('Try again')),
                          ] else if (_nextCursor != null)
                            OutlinedButton(
                              onPressed: _loadingMore ? null : () => _load(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: FitnessTheme.silver,
                                side:
                                    const BorderSide(color: FitnessTheme.line),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _loadingMore
                                  ? const CupertinoActivityIndicator()
                                  : const FitnessText('See older weeks'),
                            ),
                        ]),
                  )),
                ],
              ),
            )),
      ));

  Widget _planCard(Map<String, dynamic> plan) {
    final start = DateTime.tryParse(plan['weekStart'] as String? ?? '');
    final end =
        start == null ? null : DateTime(start.year, start.month, start.day + 6);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateRange = start == null || end == null
        ? 'Saved week'
        : '${DateFormat.MMMd(locale).format(start)} – ${DateFormat.yMMMd(locale).format(end)}';
    final label = plan['synthetic'] == true
        ? 'Test'
        : switch (plan['status']) {
            'ACTIVE' => 'Active',
            'ARCHIVED' => 'Archived',
            _ => 'Saved',
          };
    final trainingDays = plan['trainingDays'] as int? ?? 0;
    final opening = _openingId == plan['id'];
    return Material(
      color: FitnessTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FitnessTheme.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            _openingId != null ? null : () => _openPlan(plan['id'] as String),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(dateRange,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.3))),
                const SizedBox(width: 10),
                if (opening)
                  const CupertinoActivityIndicator()
                else
                  FitnessText(label,
                      style: const TextStyle(
                          color: FitnessTheme.silver, fontSize: 11)),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 4, children: [
                FitnessText(
                    '$trainingDays training ${trainingDays == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                        color: FitnessTheme.muted, fontSize: 12)),
                FitnessText(
                    plan['foodPlanIncluded'] == true
                        ? 'Food plan included'
                        : 'Food plan not included',
                    style: const TextStyle(
                        color: FitnessTheme.muted, fontSize: 12)),
              ]),
            ])),
      ),
    );
  }
}
