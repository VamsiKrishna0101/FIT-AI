import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/profile_avatar.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../auth/views/auth_view.dart';
import '../../health/views/health_connection_view.dart';
import '../../onboarding/views/equipment_selection_view.dart';
import '../../onboarding/views/training_preferences_view.dart';
import '../../today/repositories/today_repository.dart';
import '../../wellness/views/sleep_preferences_view.dart';
import '../repositories/settings_repository.dart';
import 'mcp_connections_view.dart';
import 'privacy_settings_view.dart';
import 'profile_details_view.dart';
import 'settings_components.dart';
import 'settings_preferences_view.dart';
import '../../notifications/views/notification_settings_view.dart';

class ProfileView extends StatefulWidget {
  final SettingsRepository? repository;
  const ProfileView({super.key, this.repository});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final _repository = widget.repository ?? SettingsRepository();
  Map<String, dynamic>? _profile;
  String? _error;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _repository.profile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Could not refresh your profile. Tap to retry.');
      }
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, AppPageRoute<void>(page: page));
    if (mounted) unawaited(_load());
  }

  Widget _trainingPage() => SettingsPage(
        title: 'Training',
        subtitle: 'Your schedule. Your way to train.',
        children: [
          SettingsGroup(children: [
            SettingsRow(
                icon: CupertinoIcons.calendar,
                title: 'Training preferences',
                subtitle: 'Split, days, priorities and limitations',
                onTap: () =>
                    _open(const TrainingPreferencesView(editProfile: true))),
            SettingsRow(
                icon: CupertinoIcons.slider_horizontal_3,
                title: 'Equipment',
                subtitle: 'Choose what you can train with',
                onTap: () =>
                    _open(const EquipmentSelectionView(editProfile: true))),
            SettingsRow(
                icon: CupertinoIcons.person,
                title: 'Experience & goal',
                subtitle: 'Update your training baseline',
                onTap: () =>
                    _open(ProfileDetailsView(repository: _repository))),
          ]),
          const SettingsNotice(
              'Preference changes guide your next generated plan.'),
        ],
      );

  Widget _healthPage() => SettingsPage(
        title: 'Health & sleep',
        subtitle: 'Keep your readings and sleep setup in one place.',
        children: [
          SettingsGroup(children: [
            SettingsRow(
                icon: CupertinoIcons.heart,
                title: 'Health connection',
                subtitle: 'Access, saved readings and sync controls',
                onTap: () => _open(const HealthConnectionView())),
            SettingsRow(
                icon: CupertinoIcons.moon,
                title: 'Sleep preferences',
                subtitle: 'Wearable readings and manual sleep setup',
                onTap: () => _open(const SleepPreferencesView())),
          ]),
        ],
      );

  Future<void> _signOut() async {
    if (_signingOut) return;
    final confirmed = await confirmSettingsAction(context,
        title: 'Sign out?',
        message: 'Your saved FitAI data stays with your account.',
        action: 'Sign out');
    if (!confirmed || !mounted) return;
    setState(() => _signingOut = true);
    try {
      await _repository.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            AppPageRoute<void>(page: const AuthView(initialSignIn: true)),
            (_) => false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _signingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: FitnessText('Could not sign out. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = TodayRepository.shared.current?.user;
    final name = _profile?['name'] as String? ?? user?.name ?? '';

    return AnimatedBuilder(
      animation: LanguageManager.shared,
      builder: (context, _) => SettingsPage(
        title: 'Settings',
        subtitle: '',
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DSColors.border, width: .7),
              color: DSColors.bgCard,
            ),
            child: Row(children: [
              ProfileAvatar(name: name, size: 40, label: 'Profile'),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        name.isEmpty
                            ? fitnessText(context, 'Your profile')
                            : name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: FitnessTheme.silver,
                            letterSpacing: -.4)),
                    if (user?.email?.isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Text(user!.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: FitnessTheme.muted, fontSize: 11)),
                    ],
                    const SizedBox(height: 4),
                    TextButton(
                        onPressed: () =>
                            _open(ProfileDetailsView(repository: _repository)),
                        style: TextButton.styleFrom(
                            foregroundColor: FitnessTheme.silver,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerLeft),
                        child: const FitnessText('Edit profile',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500))),
                  ])),
            ]),
          ),
          if (_error != null)
            TextButton(onPressed: _load, child: FitnessText(_error!)),
          const SizedBox(height: 24),
          SettingsGroup(title: 'Personal', children: [
            SettingsRow(
                icon: CupertinoIcons.person,
                title: 'Personal details',
                onTap: () =>
                    _open(ProfileDetailsView(repository: _repository))),
            SettingsRow(
                icon: CupertinoIcons.flame,
                title: 'Training',
                onTap: () => _open(_trainingPage())),
            SettingsRow(
                icon: CupertinoIcons.cart,
                title: 'Nutrition',
                onTap: () => _open(ProfileDetailsView(
                    nutrition: true, repository: _repository))),
          ]),
          SettingsGroup(title: 'Connections', children: [
            SettingsRow(
                icon: CupertinoIcons.heart,
                title: 'Health & sleep',
                onTap: () => _open(_healthPage())),
            SettingsRow(
                icon: CupertinoIcons.link,
                title: 'MCP & integrations',
                onTap: () => _open(const McpConnectionsView())),
          ]),
          SettingsGroup(title: 'Preferences', children: [
            SettingsRow(
                icon: CupertinoIcons.bell,
                title: 'Notifications',
                onTap: () => _open(const NotificationSettingsView())),
            SettingsRow(
                icon: CupertinoIcons.slider_horizontal_3,
                title: 'App preferences',
                value: LanguageManager.shared.currentLanguage.nativeName,
                onTap: () => _open(const SettingsPreferencesView())),
            SettingsRow(
                icon: CupertinoIcons.lock_shield,
                title: 'Photos & privacy',
                onTap: () =>
                    _open(PrivacySettingsView(repository: _repository))),
            SettingsRow(
                icon: CupertinoIcons.info_circle,
                title: 'Help & about',
                onTap: () => _open(const SettingsAboutView())),
          ]),
          SettingsGroup(children: [
            SettingsRow(
                icon: CupertinoIcons.square_arrow_right,
                title: _signingOut ? 'Signing out…' : 'Sign out',
                onTap: _signingOut ? null : _signOut),
          ]),
          const Center(
              child: FitnessText('FitAI · Your progress, your pace',
                  style: TextStyle(color: FitnessTheme.muted, fontSize: 11))),
        ],
      ),
    );
  }
}
