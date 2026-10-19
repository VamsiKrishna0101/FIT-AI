import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/progress_surface.dart';
import '../models/progress_models.dart';
import '../repositories/progress_repository.dart';
import 'progress_detail_view.dart';

class ProgressExercisesView extends StatefulWidget {
  final String period;
  final List<ProgressJson> muscles;
  final Map<String, dynamic> query;
  const ProgressExercisesView(
      {super.key,
      required this.period,
      required this.muscles,
      this.query = const {}});
  @override
  State<ProgressExercisesView> createState() => _ProgressExercisesViewState();
}

class _ProgressExercisesViewState extends State<ProgressExercisesView> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<ProgressJson> _items = [];
  List<String> _pins = [];
  String? _muscle, _cursor;
  bool _loading = true, _failed = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    LanguageManager.shared.addListener(_languageChanged);
    unawaited(_load());
  }

  void _languageChanged() {
    _debounce?.cancel();
    unawaited(_load());
  }

  @override
  void dispose() {
    LanguageManager.shared.removeListener(_languageChanged);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
      if (!more) {
        _items = [];
        _cursor = null;
      }
    });
    try {
      final data = await ProgressRepository.shared
          .load('/exercises', widget.period, query: {
        ...widget.query,
        'search': _search.text.trim(),
        if (_muscle != null) 'muscle': _muscle,
        if (more) 'cursor': _cursor,
      });
      final pins = await ProgressRepository.shared.pins();
      if (mounted && request == _request) {
        setState(() {
          _items = [
            ...(more ? _items : <ProgressJson>[]),
            ...progressRows(data['items'])
          ];
          _cursor = data['nextCursor'] as String?;
          _pins = pins;
        });
      }
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _pin(String id) async {
    await ProgressRepository.shared.pin(id);
    final pins = await ProgressRepository.shared.pins();
    if (mounted) setState(() => _pins = pins);
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: DSColors.bg,
          appBar: AppBar(
              backgroundColor: DSColors.bg,
              surfaceTintColor: Colors.transparent,
              title: Text(fitnessText(context, 'Exercise progress'),
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w600))),
          body: Column(children: [
            if (widget.query['dataset'] == 'preview')
              Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(fitnessText(context, 'Preview data'),
                      style:
                          const TextStyle(color: progressMuted, fontSize: 12))),
            Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: Column(children: [
                  TextField(
                      controller: _search,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: DSColors.bgCard,
                          hintText:
                              fitnessText(context, 'Search your exercises'),
                          prefixIcon:
                              const Icon(CupertinoIcons.search, size: 19)),
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce = Timer(
                            const Duration(milliseconds: 300), () => _load());
                      }),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _muscle ?? 'all',
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                      items: [
                        DropdownMenuItem(
                            value: 'all',
                            child: Text(fitnessText(context, 'All muscles'))),
                        ...widget.muscles.map((row) => DropdownMenuItem(
                            value: row['id'] as String,
                            child: Text(progressMuscleLabel(context, row),
                                style: const TextStyle(fontSize: 14))))
                      ],
                      onChanged: (value) {
                        _muscle = value == 'all' ? null : value;
                        _load();
                      }),
                ])),
            Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        if (_failed) {
                          return TextButton(
                              onPressed: () => _load(),
                              child: Text(fitnessText(context, 'Retry')));
                        }
                        if (_loading) {
                          return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: progressSilver, strokeWidth: 2)));
                        }
                        if (_items.isEmpty) {
                          return const ProgressEmpty(
                              'No logged exercises found');
                        }
                        if (_cursor != null) {
                          return TextButton(
                              onPressed: () => _load(more: true),
                              child: Text(fitnessText(context, 'Load more')));
                        }
                        return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                                fitnessText(context,
                                    'Pin up to three exercises to your overview.'),
                                style: const TextStyle(
                                    color: progressMuted,
                                    fontSize: 12,
                                    height: 1.4)));
                      }
                      final row = _items[index];
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ProgressSurface(
                              accent: progressCyan,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ProgressExerciseRow(
                                  exercise: row,
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => ProgressDetailView(
                                          title: row['name'] as String,
                                          path: '/exercises/${row['id']}',
                                          period: widget.period,
                                          kind: 'exercise',
                                          query: widget.query))),
                                  trailing: IconButton(
                                      onPressed: () =>
                                          _pin(row['id'] as String),
                                      tooltip:
                                          fitnessText(context, 'Pin exercise'),
                                      icon: Icon(
                                          _pins.contains(row['id'])
                                              ? CupertinoIcons.star_fill
                                              : CupertinoIcons.star,
                                          size: 19,
                                          color: _pins.contains(row['id'])
                                              ? progressSilver
                                              : progressMuted)))));
                    })),
          ])));
}
