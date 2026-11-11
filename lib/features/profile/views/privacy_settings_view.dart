import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../auth/data/social_sign_in.dart';
import '../../auth/views/auth_view.dart';
import '../legal/legal_content.dart';
import '../repositories/settings_repository.dart';
import '../repositories/privacy_repository.dart';
import '../repositories/settings_account_repository.dart';
import '../repositories/support_repository.dart';
import '../services/settings_device.dart';
import 'ai_sharing_consent.dart';
import 'legal_document_view.dart';
import 'settings_components.dart';
import 'support_views.dart';

class PrivacySettingsView extends StatefulWidget {
  final SettingsRepository? repository;
  final PrivacyRepository? privacyRepository;
  // Kept for existing callers; privacy no longer fetches or manages body photos.
  final Object? bodyRepository;
  final SocialSignIn? socialSignIn;
  const PrivacySettingsView(
      {super.key,
      this.repository,
      this.privacyRepository,
      this.bodyRepository,
      this.socialSignIn});
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
  void _open(LegalDocument document) => Navigator.push(context,
      AppPageRoute<void>(page: LegalDocumentView(document: document)));
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
      // Apple requires revoking Sign in with Apple tokens on deletion.
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          await _privacy.usesAppleSignIn() &&
          !await (widget.socialSignIn ?? SocialSignIn()).revokeApple()) {
        throw StateError(
            'Confirm with Apple to finish deleting your account.');
      }
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
        SettingsGroup(dividerIndent: 16, children: [
          SettingsRow(
              title: 'Privacy Policy',
              onTap: _busy ? null : () => _open(privacyPolicy)),
          SettingsRow(
              title: 'Terms of Use',
              onTap: _busy ? null : () => _open(termsOfUse)),
        ]),
        if (_consent != null)
          SettingsGroup(dividerIndent: 16, children: [
            SettingsRow(
                title: 'AI plan generation',
                subtitle: 'Shares goals and logs with '
                    '${(_config?['aiProvider'] as String?) ?? 'our AI provider'}',
                trailingWidget: CupertinoSwitch(
                    value: _aiAllowed,
                    activeTrackColor: Colors.white,
                    thumbColor: _aiAllowed ? Colors.black : Colors.white,
                    onChanged: _busy ? null : _aiSharing)),
          ]),
        SettingsGroup(dividerIndent: 16, children: [
          SettingsRow(
              title: 'Export my data',
              onTap: _busy || _owner == null ? null : _export),
          SettingsRow(
              title: 'Privacy question', onTap: _busy ? null : _privacyTicket),
          if (_config?['privacyEmail'] is String)
            SettingsRow(
                title: 'Contact privacy team',
                onTap: _busy
                    ? null
                    : () => _link('mailto:${_config!['privacyEmail']}')),
        ]),
        SettingsGroup(dividerIndent: 16, children: [
          SettingsRow(
              title: 'Delete account',
              destructive: true,
              onTap: _busy || _owner == null ? null : _deleteAccount),
        ]),
      ]));
}
