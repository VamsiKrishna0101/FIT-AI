import 'dart:async';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../planner/views/weekly_plan_view.dart';
import '../../subscription/subscription_service.dart';
import '../../subscription/subscription_view.dart';
import '../../subscription/subscription_pricing_view.dart';
import '../../subscription/trial_access_hero.dart';
import '../data/starter_plan_repository.dart';
import '../components/starter_muscle_preview.dart';
import 'training_preferences_view.dart';

class StarterOnboardingGate extends StatefulWidget {
  final Widget child;
  final StarterPlanRepository? repository;
  const StarterOnboardingGate(
      {super.key, required this.child, this.repository});
  @override
  State<StarterOnboardingGate> createState() => _StarterOnboardingGateState();
}

class _StarterOnboardingGateState extends State<StarterOnboardingGate> {
  late final _repository = widget.repository ?? StarterPlanRepository();
  bool _loading = true, _offer = false;
  Map<String, dynamic>? _run;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final owner = await CacheScope.userId();
    try {
      final data = await _repository.current();
      final currentOwner = await CacheScope.userId();
      if (!mounted || owner != currentOwner) return;
      final run = data['run'] is Map
          ? Map<String, dynamic>.from(data['run'] as Map)
          : null;
      setState(() {
        _run = run;
        _offer = data['eligible'] == true ||
            (data['hasAccess'] == true &&
                run != null &&
                (run['plan'] is! Map ||
                    (run['plan'] as Map)['status'] == 'DRAFT'));
        _loading = false;
      });
    } catch (_) {
      // Existing subscription access still controls the app if preview setup is offline.
      if (mounted) setState(() => _loading = false);
    }
  }

  void _finished(String? id) {
    setState(() => _offer = false);
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
              AppPageRoute<void>(page: WeeklyPlanView(initialPlanId: id)));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => _loading
      ? const Scaffold(
          body:
              Center(child: CircularProgressIndicator(color: DSColors.silver)))
      : _offer
          ? StarterPlanView(
              repository: _repository, initialRun: _run, onComplete: _finished)
          : widget.child;
}

class StarterPlanView extends StatefulWidget {
  final StarterPlanRepository? repository;
  final SubscriptionService? subscription;
  final Map<String, dynamic>? initialRun;
  final ValueChanged<String?> onComplete;
  const StarterPlanView(
      {super.key,
      this.repository,
      this.subscription,
      this.initialRun,
      required this.onComplete});
  @override
  State<StarterPlanView> createState() => _StarterPlanViewState();
}

