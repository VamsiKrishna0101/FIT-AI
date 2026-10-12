import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/components/premium_surface.dart';
import '../../../core/health/health_models.dart';
import '../../../core/health/health_sync_service.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../onboarding/components/onboarding_chrome.dart';

class HealthConnectionView extends StatefulWidget {
  final VoidCallback? onComplete;
  final HealthSyncService? service;
  const HealthConnectionView({super.key, this.onComplete, this.service});
  @override
  State<HealthConnectionView> createState() => _HealthConnectionViewState();
}

class _HealthConnectionViewState extends State<HealthConnectionView>
    with WidgetsBindingObserver {
  HealthSyncService get service => widget.service ?? HealthSyncService.shared;
  bool _busy = false, _body = false, _initializing = true;
  String? _message;
  List<Map<String, dynamic>> _workouts = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    service.addListener(_changed);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await service.initialize();
    if (mounted) {
      setState(() {
        _initializing = false;
        _body = service.bodyEnabled;
      });
    }
    if (service.enabled) unawaited(_loadSaved());
  }

  Future<void> _loadSaved() async {
    try {
      final workouts = await service.loadSavedReadings();
      if (mounted) setState(() => _workouts = workouts);
    } catch (_) {
      /* Keep available readings visible when the server is offline. */
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) {
      unawaited(service.initialize());
    }
  }

  @override
  void dispose() {
    service.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (await service.requestPermissions(includeBody: _body)) {
        final result = await service.syncToday();
        if (mounted) setState(() => _message = result.message);
        if (result.success) {
          unawaited(_loadSaved());
          unawaited(service.syncRecentDays().catchError((Object _) {}));
        }
      } else if (mounted) {
        setState(() => _message = service.currentState ==
                HealthConnectionState.needsInstall
            ? 'Install or update Health Connect, then return here to connect.'
            : 'You can share only the data you choose, or continue with manual logging.');
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _message = 'Could not connect. You can try again or set up later.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    try {
      final result = await service.syncToday();
      if (mounted) setState(() => _message = result.message);
      if (result.success) {
        unawaited(_loadSaved());
        unawaited(service.syncRecentDays().catchError((Object _) {}));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _later() async {
    await service.skipSetup();
    if (mounted) widget.onComplete?.call();
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    try {
      await service.disconnect();
      if (mounted) {
        setState(() => _message =
            'Syncing stopped. Previously saved readings are preserved.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manage() async {
    if (service.currentProvider == HealthProviderType.googleHealthConnect) {
      try {
        await const MethodChannel('fitai/health_ui')
            .invokeMethod<void>('manageAccess');
        return;
      } catch (_) {}
    }
    if (!mounted) return;
    showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
                title: const FitnessText('Manage health access'),
                content: FitnessText(service.currentProvider ==
                        HealthProviderType.appleHealthKit
                    ? 'Open Apple Health, tap your profile, then Apps and FitAI to review access. Apple does not tell FitAI which read permissions you declined.'
                    : 'Open Health Connect, then App permissions and FitAI to review access.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const FitnessText('Done'))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    final provider = service.currentProvider;
    final unsupported =
        service.currentState == HealthConnectionState.unsupported;
    final name = provider.displayName;
    final data = service.lastSnapshot;
    return FitnessTheme(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
                statusBarColor: FitnessTheme.canvas,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: FitnessTheme.canvas,
                systemNavigationBarIconBrightness: Brightness.light),
            child: Scaffold(
                backgroundColor: FitnessTheme.canvas,
                body: SafeArea(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: SizedBox(
                            height: 44,
                            child: Row(children: [
                              if (widget.onComplete == null)
                                OnboardingBackButton(
                                    onPressed: () =>
                                        Navigator.of(context).maybePop())
                              else
                                Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                        color: FitnessTheme.surface,
                                        shape: BoxShape.circle),
                                    child: const Icon(CupertinoIcons.heart_fill,
                                        color: FitnessTheme.silver, size: 20)),
                              const SizedBox(width: 14),
                              const Expanded(
                                  child: FitnessText('Health connection',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: FitnessTheme.muted))),
                              if (widget.onComplete != null)
                                const FitnessText('Optional',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: FitnessTheme.muted)),
                            ])),
                      ),
                      Expanded(
                          child: ListView(
                              key: const ValueKey('health-connection-scroll'),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 24, 20, 20),
                              children: [
                            const FitnessText('Connect your health',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.8,
                                    height: 1.12)),
                            const SizedBox(height: 9),
                            FitnessText(
                                unsupported
                                    ? 'Health sync is unavailable on this device. You can continue with manual logging.'
                                    : 'Bring your daily movement, sleep, and recovery readings into FitAI.',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: FitnessTheme.muted,
                                    height: 1.45)),
                            const SizedBox(height: 24),
                            _category(CupertinoIcons.flame, 'Activity',
                                'Steps, active calories, workouts'),
                            const SizedBox(height: 10),
                            _category(CupertinoIcons.moon_stars, 'Recovery',
                                'Sleep, resting heart rate, HRV'),
                            const SizedBox(height: 10),
                            PremiumSurface(
                                child: SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    title: const FitnessText(
                                        'Body measurements',
                                        style: TextStyle(fontSize: 14)),
                                    subtitle: const FitnessText(
                                        'Optional · Weight and body fat',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: FitnessTheme.muted)),
                                    value: _body,
                                    activeTrackColor: FitnessTheme.silver,
                                    onChanged:
                                        _busy || _initializing || unsupported
                                            ? null
                                            : (value) =>
                                                setState(() => _body = value))),
                            const SizedBox(height: 22),
                            if (service.enabled) ...[
                              PremiumSurface(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    FitnessText(
                                        provider ==
                                                HealthProviderType
                                                    .appleHealthKit
                                            ? 'Apple Health setup complete'
                                            : 'Health Connect access configured',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    if (service.lastSyncTime != null)
                                      FitnessText(
                                          'Last checked · ${DateFormat('d MMM, HH:mm').format(service.lastSyncTime!)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: FitnessTheme.muted)),
                                    if (data != null) ...[
                                      const SizedBox(height: 12),
                                      FitnessText('Readings · ${data.date}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: FitnessTheme.muted)),
                                      const SizedBox(height: 8),
                                      _reading(
                                          'Steps',
                                          data.steps == null
                                              ? null
                                              : '${data.steps}'),
                                      _reading(
                                          'Sleep',
                                          data.sleepTotalMinutes == null
                                              ? null
                                              : '${data.sleepTotalMinutes!.round() ~/ 60} h ${data.sleepTotalMinutes!.round() % 60} m'),
                                      _reading(
                                          'Resting heart rate',
                                          data.restingHR == null
                                              ? null
                                              : '${data.restingHR!.round()} bpm'),
                                      _reading(
                                          'HRV',
                                          data.hrv == null
                                              ? null
                                              : '${data.hrv!.round()} ms${data.hrvMethod == null ? '' : ' · ${data.hrvMethod}'}'),
                                    ],
                                  ])),
                              const SizedBox(height: 12),
                            ],
                            if (_workouts.isNotEmpty) ...[
                              PremiumSurface(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    const FitnessText(
                                        'Imported workouts · Today',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    const FitnessText(
                                        'Recorded in your health app. FitAI sets and volume stay separate.',
                                        style: TextStyle(
                                            fontSize: 11,
                                            height: 1.4,
                                            color: FitnessTheme.muted)),
                                    for (final workout in _workouts)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FitnessText(
                                                    (workout['workoutType']
                                                            as String)
                                                        .split('_')
                                                        .map((word) => word
                                                                .isEmpty
                                                            ? ''
                                                            : '${word[0]}${word.substring(1).toLowerCase()}')
                                                        .join(' '),
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                                const SizedBox(height: 4),
                                                FitnessText(
                                                    '${(workout['durationMinutes'] as num).round()} min${workout['activeCalories'] == null ? '' : ' · ${(workout['activeCalories'] as num).round()} kcal'}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: FitnessTheme
                                                            .muted)),
                                              ])),
                                  ])),
                              const SizedBox(height: 16),
                            ],
                            if (_message != null)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: FitnessText(_message!,
                                      style: const TextStyle(
                                          color: FitnessTheme.muted,
                                          fontSize: 13,
                                          height: 1.5))),
                            if (_busy || _initializing)
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: LinearProgressIndicator(
                                      color: FitnessTheme.silver,
                                      minHeight: 2)),
                            if (service.enabled)
                              Wrap(alignment: WrapAlignment.center, children: [
                                TextButton(
                                    onPressed: _busy ? null : _sync,
                                    child: const FitnessText('Sync now')),
                                TextButton(
                                    onPressed: _busy ? null : _manage,
                                    child: const FitnessText('Manage access')),
                                TextButton(
                                    onPressed: _busy ? null : _stop,
                                    child: const FitnessText('Stop syncing')),
                              ]),
                            const SizedBox(height: 16),
                            const FitnessText(
                                'You choose what to share. Selected readings are synced to your FitAI account to power your dashboard. You can stop syncing at any time.',
                                style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: FitnessTheme.muted)),
                            TextButton(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const HealthPrivacyView())),
                                child: const FitnessText('Privacy & data use')),
                          ])),
                      Container(
                        key: const ValueKey('health-action-footer'),
                        decoration: const BoxDecoration(
                            color: FitnessTheme.canvas,
                            border: Border(
                                top: BorderSide(color: Color(0x0FFFFFFF)))),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!unsupported)
                              LiquidChromeButton(
                                  title: service.currentState ==
                                          HealthConnectionState.needsInstall
                                      ? 'Install / update Health Connect'
                                      : service.enabled
                                          ? 'Review sharing choices'
                                          : 'Connect $name',
                                  onPressed:
                                      _busy || _initializing ? null : _connect,
                                  isLoading: _busy || _initializing),
                            if (widget.onComplete != null) ...[
                              if (!unsupported) const SizedBox(height: 4),
                              TextButton(
                                  onPressed: _busy || _initializing
                                      ? null
                                      : service.enabled
                                          ? widget.onComplete
                                          : _later,
                                  child: FitnessText(
                                      service.enabled
                                          ? 'Continue to Today'
                                          : 'Set up later',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: FitnessTheme.muted))),
                            ],
                          ],
                        ),
                      ),
                    ])))));
  }

  Widget _category(IconData icon, String title, String subtitle) =>
      PremiumSurface(
          child: Row(children: [
        Icon(icon, size: 22, color: FitnessTheme.silver),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitnessText(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FitnessText(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: FitnessTheme.muted, height: 1.4)),
        ])),
      ]));
  Widget _reading(String label, String? value) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        Expanded(
            child: FitnessText(label,
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted))),
        Flexible(
            child: FitnessText(value ?? 'No readable records yet',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.right)),
      ]));
}

class HealthPrivacyView extends StatelessWidget {
  const HealthPrivacyView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: FitnessTheme.canvas,
      appBar: AppBar(title: const FitnessText('Health data & privacy')),
      body: const SafeArea(
          child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: FitnessText(
                  'FitAI requests read access to steps, active calories, workouts, sleep, resting heart rate, and heart rate variability. Weight and body fat are optional.\n\n'
                  'The phone reads the categories you choose from Health Connect or Apple Health. FitAI uploads daily readings, source information, and imported workout details to its backend and saves them in your signed-in account. These records power dated dashboards and trends. Readiness is a FitAI estimate, not a measurement provided by your health app.\n\n'
                  'FitAI does not request permission to write health records in this connection flow. You can decline categories or choose Set up later. Missing data is not replaced with example readings.\n\n'
                  'Stop syncing in Profile → Health connection. Review or revoke operating-system access in Health Connect or Apple Health. Stopping sync does not delete previously saved account records.\n\n'
                  'Apple does not disclose whether individual read permissions were denied; no readable records can mean missing data or restricted access.',
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: FitnessTheme.silver)))));
}
