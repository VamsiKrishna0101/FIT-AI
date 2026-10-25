import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/branding/setcraft_launch_screen.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../planner/views/weekly_plan_view.dart';
import '../../subscription/subscription_service.dart';
import '../../subscription/subscription_view.dart';
import '../data/starter_plan_repository.dart';
import '../components/starter_plan_reveal.dart';
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
  String? _errorCode;
  Timer? _timer;
  bool _busy = false, _polling = false, _foreground = true;
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
      if (_subscription.access?.hasAccess != true) {
        await _repo.prepareUnlock(id);
        if (!await _sameOwner()) return;
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
        setState(() {
          _error = _message(error);
          _errorCode = details is Map ? details['code'] as String? : null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            title: const FitnessText('Your plan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            actions: [
              TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(AppPageRoute<void>(
                          page: SubscriptionView(service: _subscription))),
                  child: const FitnessText('Membership'))
            ]),
        body: SafeArea(
            child: Column(children: [
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                if (_ready && _preview != null) ...[
                  StarterPlanPreview(preview: _preview!, profile: _profile),
                ] else ...[
                  const SizedBox(height: 28),
                  FitnessText(
                      _failed || _error != null
                          ? 'We could not finish your plan'
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
                  if (_ready && _errorCode == 'STALE_PLAN')
                    TextButton(
                        onPressed: _busy ? null : () => _begin(retry: true),
                        child: const FitnessText('Refresh my plan')),
                  const SizedBox(height: 8),
                ],
                if (_ready || _failed || _error != null)
                  LiquidChromeButton(
                      pill: true,
                      solid: true,
                      showArrow: false,
                      title: _ready
                          ? (_subscription.access?.hasAccess == true
                              ? 'Open my full plan'
                              : 'Unlock my plan')
                          : _canRetry
                              ? 'Try again'
                              : 'View membership',
                      isLoading: _busy,
                      onPressed: _busy
                          ? null
                          : _ready
                              ? _unlock
                              : _canRetry
                                  ? () => _begin(retry: true)
                                  : () => Navigator.of(context).push(
                                      AppPageRoute<void>(
                                          page: SubscriptionView(
                                              service: _subscription)))),
                if (_ready) ...[
                  const SizedBox(height: 9),
                  const FitnessText('Choose your membership next',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: FitnessTheme.muted)),
                ],
              ])),
        ])),
      ));
}

class StarterPlanPreview extends StatelessWidget {
  final Map<String, dynamic> preview;
  final Map<String, dynamic>? profile;
  const StarterPlanPreview({super.key, required this.preview, this.profile});
  @override
  Widget build(BuildContext context) =>
      StarterPlanReveal(preview: preview, profile: profile);
}