class _StarterPlanViewState extends State<StarterPlanView>
    with WidgetsBindingObserver {
  late final _repo = widget.repository ?? StarterPlanRepository();
  late final _subscription = widget.subscription ?? SubscriptionService.shared;
  Map<String, dynamic>? _run;
  String? _error, _owner;
  Timer? _timer;
  bool _busy = false, _polling = false, _foreground = true;
  bool get _ready => _run?['status'] == 'COMPLETED' && _run?['plan'] is Map;
  bool get _failed => _run?['status'] == 'FAILED';
  Map<String, dynamic>? get _preview =>
      _ready && (_run!['plan'] as Map)['preview'] is Map
          ? Map<String, dynamic>.from((_run!['plan'] as Map)['preview'] as Map)
          : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _begin();
  }

  Future<bool> _sameOwner() async {
    final owner = await CacheScope.userId();
    final same = mounted && _owner == owner;
    if (!same) _timer?.cancel();
    return same;
  }

  String _message(Object error) {
    if (error is StateError) return error.message.toString();
    final data = error is DioException ? error.response?.data : null;
    return data is Map && data['error'] is String
        ? data['error'] as String
        : 'Could not prepare your plan. Your answers are saved. Please try again.';
  }

  Future<void> _begin({bool retry = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _timer?.cancel();
    _owner = await CacheScope.userId();
    if (!mounted) return;
    try {
      final run = !retry && widget.initialRun != null
          ? widget.initialRun!
          : await _repo.start();
      if (!await _sameOwner()) return;
      setState(() => _run = run);
      await _subscription.refresh();
      _schedule();
    } catch (error) {
      if (await _sameOwner()) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!_ready && !_failed && _foreground && _run != null) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    }
  }

  Future<void> _poll() async {
    if (_polling || !_foreground || _run == null) return;
    _polling = true;
    try {
      final run = await _repo.run(_run!['id'] as String);
      if (!await _sameOwner()) return;
      setState(() {
        _run = run;
        _error = null;
      });
      if (_ready || _failed) _timer?.cancel();
    } catch (error) {
      if (await _sameOwner()) setState(() => _error = _message(error));
    } finally {
      _polling = false;
    }
  }

  Future<void> _unlock() async {
    if (_busy || !_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _subscription.refresh();
      if (!await _sameOwner()) return;
      final id = (_run!['plan'] as Map)['id'] as String;
      if (_subscription.access?.trialAvailable == true) {
        await _repo.prepareUnlock(id);
        if (!await _sameOwner()) return;
        await _subscription.startTrial();
      }
      if (!await _sameOwner()) return;
      if (_subscription.access?.hasAccess != true) {
        if (_subscription.access?.trialAvailable == true ||
            _subscription.error != null) {
          throw StateError(_subscription.error ??
              'Could not start your trial. Please try again.');
        }
        if (mounted) {
          await Navigator.of(context).push(AppPageRoute<void>(
              page: SubscriptionView(service: _subscription)));
        }
        return;
      }
      await _repo.activate(id);
      if (await _sameOwner()) widget.onComplete(id);
    } catch (error) {
      if (await _sameOwner()) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    await Navigator.of(context).push(AppPageRoute<void>(
        page: const TrainingPreferencesView(editProfile: true)));
    if (mounted) _begin(retry: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _poll();
      _schedule();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _stage => switch (_run?['stage']) {
        'specialists' => 'Choosing exercises for your equipment',
        'workout_prescriptions' => 'Balancing your training week',
        'nutrition' => 'Preparing your nutrition guidance',
        'validation' || 'saving' => 'Checking and saving your plan',
        _ => 'Reviewing your confirmed answers',
      };
  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        appBar: AppBar(
            title: const FitnessText('Your starting plan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            actions: [
              TextButton(
                  onPressed: _busy ? null : () => widget.onComplete(null),
                  child: const FitnessText('Not now'))
            ]),
        body: SafeArea(
            child: Column(children: [
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                if (_ready && _preview != null) ...[
                  const FitnessText('Your week is ready',
                      style: TextStyle(
                          fontSize: 34,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1.3)),
                  const SizedBox(height: 10),
                  const FitnessText('Your plan, built around you.',
                      style: TextStyle(
                          fontSize: 13, height: 1.4, color: Color(0xFF9AA3AE))),
                  const SizedBox(height: 22),
                  TrialAccessHero(
                      days: _subscription.access?.state == 'trial'
                          ? _subscription.access!.daysRemaining
                          : 14),
                  const SizedBox(height: 26),
                  StarterPlanPreview(preview: _preview!),
                ] else ...[
                  const SizedBox(height: 28),
                  Icon(
                      _failed
                          ? Icons.tune_rounded
                          : Icons.auto_awesome_outlined,
                      color: DSColors.silver,
                      size: 36),
                  const SizedBox(height: 20),
                  FitnessText(
                      _failed
                          ? 'Your plan needs a little more information'
                          : 'Building your first week',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          height: 1.2)),
                  const SizedBox(height: 20),
                  if (!_failed && _error == null) ...[
                    const Center(
                        child: SizedBox(
                            width: 42,
                            height: 42,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: DSColors.silver))),
                    const SizedBox(height: 20),
                    Semantics(
                        liveRegion: true,
                        child: FitnessText(_stage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: FitnessTheme.muted))),
                  ],
                  if (_failed) ...[
                    const SizedBox(height: 10),
                    const FitnessText(
                        'Review your equipment and movement notes, then try again.',
                        textAlign: TextAlign.center),
                    TextButton(
                        onPressed: _busy ? null : _review,
                        child: const FitnessText('Review preferences')),
                  ],
                ],
              ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(children: [
                if (_error != null) ...[
                  Semantics(
                      liveRegion: true,
                      child: FitnessText(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.coral))),
                  if (_ready)
                    TextButton(
                        onPressed: _busy ? null : _review,
                        child: const FitnessText('Review preferences')),
                  const SizedBox(height: 8),
                ],
                if (_ready || _failed || _error != null)
                  LiquidChromeButton(
                      title: _ready
                          ? (_subscription.access?.hasAccess == true
                              ? 'Open my full plan'
                              : 'Start my 14-day trial')
                          : 'Try again',
                      isLoading: _busy,
                      onPressed: _busy
                          ? null
                          : _ready
                              ? _unlock
                              : () => _begin(retry: true)),
                if (_ready) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Expanded(
                        child: FitnessText(
                            'No payment details. No automatic charge.',
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.4,
                                color: FitnessTheme.muted))),
                    const SizedBox(width: 10),
                    TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).push(
                                AppPageRoute<void>(
                                    page: SubscriptionPricingView(
                                        service: _subscription))),
                        child: const FitnessText('See pricing',
                            style: TextStyle(fontSize: 11))),
                  ]),
                ],
              ])),
        ])),
      ));
}

