import '../../../core/theme/ds_colors.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/components/profile_avatar.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../auth/views/auth_view.dart';
import '../../health/views/health_connection_view.dart';
import '../../today/repositories/today_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/mcp_repository.dart';
import 'mcp_connections_view.dart';
import 'privacy_settings_view.dart';
import 'profile_details_view.dart';
import 'settings_components.dart';
import 'settings_preferences_view.dart';
import 'training_settings_view.dart';
import '../../notifications/views/notification_settings_view.dart';
import '../../subscription/subscription_service.dart';
import '../../../core/watch/views/apple_watch_settings_view.dart';
import '../../../core/watch/watch_sync_service.dart';

class ProfileView extends StatefulWidget {
  final SettingsRepository? repository;
  final McpRepository? mcpRepository;
  final SubscriptionService? subscriptionService;
  const ProfileView(
      {super.key,
      this.repository,
      this.mcpRepository,
      this.subscriptionService});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final _repository = widget.repository ?? SettingsRepository();
  Map<String, dynamic>? _profile;
  String? _error;
  bool _signingOut = false;
  bool _openingPremium = false;

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

  Future<void> _openPremium() async {
    if (_openingPremium) return;
    setState(() => _openingPremium = true);
    final service = widget.subscriptionService ?? SubscriptionService.shared;
    try {
      await service.initialize();
      if (!mounted) return;
      if (service.access?.hasAccess == true) {
        await service.manage();
      } else if (service.plansAvailable) {
        await service.purchase(service.offers.containsKey('annual')
            ? 'annual'
            : service.offers.keys.first);
      } else {
        throw StateError(service.catalogError ??
            'Membership is unavailable. Please try again.');
      }
      if (service.error case final error?) {
        throw StateError(error);
      }
    } catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: FitnessText(SubscriptionService.message(failure))));
      }
    } finally {
      if (mounted) setState(() => _openingPremium = false);
    }
  }

  Widget _buildWatchStatusPill() {
    return AnimatedBuilder(
      animation: WatchSyncService.shared,
      builder: (context, _) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: FitnessText(WatchSyncService.shared.statusLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, color: FitnessTheme.muted))),
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Sign out?',
      message: 'Your saved Setcraft data stays with your account.',
      action: 'Sign out',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _signingOut = true);
    try {
      await _repository.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          AppPageRoute<void>(page: const AuthView(initialSignIn: true)),
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _signingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: FitnessText('Could not sign out. Please try again.'),
          ),
        );
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
          // Profile Card - Clean Obsidian & Silver (No green border, pure luxury)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DSColors.border, width: .7),
              color: DSColors.bgCard,
            ),
            child: Row(
              children: [
                ProfileAvatar(name: name, size: 44, label: 'Profile'),
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
                          letterSpacing: -.4,
                        ),
                      ),
                      if (user?.email?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          user!.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FitnessTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      TextButton(
                        onPressed: () =>
                            _open(ProfileDetailsView(repository: _repository)),
                        style: TextButton.styleFrom(
                          foregroundColor: FitnessTheme.silver,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft,
                        ),
                        child: const FitnessText(
                          'Edit profile',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: FitnessTheme.silver,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: FitnessText(_error!)),
          ],
          const SizedBox(height: 22),

          SettingsGroup(
            title: 'Personal',
            dividerIndent: 16,
            children: [
              SettingsRow(
                title: 'Training',
                onTap: () =>
                    _open(TrainingSettingsView(repository: _repository)),
              ),
              SettingsRow(
                title: 'Nutrition',
                onTap: () => _open(ProfileDetailsView(
                    nutrition: true, repository: _repository)),
              ),
            ],
          ),

          SettingsGroup(
            title: 'Connections',
            dividerIndent: 16,
            children: [
              if (WatchSyncService.shared.isSupported)
                SettingsRow(
                  title: 'Apple Watch',
                  trailingWidget: _buildWatchStatusPill(),
                  onTap: () => _open(const AppleWatchSettingsView()),
                ),
              SettingsRow(
                title: 'Health connection',
                subtitle: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                    ? 'Apple Health'
                    : 'Health Connect',
                onTap: () => _open(const HealthConnectionView()),
              ),
              SettingsRow(
                title: 'MCP',
                onTap: () =>
                    _open(McpConnectionsView(repository: widget.mcpRepository)),
              ),
            ],
          ),

          SettingsGroup(
            title: 'Preferences',
            dividerIndent: 16,
            children: [
              SettingsRow(
                title: 'Setcraft Premium',
                onTap: _openingPremium ? null : _openPremium,
              ),
              SettingsRow(
                title: 'Notifications',
                onTap: () => _open(const NotificationSettingsView()),
              ),
              SettingsRow(
                title: 'Language',
                value: LanguageManager.shared.currentLanguage.nativeName,
                onTap: () => _open(const SettingsPreferencesView()),
              ),
              SettingsRow(
                title: 'Privacy & Data',
                onTap: () =>
                    _open(PrivacySettingsView(repository: _repository)),
              ),
              SettingsRow(
                title: 'Help & Support',
                onTap: () => _open(const SettingsAboutView()),
              ),
            ],
          ),

          SettingsGroup(
            dividerIndent: 16,
            children: [
              SettingsRow(
                title: _signingOut ? 'Signing out…' : 'Sign out',
                destructive: true,
                onTap: _signingOut ? null : _signOut,
              ),
            ],
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: FitnessText(
                'Setcraft · Your progress, your pace',
                style: TextStyle(
                  color: FitnessTheme.muted,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
