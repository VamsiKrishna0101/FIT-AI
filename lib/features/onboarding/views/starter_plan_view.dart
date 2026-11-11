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
import '../components/coach_mascot.dart';
import '../components/coach_speech.dart';
import '../components/onboarding_motion.dart';
import 'training_preferences_view.dart';
import 'equipment_selection_view.dart';
import '../../profile/views/ai_sharing_consent.dart';
import '../../profile/views/support_views.dart';

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
  final Future<bool> Function(BuildContext) requestAiConsent;
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
      this.requestAiConsent = ensureAiSharingConsent,
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
  String? _errorCode;
  SubscriptionPreparation? _billingPreparation;
  Timer? _timer;
  bool _busy = false, _polling = false, _foreground = true;
  bool _presentReady = false, _membershipOpen = false;
  bool _refreshingPlan = false, _unlockAfterRefresh = false;
  static const _refreshableCodes = {
    'STALE_PLAN',
    'WORKFLOW_UPDATED',
    'CATALOG_CHANGED',
    'PAST_PLAN',
    'INVALID_WEEK',
    'NOT_FOUND',
  };
  bool get _ready => _run?['status'] == 'COMPLETED' && _run?['plan'] is Map;
  bool get _failed => _run?['status'] == 'FAILED';
  String? get _failureCode => _run?['errorCode'] as String?;
  bool get _equipmentIssue => _failed && _failureCode == 'CATALOG_GAP';
  bool get _movementIssue =>
      _failed && _failureCode == 'STARTER_REVIEW_REQUIRED';
  bool get _canRetry => !_failed || _run?['canRetry'] != false;
  // Only an access failure leads to membership; other failures are not billing.
  bool get _membershipIssue =>
      _failed &&
      const {'PREMIUM_REQUIRED', 'SUBSCRIPTION_REQUIRED'}
          .contains(_failureCode);
  String get _failureMessage => _equipmentIssue
      ? 'We could not match a complete week to your equipment. Check what you have available.'
      : _movementIssue
          ? 'We could not match exercises to your movement notes. Review them if anything has changed.'
          : _canRetry
              ? 'Your answers are saved. You do not need to fill them in again.'
              : _membershipIssue
                  ? 'Your answers are saved. Check your membership to continue.'
                  : 'Your answers are saved. Planning is unavailable right now. Our team can help.';
  Map<String, dynamic>? get _preview =>
      _ready && (_run!['plan'] as Map)['preview'] is Map
          ? Map<String, dynamic>.from((_run!['plan'] as Map)['preview'] as Map)
          : null;

  @override
  void initState() {
    super.initState();
    _presentReady = widget.initialRun?['status'] == 'COMPLETED';
    WidgetsBinding.instance.addObserver(this);
    _begin();
    unawaited(_loadProfile());
    unawaited(_prepareBilling());
  }

  Future<void> _prepareBilling() async {
    try {
      final prepared = await _subscription.prepareAccountEntry();
      if (mounted && await _sameOwner()) {
        setState(() => _billingPreparation = prepared);
      }
    } catch (_) {
      /* Checkout shows a retry on the same page if the store is offline. */
    }
  }

  Future<bool> _beforePurchase() async {
    if (!_ready || _busy || !_foreground) return false;
    try {
      await _subscription.refresh();
      if (!await _sameOwner() || !_foreground) return false;
      await _repo.prepareUnlock((_run!['plan'] as Map)['id'] as String);
      return await _sameOwner() && _foreground;
    } catch (error) {
      if (await _sameOwner()) {
        final details = error is DioException ? error.response?.data : null;
        final code = details is Map ? details['code'] as String? : null;
        if (_refreshableCodes.contains(code)) {
          await _begin(retry: true);
        } else {
          setState(() => _error = _message(error));
        }
      }
      return false;
    }
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
      if (retry) {
        _run = null;
        _presentReady = false;
      }
    });
    _timer?.cancel();
    _owner = await CacheScope.userId();
    if (!mounted) return;
    try {
      if (!mounted) return;
      if (retry || widget.initialRun == null) {
        if (!mounted) return;
        final approved = await widget.requestAiConsent(context);
        if (!await _sameOwner()) return;
        if (!approved) {
          // Declining must not leave an endless loading screen.
          setState(() => _error =
              'Your plan is created with AI planning. Your answers are saved, so you can agree whenever you are ready.');
          return;
        }
      }
      var run = !retry && widget.initialRun != null
          ? widget.initialRun!
          : await _repo.start();
      if (!await _sameOwner()) return;
      // A prepared entry can outlive a backend update. Refresh legacy previews
      // once so exercise identities and catalogue media are never frozen in it.
      if (!retry &&
          widget.initialRun != null &&
          _missingExerciseIdentity(run)) {
        try {
          run = await _repo.run(run['id'] as String);
        } catch (_) {
          // Keep the saved preview available; foreground refresh can recover it.
        }
        if (!await _sameOwner()) return;
      }
      setState(() => _run = run);
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

  bool _missingExerciseIdentity(Map<String, dynamic> run) {
    if (run['status'] != 'COMPLETED') return false;
    final plan = run['plan'];
    final preview = plan is Map ? plan['preview'] : null;
    final first = preview is Map ? preview['firstWorkout'] : null;
    final samples = first is Map ? first['exercises'] : null;
    return samples is List &&
        samples.whereType<Map>().any((sample) {
          final exercise = sample['exercise'];
          final id =
              sample['exerciseId'] ?? (exercise is Map ? exercise['id'] : null);
          return id is! String || id.trim().isEmpty;
        });
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
    if (!await widget.requestAiConsent(context) || !await _sameOwner()) return;
    _timer?.cancel();
    setState(() {
      _run = null;
      _presentReady = false;
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

  Future<void> _showMembership() async {
    if (_membershipOpen || _busy || !_ready || !_foreground) return;
    if (!await _sameOwner() || !mounted || !_foreground) return;
    if (_subscription.access?.hasAccess == true) {
      await _unlock();
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _membershipOpen = true);
    try {
      late final AppPageRoute<bool> route;
      route = AppPageRoute<bool>(
          page: SubscriptionView(
        service: _subscription,
        preparation: _billingPreparation,
        beforePurchase: () async {
          final valid = await _beforePurchase();
          if (!valid && mounted && route.isCurrent) navigator.pop(false);
          return valid && route.isCurrent;
        },
        onContinue: () {
          if (route.isCurrent) navigator.pop(true);
        },
      ));
      final verified = await navigator.push<bool>(route);
      if (verified == true && await _sameOwner()) await _unlock();
    } finally {
      if (mounted) setState(() => _membershipOpen = false);
    }
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
      // Recheck the snapshot after verified payment before activating the plan.
      await _repo.prepareUnlock(id);
      if (!await _sameOwner() || !_foreground) return;
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
  Widget build(BuildContext context) => _ready &&
          _presentReady &&
          _preview != null
      ? FitnessTheme(
          child: Scaffold(
          backgroundColor: Colors.black,
          // The reveal opens with a confetti burst above Mochi's cheer.
          body: Stack(fit: StackFit.expand, children: [
            SafeArea(
              child: Center(
                  child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Text('SETCRAFT',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF606066),
                              letterSpacing: -.8))),
                  Expanded(
                      child: ListView(
                          key: const ValueKey('starter-preview-scroll'),
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                          children: [
                        const CoachSpeech(
                            key: ValueKey('starter-coach'),
                            mood: CoachMood.cheer,
                            text: 'Done! I built this week around your answers'),
                        const SizedBox(height: 24),
                        StarterPlanPreview(
                            preview: _preview!,
                            profile: _profile,
                            locked: _subscription.access?.hasAccess != true)
                      ])),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: FitnessText(_error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: FitnessTheme.muted))),
                            LiquidChromeButton(
                                key: const ValueKey('starter-unlock'),
                                title: _subscription.access?.hasAccess == true
                                    ? 'Open my plan'
                                    : 'Unlock full plan',
                                loadingTitle: 'Opening your plan',
                                pill: true,
                                solid: true,
                                showArrow: false,
                                isLoading: _busy || _membershipOpen,
                                onPressed: _busy || _membershipOpen
                                    ? null
                                    : _showMembership),
                          ])),
                ]),
          ))),
            const Positioned.fill(child: ConfettiBurst()),
          ]),
        ))
      : FitnessTheme(
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
                  ...[
                    const SizedBox(height: 12),
                    Center(
                        child: CoachHero(
                            child: CoachMascot(
                                key: const ValueKey('starter-building-coach'),
                                size: 92,
                                mood: _failed || _error != null
                                    ? CoachMood.listening
                                    : CoachMood.thinking))),
                    const SizedBox(height: 16),
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
                                  onComplete: () {
                                    if (mounted && _ready) {
                                      setState(() => _presentReady = true);
                                    }
                                  },
                                  percent: (_ready
                                      ? 100
                                      : ((_run?['progress'] as Map?)?['percent']
                                                  as num? ??
                                              0)
                                          .toInt()
                                          .clamp(0, 99)),
                                  animating: _foreground && !_failed))),
                      const SizedBox(height: 20),
                      Semantics(
                          liveRegion: true,
                          child: FitnessText(_stage,
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: FitnessTheme.muted))),
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
                  if (_error != null) ...[
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
                  if (_failed || _error != null || _refreshingPlan)
                    LiquidChromeButton(
                        pill: true,
                        solid: true,
                        showArrow: false,
                        title: _canRetry
                            ? 'Try again'
                            : _membershipIssue
                                ? 'View membership'
                                : 'Help & Support',
                        loadingTitle: _refreshingPlan
                            ? 'Updating your plan…'
                            : 'Checking your plan…',
                        isLoading: _busy || _refreshingPlan,
                        onPressed: _busy || _refreshingPlan
                            ? null
                            : _canRetry
                                ? () => _begin(retry: true)
                                : () => Navigator.of(context).push(
                                    AppPageRoute<void>(
                                        page: _membershipIssue
                                            ? SubscriptionView(
                                                service: _subscription)
                                            : const HelpSupportView()))),
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