class StarterPlanPreview extends StatelessWidget {
  final Map<String, dynamic> preview;
  const StarterPlanPreview({super.key, required this.preview});
  @override
  Widget build(BuildContext context) {
    if ((preview['muscleGroups'] as List?)?.isNotEmpty == true) {
      return StarterMusclePreview(preview: preview);
    }
    final days = (preview['workouts'] as List? ?? []).whereType<Map>().toList();
    final first = preview['firstWorkout'] as Map?;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (preview['source'] == 'rules') ...[
        const FitnessText('Rules-based starter plan',
            style: TextStyle(
                fontSize: 12,
                color: FitnessTheme.silver,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        const FitnessText(
            'AI planning is unavailable. This plan uses your confirmed setup and conservative training rules.',
            style: TextStyle(
                fontSize: 12, color: FitnessTheme.muted, height: 1.4)),
        const SizedBox(height: 14),
      ],
      FitnessCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FitnessText('Your week',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        for (final day in days)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 64,
                    child: Text(
                        DateFormat.E(locale)
                            .format(DateTime.parse(day['date'] as String)),
                        style: const TextStyle(
                            fontSize: 12, color: FitnessTheme.muted))),
                Expanded(
                    child: FitnessText(
                        day['restDay'] == true ? 'Rest day' : '${day['name']}',
                        style: const TextStyle(fontSize: 13))),
              ])),
      ])),
      if (first != null) ...[
        const SizedBox(height: 12),
        FitnessCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FitnessText('Your first workout',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final exercise
              in (first['exercises'] as List? ?? []).whereType<Map>())
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FitnessText('${exercise['name']}',
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 4),
                      FitnessText(
                          '${exercise['sets']} × ${exercise['repsMin'] == exercise['repsMax'] ? exercise['repsMax'] : '${exercise['repsMin']}–${exercise['repsMax']}'} reps',
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.muted)),
                    ])),
        ])),
      ],
      const SizedBox(height: 12),
      FitnessCard(
          child: Stack(alignment: Alignment.center, children: [
        ExcludeSemantics(
            child: IgnorePointer(
                child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Column(children: [
            for (var index = 0; index < 3; index++)
              Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(vertical: 7),
                  width: 170.0 - index * 20,
                  decoration: BoxDecoration(
                      color: DSColors.bgRaised,
                      borderRadius: BorderRadius.circular(5))),
          ]),
        ))),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_outline_rounded, size: 17, color: DSColors.silver),
          SizedBox(width: 8),
          Flexible(
              child: FitnessText('Unlock your complete plan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ]),
      ])),
    ]);
  }
}
