import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../auth/views/auth_view.dart';
import '../../health/views/health_connection_view.dart';
import '../../subscription/subscription_service.dart';
import '../repositories/settings_repository.dart';
import '../repositories/privacy_repository.dart';
import '../repositories/settings_account_repository.dart';
import '../repositories/support_repository.dart';
import '../services/settings_device.dart';
import 'ai_sharing_consent.dart';
import 'mcp_connections_view.dart';
import 'settings_components.dart';
import 'settings_editor_components.dart';
import 'support_views.dart';

class PrivacySettingsView extends StatefulWidget {
  final SettingsRepository? repository;
  final PrivacyRepository? privacyRepository;
  // Kept for existing callers; privacy no longer fetches or manages body photos.
  final Object? bodyRepository;
  const PrivacySettingsView(
      {super.key,
      this.repository,
      this.privacyRepository,
      this.bodyRepository});
  @override
  State<PrivacySettingsView> createState() => _PrivacySettingsViewState();
}

class _PrivacySettingsViewState extends State<PrivacySettingsView> {
  late final _repository = widget.repository ?? SettingsRepository();
  late final _privacy = widget.privacyRepository ?? PrivacyRepository();
  Map<String, dynamic>? _config, _consent;
  bool _loading = true, _busy = false;
  String? _owner, _message;
  bool get _aiAllowed =>
      _consent?['aiPlanningConsent'] == true &&
      _consent?['aiPlanningPolicyVersion'] == _config?['aiPolicyVersion'];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final owner = await CacheScope.userId();
      final config = await _privacy.configuration(),
          consent = await _privacy.consent();
      if (!mounted || await CacheScope.userId() != owner) return;
      setState(() {
        _owner = owner;
        _config = config;
        _consent = consent;
        _message = null;
      });
    } catch (error) {
      if (mounted) setState(() => _message = accountSettingsError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_owner == null || await CacheScope.userId() != _owner) {
        throw StateError('Your account changed. Reopen Settings.');
      }
      await action();
    } catch (error) {
      if (mounted) setState(() => _message = accountSettingsError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _aiSharing(bool value) => _run(() async {
        if (value) {
          if (!await ensureAiSharingConsent(context,
              repository: _privacy, review: true)) {
            return;
          }
          final consent = await _privacy.consent();
          if (mounted) setState(() => _consent = consent);
        } else {
          final consent = await _privacy.setAiConsent(
              false, _config!['aiPolicyVersion'] as String);
          if (mounted) {
            setState(() {
              _consent = consent;
              _message =
                  'Future AI sharing requests are stopped. Work already sent to the provider may finish.';
            });
          }
        }
      });
  Future<void> _export() => _run(() async {
        final data = await _repository.exportData();
        if (await CacheScope.userId() != _owner) {
          throw StateError('Your account changed. Reopen Settings.');
        }
        await SettingsDevice.shareExport(data);
      });
  Future<void> _link(String value) => _run(() => openSettingsLink(value));
  Future<void> _deleteAccount() async {
    final store = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? 'the App Store'
        : 'Google Play';
    final confirmed = await confirmSettingsAction(context,
        title: 'Permanently delete account?',
        message:
            'Your account, plans, workouts, nutrition, health records, support conversations and associated photos will be removed. This cannot be undone. Deleting your account does not cancel a subscription. Manage it in $store first.',
        action: 'Delete account',
        destructive: true);
    if (!confirmed || !mounted) return;
    await _run(() async {
      await _repository.deleteAccount(expectedOwner: _owner!);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            AppPageRoute<void>(page: const AuthView(initialSignIn: true)),
            (_) => false);
      }
    });
  }

  Future<void> _privacyTicket() async {
    await _run(() async {
      final support = SupportRepository();
      await support.open();
      if (!mounted) return;
      final id = await Navigator.push<String>(
          context,
          AppPageRoute<String>(
              page:
                  SupportTicketForm(repository: support, category: 'PRIVACY')));
      if (id != null && mounted) {
        await Navigator.push(
            context,
            AppPageRoute<void>(
                page: SupportTicketView(id: id, repository: support)));
      }
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: SettingsPage(title: 'Privacy & Data', subtitle: '', children: [
        if (_busy)
          const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: LinearProgressIndicator()),
        if (_message != null) SettingsNotice(_message!),
        if (_loading)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CupertinoActivityIndicator())),
        if (!_loading && _config == null)
          TextButton(
              onPressed: _load, child: const FitnessText('Retry loading')),
        SettingsGroup(title: 'Privacy', dividerIndent: 16, children: [
          SettingsRow(
              title: 'Privacy policy',
              subtitle: _config?['privacyPolicyUpdated'] as String? ??
                  (_config?['privacyPolicyUrl'] == null
                      ? 'Not published yet'
                      : null),
              onTap: _busy || _config?['privacyPolicyUrl'] == null
                  ? null
                  : () => _link(_config!['privacyPolicyUrl'] as String)),
          if (_config?['termsUrl'] is String)
            SettingsRow(
                title: 'Terms of use',
                onTap:
                    _busy ? null : () => _link(_config!['termsUrl'] as String)),
        ]),
        if (_consent != null)
          SettingsGroup(title: 'AI sharing', dividerIndent: 16, children: [
            SettingsRow(
                title: 'Personal plans',
                subtitle:
                    'Provider: ${_config?['aiProvider'] ?? 'AI sharing provider'}',
                trailingWidget: CupertinoSwitch(
                    value: _aiAllowed,
                    activeTrackColor: Colors.white,
                    thumbColor: _aiAllowed ? Colors.black : Colors.white,
                    onChanged: _busy ? null : _aiSharing)),
          ]),
        const SettingsDisclosure(
            title: 'Data use',
            summary: 'What’s stored and shared',
            children: [
              SettingsNotice(
                  'Your profile and logs keep plans and progress in sync.'),
              SettingsNotice(
                  'Manage access in your health app. Health imports and photos are excluded from AI plans.'),
              SettingsNotice(
                  'AI planning shares only the data listed in the consent notice, with your permission.'),
              SettingsNotice(
                  'Support can read the messages and screenshots you send.'),
              SettingsNotice(
                  'See the privacy policy for retention and your rights. JSON exports include records, not image files.'),
            ]),
        SettingsGroup(title: 'Connections', dividerIndent: 16, children: [
          SettingsRow(
              title: 'Health connection',
              subtitle: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                  ? 'Apple Health'
                  : 'Health Connect',
              onTap: _busy
                  ? null
                  : () => Navigator.push(context,
                      AppPageRoute<void>(page: const HealthConnectionView()))),
          SettingsRow(
              title: 'MCP',
              onTap: _busy
                  ? null
                  : () => Navigator.push(context,
                      AppPageRoute<void>(page: const McpConnectionsView()))),
        ]),
        SettingsGroup(title: 'Your data', dividerIndent: 16, children: [
          SettingsRow(
              title: 'Export my data',
              value: 'JSON',
              onTap: _busy || _owner == null ? null : _export),
          SettingsRow(
              title: 'Privacy question', onTap: _busy ? null : _privacyTicket),
          if (_config?['privacyEmail'] is String)
            SettingsRow(
                title: 'Privacy contact',
                subtitle: _config!['privacyEmail'] as String,
                onTap: _busy
                    ? null
                    : () => _link('mailto:${_config!['privacyEmail']}')),
          SettingsRow(
              title: 'Manage subscription',
              onTap: _busy || _owner == null
                  ? null
                  : () => _run(SubscriptionService.shared.manage)),
          SettingsRow(
              title: 'Delete account',
              destructive: true,
              onTap: _busy || _owner == null ? null : _deleteAccount),
        ]),
      ]));
}
