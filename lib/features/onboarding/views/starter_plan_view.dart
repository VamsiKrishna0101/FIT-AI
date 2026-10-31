import '../../body_scan/models/body_measurement_baseline.dart';
import '../../body_scan/views/body_entry_view.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/branding/setcraft_launch_screen.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../planner/views/weekly_plan_view.dart';
import '../../subscription/subscription_service.dart';
import '../../subscription/subscription_view.dart';
import '../data/starter_plan_repository.dart';
import '../components/starter_plan_reveal.dart';
import '../../planner/views/widgets/plan_particle_orb.dart';
import '../../profile/repositories/settings_repository.dart';
import '../data/discovery_repository.dart';
import 'discovery_onboarding_gate.dart';
import 'training_preferences_view.dart';
import 'equipment_selection_view.dart';

class StarterOnboardingGate extends StatefulWidget {
  final Widget child;
  final StarterPlanRepository? repository;
  final DiscoveryRepository discoveryRepository;
  final StarterEntryPreparation? preparation;
  const StarterOnboardingGate(
      {super.key,
      required this.child,
      this.repository,
      this.discoveryRepository = const DiscoveryRepository(),
      this.preparation});
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
    final prepared = widget.preparation;
    if (prepared != null) {
      _apply(prepared.data);
    } else {
      _load();
    }
  }

  void _apply(Map<String, dynamic>? data) {
    _run = data?['run'] is Map
        ? Map<String, dynamic>.from(data!['run'] as Map)
        : null;
    _offer = StarterEntryPreparation.shouldOffer(data);
    _loading = false;
  }

  Future<void> _load() async {
    final owner = await CacheScope.userId();
    try {
      final data = await _repository.current();
      final currentOwner = await CacheScope.userId();
      if (!mounted || owner != currentOwner) return;
      setState(() => _apply(data));
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
          Navigator.of(context).push(AppPageRoute<void>(
              page: WeeklyPlanView(initialPlanId: id, fromOnboarding: true)));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => _loading
      ? const SetcraftLaunchScreen()
      : _offer
          ? DiscoveryOnboardingGate(
              repository: widget.discoveryRepository,
              preparation: widget.preparation?.discovery,
              child: StarterPlanView(
                  repository: _repository,
                  initialRun: _run,
                  onComplete: _finished))
          : widget.child;
}

class StarterPlanView extends StatefulWidget {
  final StarterPlanRepository? repository;
  final SubscriptionService? subscription;
  final Map<String, dynamic>? initialRun;
  final ValueChanged<String?> onComplete;
  final Future<Map<String, dynamic>> Function()? profileLoader;
  const StarterPlanView(
      {super.key,
      this.repository,
      this.subscription,
      this.initialRun,
      this.profileLoader,
      required this.onComplete});
  @override
  State<StarterPlanView> createState() => _StarterPlanViewState();
}

class _StarterPlanViewState extends State<StarterPlanView>
    with WidgetsBindingObserver {
  late final _repo = widget.repository ?? StarterPlanRepository();
  late final _subscription = widget.subscription ?? SubscriptionService.shared;
  Map<String, dynamic>? _run;
  Map<String, dynamic>? _profile;
  String? _error, _owner;
  String? _errorCode, _measurementError;
  Timer? _timer;
  bool _busy = false, _polling = false, _foreground = true;
  bool _refreshingPlan = false, _unlockAfterRefresh = false;
  static const _refreshableCodes = {
    'STALE_PLAN',
    'WORKFLOW_UPDATED',
    'CATALOG_CHANGED',
    'PAST_PLAN',
    'INVALID_WEEK',
    'NOT_FOUND',
  };
  bool get _needsMeasurements =>
      _errorCode == 'MEASUREMENTS_REQUIRED' ||
      _failureCode == 'MEASUREMENTS_REQUIRED';
  bool get _ready => _run?['status'] == 'COMPLETED' && _run?['plan'] is Map;
  bool get _failed => _run?['status'] == 'FAILED';
  String? get _failureCode => _run?['errorCode'] as String?;
  bool get _equipmentIssue => _failed && _failureCode == 'CATALOG_GAP';
  bool get _movementIssue =>
      _failed && _failureCode == 'STARTER_REVIEW_REQUIRED';
  bool get _canRetry => !_failed || _run?['canRetry'] != false;
  String get _failureMessage => _equipmentIssue
      ? 'We could not match a complete week to your equipment. Check what you have available.'
      : _movementIssue
          ? 'We could not match exercises to your movement notes. Review them if anything has changed.'
          : _canRetry
              ? 'Your answers are saved. You do not need to fill them in again.'
              : 'Your answers are saved. Planning is unavailable right now.';
  Map<String, dynamic>? get _preview =>
      _ready && (_run!['plan'] as Map)['preview'] is Map
          ? Map<String, dynamic>.from((_run!['plan'] as Map)['preview'] as Map)
          : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _begin();
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final owner = await CacheScope.userId();
    try {
      final profile = await (widget.profileLoader?.call() ??
          SettingsRepository().profile());
      if (mounted && owner == await CacheScope.userId()) {
        setState(() => _profile = profile);
      }
    } catch (_) {
      // Public plan data remains useful when cached profile details are offline.
      if (mounted && owner == await CacheScope.userId()) {
        setState(() => _profile = {});
      }
    }
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
      _errorCode = null;
      _refreshingPlan = false;
      _unlockAfterRefresh = false;
      if (retry) _run = null;
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
      if (await _sameOwner()) {
        setState(() {
          _error = _message(error);
          final details = error is DioException ? error.response?.data : null;
          _errorCode = details is Map ? details['code'] as String? : null;
        });
      }
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
        if (_failed) {
          _refreshingPlan = false;
          _unlockAfterRefresh = false;
        }
      });
      if (_ready || _failed) _timer?.cancel();
    } catch (error) {
      if (await _sameOwner()) {
        setState(() {
          _error = _message(error);
          final details = error is DioException ? error.response?.data : null;
          _errorCode = details is Map ? details['code'] as String? : null;
        });
      }
    } finally {
      _polling = false;
    }
    await _resumeUnlockIfReady();
  }

  Future<void> _refreshForUnlock() async {
    _timer?.cancel();
    setState(() {
      _run = null;
      _error = null;
      _errorCode = null;
      _refreshingPlan = true;
      _unlockAfterRefresh = true;
    });
    try {
      final run = await _repo.start();
      if (!await _sameOwner()) return;
      setState(() {
        _run = run;
        if (_failed) {
          _refreshingPlan = false;
          _unlockAfterRefresh = false;
        }
      });
      _schedule();
    } catch (error) {
      if (!await _sameOwner()) return;
      setState(() {
        _refreshingPlan = false;
        _unlockAfterRefresh = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _resumeUnlockIfReady() async {
    if (!_unlockAfterRefresh || !_ready || _busy || !_foreground) return;
    if (!await _sameOwner()) return;
    // Lifecycle and polling can both complete together. Consume the intent once.
    if (!_unlockAfterRefresh || _busy || !_foreground) return;
    setState(() {
      _unlockAfterRefresh = false;
      _refreshingPlan = false;
    });
    await _unlock(allowRefresh: false);
  }

  Future<void> _unlock({bool allowRefresh = true}) async {
    if (_busy || !_ready) return;
    setState(() {
      _busy = true;
      _error = null;
      _errorCode = null;
    });
    try {
      await _subscription.refresh();
      if (!await _sameOwner()) return;
      final id = (_run!['plan'] as Map)['id'] as String;
      // Validate before showing checkout, and again on the server at activation.
      await _repo.prepareUnlock(id);
      if (!await _sameOwner() || !_foreground) return;
      if (_subscription.access?.hasAccess != true) {
        if (mounted) {
          await Navigator.of(context).push(AppPageRoute<void>(
              page: SubscriptionView(
                  service: _subscription,
                  onContinue: () {
                    if (_subscription.access?.hasAccess == true) {
                      Navigator.pop(context);
                    }
                  })));
        }
      }
      if (!await _sameOwner() || _subscription.access?.hasAccess != true) {
        return;
      }
      await _repo.activate(id);
      if (await _sameOwner()) widget.onComplete(id);
    } catch (error) {
      if (await _sameOwner()) {
        final details = error is DioException ? error.response?.data : null;
        final code = details is Map ? details['code'] as String? : null;
        if (allowRefresh && _refreshableCodes.contains(code)) {
          await _refreshForUnlock();
        } else {
          setState(() {
            _error = _refreshableCodes.contains(code)
                ? 'Your setup changed again. Refresh your plan to continue.'
                : _message(error);
            _errorCode = code;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _resumeUnlockIfReady();
  }

  Future<void> _completeMeasurements() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _measurementError = null;
    });
    var saved = false;
    try {
      final body = await _repo.bodyOverview();
      if (!await _sameOwner()) return;
      if (!mounted) return;
      final route = AppPageRoute<bool>(
          page: BodyEntryView(
              baseline: BodyMeasurementBaseline(body), requireBaseline: true));
      saved = await Navigator.of(context).push(route) == true;
      await route.completed;
    } catch (error) {
      if (mounted) setState(() => _measurementError = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (saved && await _sameOwner()) await _begin(retry: true);
  }

  Future<void> _review() async {
    await Navigator.of(context).push(AppPageRoute<void>(
        page: _equipmentIssue
            ? const EquipmentSelectionView(editProfile: true)
            : const TrainingPreferencesView(editProfile: true)));
    if (mounted) _begin(retry: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _foreground = state == AppLifecycleState.resumed);
    if (_foreground) {
      _poll();
      _schedule();
      unawaited(_resumeUnlockIfReady());
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
        'retrying' => 'Reconnecting and retrying automatically',
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
            centerTitle: true,
            title: const FitnessText('Your plan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        body: SafeArea(
            child: Column(children: [
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                if (_needsMeasurements) ...[
                  const SizedBox(height: 44),
                  const Icon(Icons.straighten_rounded,
                      size: 40, color: FitnessTheme.silver),
                  const SizedBox(height: 24),
                  const FitnessText('Complete your measurements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.7)),
                  const SizedBox(height: 12),
                  const FitnessText(
                      'Add your measurements before creating your plan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: FitnessTheme.muted,
                          height: 1.5)),
                ] else if (_ready && _preview != null) ...[
                  StarterPlanPreview(
                      preview: _preview!,
                      profile: _profile,
                      locked: _subscription.access?.hasAccess != true),
                ] else ...[
                  const SizedBox(height: 28),
                  FitnessText(
                      _failed || _error != null
                          ? 'We could not finish your plan'
                          : _refreshingPlan
                              ? 'Updating your plan…'
                              : 'Building your first week',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          height: 1.2)),
                  const SizedBox(height: 20),
                  if (!_failed && _error == null) ...[
                    Center(
                        child: SizedBox(
                            width: 220,
                            child: PlanParticleOrb(
                                percent: ((_run?['progress']
                                            as Map?)?['percent'] as num? ??
                                        0)
                                    .toInt()
                                    .clamp(0, 99),
                                animating: _foreground && !_failed))),
                    const SizedBox(height: 20),
                    Semantics(
                        liveRegion: true,
                        child: FitnessText(_stage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: FitnessTheme.muted))),
                  ],
                  if (_failed) ...[
                    const SizedBox(height: 10),
                    FitnessText(_failureMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: FitnessTheme.muted, height: 1.5)),
                    if (_equipmentIssue || _movementIssue)
                      TextButton(
                          onPressed: _busy ? null : _review,
                          child: FitnessText(_equipmentIssue
                              ? 'Review equipment'
                              : 'Review movement notes')),
                  ],
                ],
              ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(children: [
                if (_measurementError != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FitnessText(_measurementError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.coral))),
                if (_error != null && !_needsMeasurements) ...[
                  Semantics(
                      liveRegion: true,
                      child: FitnessText(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: FitnessTheme.coral))),
                  if (_ready && _refreshableCodes.contains(_errorCode))
                    TextButton(
                        onPressed: _busy ? null : () => _begin(retry: true),
                        child: const FitnessText('Refresh my plan')),
                  const SizedBox(height: 8),
                ],
                if (_ready || _failed || _error != null || _refreshingPlan)
                  LiquidChromeButton(
                      pill: true,
                      solid: true,
                      showArrow: false,
                      title: _needsMeasurements
                          ? 'Add measurements'
                          : _ready
                              ? (_subscription.access?.hasAccess == true
                                  ? 'Open my full plan'
                                  : 'Unlock my plan')
                              : _canRetry
                                  ? 'Try again'
                                  : 'View membership',
                      loadingTitle: _refreshingPlan
                          ? 'Updating your plan…'
                          : 'Checking your plan…',
                      isLoading: _busy || _refreshingPlan,
                      onPressed: _busy || _refreshingPlan
                          ? null
                          : _needsMeasurements
                              ? _completeMeasurements
                              : _ready
                                  ? _unlock
                                  : _canRetry
                                      ? () => _begin(retry: true)
                                      : () => Navigator.of(context).push(
                                          AppPageRoute<void>(
                                              page: SubscriptionView(
                                                  service: _subscription)))),
              ])),
        ])),
      ));
}

class StarterPlanPreview extends StatelessWidget {
  final Map<String, dynamic> preview;
  final Map<String, dynamic>? profile;
  final bool locked;
  const StarterPlanPreview(
      {super.key, required this.preview, this.profile, this.locked = true});
  @override
  Widget build(BuildContext context) =>
      StarterPlanReveal(preview: preview, profile: profile, locked: locked);
}
