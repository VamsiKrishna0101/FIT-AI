import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../auth/views/auth_view.dart';
import '../../body_scan/models/body_assessment_models.dart';
import '../../body_scan/repositories/body_assessment_repository.dart';
import '../repositories/settings_repository.dart';
import 'settings_components.dart';

class PrivacySettingsView extends StatefulWidget {
  final SettingsRepository? repository;
  final BodyAssessmentRepository? bodyRepository;
  const PrivacySettingsView({super.key, this.repository, this.bodyRepository});

  @override
  State<PrivacySettingsView> createState() => _PrivacySettingsViewState();
}

class _PrivacySettingsViewState extends State<PrivacySettingsView> {
  late final _repository = widget.repository ?? SettingsRepository();
  late final _bodyRepository =
      widget.bodyRepository ?? BodyAssessmentRepository.shared;
  List<BodyAssessment> _records = [];
  bool _loading = true, _busy = false, _photoLoadFailed = false;
  String? _owner, _message;
  int get _photoCount =>
      _records.fold(0, (total, entry) => total + entry.photos.length);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final owner = await CacheScope.userId();
      _owner = owner;
      final body = await _bodyRepository.load();
      if (!mounted || await CacheScope.userId() != owner) return;
      setState(() {
        _owner = owner;
        _records = body.records;
        _loading = false;
        _photoLoadFailed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _photoLoadFailed = true;
          _message = 'Could not load saved photos. Please retry.';
        });
      }
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
        throw StateError('Your session changed. Reopen Settings.');
      }
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _message = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhotos() async {
    final confirmed = await confirmSettingsAction(context,
        title: 'Delete saved photos?',
        message:
            'Remove the saved photos shown here. Your scan results and entered measurements stay in your account.',
        action: 'Delete photos',
        destructive: true);
    if (!confirmed || !mounted) return;
    await _run(() async {
      for (final entry
          in _records.where((entry) => entry.photos.isNotEmpty).toList()) {
        if (await CacheScope.userId() != _owner) {
          throw StateError('Your session changed.');
        }
        final updated = await _bodyRepository.deletePhotos(entry.id);
        if (!mounted || await CacheScope.userId() != _owner) return;
        setState(() => _records = _records
            .map((record) => record.id == updated.id ? updated : record)
            .toList());
      }
      if (mounted) {
        setState(() => _message =
            'Saved photos deleted. Your measurements are preserved.');
      }
    });
  }

  Future<void> _export() => _run(() async {
        final data = await _repository.exportData();
        if (mounted) {
          await Navigator.push(
              context, AppPageRoute<void>(page: _DataExportView(data: data)));
        }
      });

  Future<void> _deleteAccount() async {
    final confirmed = await confirmSettingsAction(context,
        title: 'Permanently delete account?',
        message:
            'Your account, plans, workouts, health records and saved photos will be removed. This cannot be undone. Deleting your account does not cancel a Google Play subscription. Manage it in Google Play first.',
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

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: 'Photos & privacy',
        subtitle: 'Your data. Your choice.',
        children: [
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: LinearProgressIndicator()),
          if (_message != null) SettingsNotice(_message!),
          SettingsGroup(title: 'Body photos', children: [
            const SettingsRow(
                icon: CupertinoIcons.camera,
                title: 'Photo saving',
                subtitle:
                    'Off by default. Choose Save photos during each scan.'),
            SettingsRow(
                icon: CupertinoIcons.photo_on_rectangle,
                title: 'Saved photos',
                value: _loading
                    ? 'Loading…'
                    : _photoLoadFailed
                        ? 'Unavailable'
                        : '$_photoCount'),
            SettingsRow(
                icon: CupertinoIcons.trash,
                title: 'Delete saved photos',
                subtitle: _photoCount == 0
                    ? 'No saved photos to delete'
                    : 'Remove photos from your recent saved scans',
                destructive: true,
                onTap: _busy || _loading || _photoLoadFailed || _photoCount == 0
                    ? null
                    : _removePhotos),
          ]),
          if (!_loading && _photoLoadFailed)
            TextButton(
                onPressed: _load, child: const FitnessText('Retry loading')),
          SettingsGroup(title: 'Your account data', children: [
            SettingsRow(
                icon: CupertinoIcons.arrow_down_doc,
                title: 'Export my data',
                subtitle: 'View and copy your account data as JSON',
                onTap: _busy || _owner == null ? null : _export),
            SettingsRow(
                icon: CupertinoIcons.person_crop_circle_badge_xmark,
                title: 'Delete account',
                subtitle: 'Permanently remove your account and its data',
                destructive: true,
                onTap: _busy || _owner == null ? null : _deleteAccount),
          ]),
          const SettingsNotice(
              'Deleting saved photos keeps your scan results. Delete account removes the account and its associated records.'),
        ],
      );
}

class _DataExportView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DataExportView({required this.data});

  @override
  Widget build(BuildContext context) {
    final json = const JsonEncoder.withIndent('  ').convert(data);
    return SettingsPage(
      title: 'Your data export',
      subtitle:
          'This export contains personal account data. Choose where you share it.',
      bottom: LiquidChromeButton(
          title: 'Copy JSON',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: json));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: FitnessText('Export copied')));
            }
          }),
      children: [
        SelectableText(json,
            style: const TextStyle(
                fontFamily: 'monospace',
                color: FitnessTheme.silver,
                fontSize: 12,
                height: 1.5))
      ],
    );
  }
}
