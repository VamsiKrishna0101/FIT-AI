import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

class _AppleWatchSettingsViewState extends State<AppleWatchSettingsView> {
  final _service = WatchSyncService.shared;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _refreshState();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshState() async {
    setState(() => _refreshing = true);
    await _service.checkWatchState();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    final isPaired = _service.isPaired;
    final isInstalled = _service.isAppInstalled;

    return SettingsPage(
      title: 'Apple Watch',
      subtitle: '',
      children: [
        _buildHeroCard(isIOS, isPaired, isInstalled),
        const SizedBox(height: 14),

        SettingsGroup(
          title: 'Workout',
          children: [
            _buildSwitchRow(
              icon: CupertinoIcons.arrow_up_right_square,
              title: 'Auto-launch',
              subtitle: 'Opens on workout start',
              value: _service.autoLaunchWatch,
              onChanged: (val) => _service.setAutoLaunchWatch(val),
            ),
            _buildSwitchRow(
              icon: CupertinoIcons.waveform_path,
              title: 'Haptic alerts',
              subtitle: 'Buzz on rest completion',
              value: _service.hapticRestAlerts,
              onChanged: (val) => _service.setHapticRestAlerts(val),
            ),
            _buildSwitchRow(
              icon: CupertinoIcons.heart,
              title: 'Heart rate',
              subtitle: 'Live wrist telemetry',
              value: _service.opticalHrEnabled,
              onChanged: (val) => _service.setOpticalHrEnabled(val),
            ),
          ],
        ),

        if (isIOS) ...[
          SettingsGroup(
            title: 'Device',
            children: [
              SettingsRow(
                icon: CupertinoIcons.antenna_radiowaves_left_right,
                title: 'Wake Apple Watch',
                subtitle: 'Send immediate launch signal',
                onTap: () async {
                  final success = await _service.startWatchApp();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Signal sent to Apple Watch'
                          : 'Could not reach Apple Watch'),
                    ),
                  );
                },
              ),
              SettingsRow(
                icon: CupertinoIcons.gear_alt,
                title: 'Watch app settings',
                subtitle: 'iOS system preferences',
                onTap: () => _service.openWatchSettings(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeroCard(bool isIOS, bool isPaired, bool isInstalled) {
    final statusText = switch ((isIOS, isPaired, isInstalled)) {
      (false, _, _) => 'Ready to Pair',
      (true, true, true) => 'Connected & Ready',
      (true, true, false) => 'Install Setcraft on Watch',
      (true, false, _) => 'Not Connected',
    };
    final isReady = isIOS && isPaired && isInstalled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: DSColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DSColors.border, width: .7),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.watch_outlined,
                color: FitnessTheme.silver, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apple Watch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            isReady ? FitnessTheme.silver : FitnessTheme.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: FitnessTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_refreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: FitnessTheme.muted),
            )
          else
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_clockwise,
                  size: 16, color: FitnessTheme.muted),
              onPressed: _refreshState,
              tooltip: 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .045),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: FitnessTheme.silver),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FitnessText(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: DSColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                FitnessText(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FitnessTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: value,
            activeTrackColor: FitnessTheme.silver,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
