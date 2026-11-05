import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../features/profile/views/settings_components.dart';
import '../../theme/ds_colors.dart';
import '../../theme/fitness_theme.dart';
import '../../localization/fitness_text.dart';
import '../watch_sync_service.dart';

class AppleWatchSettingsView extends StatefulWidget {
  const AppleWatchSettingsView({super.key});

  @override
  State<AppleWatchSettingsView> createState() => _AppleWatchSettingsViewState();
}

class _AppleWatchSettingsViewState extends State<AppleWatchSettingsView>
    with WidgetsBindingObserver {
  final _service = WatchSyncService.shared;
  bool _refreshing = false, _waking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.addListener(_changed);
    if (_service.isSupported) _refresh();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _service.isSupported) _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _service.checkWatchState();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _preference(Future<void> Function() update) async {
    try {
      await update();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save this preference. Try again.');
      }
    }
  }

  Future<void> _openWatch() async {
    final opened = await _service.openWatchSettings();
    if (!opened && mounted) {
      setState(() =>
          _error = 'Open the Watch app on your iPhone to manage your watch.');
    }
  }

  Future<void> _wake() async {
    if (_waking) return;
    setState(() => _waking = true);
    final sent = await _service.startWatchApp(manual: true);
    if (!mounted) return;
    setState(() {
      _waking = false;
      _error = sent
          ? null
          : 'Could not reach your watch. Open Setcraft on Apple Watch and try again.';
    });
    await _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_changed);
    super.dispose();
  }

  String get _statusDescription {
    if (!_service.isPaired) {
      return 'Pair your Apple Watch to get started.';
    }
    if (!_service.isAppInstalled) {
      return 'Install Setcraft on your watch.';
    }
    if (!_service.isReachable) {
      return 'Open Setcraft on your watch.';
    }
    return 'Ready for workouts.';
  }

  Widget _switch(String title, String subtitle, bool value,
          ValueChanged<bool>? onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitnessText(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              FitnessText(subtitle,
                  style: const TextStyle(
                      fontSize: 12, height: 1.4, color: FitnessTheme.muted)),
            ],
          )),
          const SizedBox(width: 16),
          CupertinoSwitch(
            value: value,
            activeTrackColor: Colors.white,
            inactiveTrackColor: DSColors.bgRaised,
            thumbColor: value ? FitnessTheme.canvas : FitnessTheme.silver,
            onChanged: onChanged,
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final supported = _service.isSupported;
    final canConfigure =
        supported && _service.isPaired && _service.isAppInstalled;
    return SettingsPage(
      title: 'Apple Watch',
      centerTitle: true,
      subtitle: '',
      children: [
        if (!supported)
          const SettingsNotice('Apple Watch is available on iPhone.')
        else ...[
          FitnessCard(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: FitnessText(_service.statusLabel,
                        key: const ValueKey('watch-status'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500))),
                TextButton(
                    onPressed: _refreshing ? null : _refresh,
                    child: _refreshing
                        ? const CupertinoActivityIndicator(radius: 8)
                        : const FitnessText('Refresh',
                            style: TextStyle(fontSize: 12))),
              ]),
              const SizedBox(height: 6),
              FitnessText(_statusDescription,
                  style: const TextStyle(
                      fontSize: 13, height: 1.5, color: FitnessTheme.muted)),
              if (!canConfigure) ...[
                const SizedBox(height: 8),
                TextButton(
                    onPressed: _openWatch,
                    child: const FitnessText('Open Watch app')),
              ],
            ],
          )),
          const SizedBox(height: 24),
          SettingsGroup(title: 'Workout', dividerIndent: 16, children: [
            _switch(
                'Open automatically',
                'When a workout starts',
                _service.autoLaunchWatch,
                canConfigure
                    ? (value) =>
                        _preference(() => _service.setAutoLaunchWatch(value))
                    : null),
            _switch(
                'Rest alerts',
                'Haptics when rest ends',
                _service.hapticRestAlerts,
                canConfigure
                    ? (value) =>
                        _preference(() => _service.setHapticRestAlerts(value))
                    : null),
            _switch(
                'Heart rate',
                'During workouts',
                _service.opticalHrEnabled,
                canConfigure
                    ? (value) =>
                        _preference(() => _service.setOpticalHrEnabled(value))
                    : null),
          ]),
          if (canConfigure)
            SettingsGroup(dividerIndent: 16, children: [
              SettingsRow(
                  title: _waking ? 'Opening…' : 'Open on watch',
                  onTap: _waking ? null : _wake),
              SettingsRow(title: 'Watch app settings', onTap: _openWatch),
            ]),
          if (_error != null) SettingsNotice(_error!, error: true),
        ],
      ],
    );
  }
}
