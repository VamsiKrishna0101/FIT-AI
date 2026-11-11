import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/settings_account_repository.dart';
import '../repositories/support_repository.dart';
import '../services/settings_device.dart';
import '../legal/legal_content.dart';
import 'ai_sharing_consent.dart';
import 'legal_document_view.dart';
import 'settings_components.dart';
import 'settings_editor_components.dart';
import '../../rating/views/rate_app_modal.dart';

Widget accountAction(String title, VoidCallback? onPressed,
        {bool busy = false}) =>
    FilledButton(
        style: FilledButton.styleFrom(
            backgroundColor: FitnessTheme.silver,
            foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF333333),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const CupertinoActivityIndicator(color: FitnessTheme.muted)
            : FitnessText(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)));
String _date(dynamic value) {
  final date = DateTime.tryParse('$value');
  return date == null
      ? ''
      : DateFormat('d MMM · h:mm a').format(date.toLocal());
}

class HelpSupportView extends StatefulWidget {
  final SupportRepository? repository;
  const HelpSupportView({super.key, this.repository});
  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView> {
  late final _repo = widget.repository ?? SupportRepository();
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic> _config = {}, _info = {};
  String? _cursor, _error;
  bool _loading = true, _more = false;
  @override
  void initState() {
    super.initState();
    _load();
    _appInfo();
  }

  Future<void> _appInfo() async {
    try {
      final info = await SettingsDevice.info();
      if (mounted) setState(() => _info = info);
    } catch (_) {/* No guessed version number on older native builds. */}
  }

  Future<void> _load({bool more = false}) async {
    if (more && _more) return;
    if (more) setState(() => _more = true);
    try {
      final data = await _repo.tickets(cursor: more ? _cursor : null);
      if (!mounted) return;
      setState(() {
        final rows = (data['tickets'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
        _tickets = more ? [..._tickets, ...rows] : rows;
        _cursor = data['nextCursor'] as String?;
        _error = null;
      });
      final config = await _repo.configuration();
      if (mounted) setState(() => _config = config);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = accountSettingsError(error);
          if (error is StateError) {
            _tickets = [];
            _config = {};
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _more = false;
        });
      }
    }
  }

  Future<void> _open(String id) async {
    await Navigator.push(context,
        AppPageRoute<void>(page: SupportTicketView(id: id, repository: _repo)));
    if (mounted) await _load();
  }

  Future<void> _create() async {
    final id = await Navigator.push<String>(context,
        AppPageRoute<String>(page: SupportTicketForm(repository: _repo)));
    if (id != null && mounted) {
      await _load();
      if (mounted) await _open(id);
    }
  }

  Future<void> _link(String url) async {
    try {
      await openSettingsLink(url);
    } catch (error) {
      if (mounted) setState(() => _error = accountSettingsError(error));
    }
  }

  @override
  Widget build(BuildContext context) =>
      SettingsPage(title: 'Help & Support', subtitle: '', children: [
        if (_error != null) SettingsNotice(_error!),
        accountAction('Raise a ticket', _create),
        const SizedBox(height: 24),
        Row(children: [
          const Expanded(
              child: FitnessText('Your tickets',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500))),
          TextButton(
              onPressed: () => _load(), child: const FitnessText('Refresh'))
        ]),
        if (_loading)
          const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CupertinoActivityIndicator()))
        else if (_tickets.isEmpty)
          const SettingsNotice('Your tickets will appear here.')
        else
          SettingsGroup(dividerIndent: 16, children: [
            for (final ticket in _tickets)
              SettingsRow(
                  title: ticket['subject'] as String,
                  subtitle:
                      '#${ticket['number']} · ${supportStatusLabels[ticket['status']] ?? ticket['status']}',
                  onTap: () => _open(ticket['id'] as String))
          ]),
        if (_cursor != null)
          TextButton(
              onPressed: _more ? null : () => _load(more: true),
              child: FitnessText(_more ? 'Loading…' : 'Load more tickets')),
        const SizedBox(height: 16),
        const SettingsDisclosure(
            title: 'Quick answers',
            summary: 'Plans, health and billing',
            children: [
              SettingsNotice(
                  'Missing health data? Check Health connection in Settings.'),
              SettingsNotice(
                  'Create your next plan after seven days. Previous weeks stay saved.'),
              SettingsNotice('Manage billing in Settings → Setcraft Premium.'),
            ]),
        SettingsGroup(dividerIndent: 16, children: [
          SettingsRow(
              title: 'Rate Setcraft',
              subtitle: 'Share your feedback or rate on the store',
              onTap: () => RateAppModal.show(context)),
          SettingsRow(
              title: 'Email support',
              subtitle: (_config['supportEmail'] as String?) ??
                  'support@setcraft.fit',
              onTap: () => _link(
                  'mailto:${(_config['supportEmail'] as String?) ?? 'support@setcraft.fit'}')),
          SettingsRow(
              title: 'Terms of Use',
              onTap: () => Navigator.push(
                  context,
                  AppPageRoute<void>(
                      page: const LegalDocumentView(document: termsOfUse)))),
          SettingsRow(
              title: 'Privacy Policy',
              onTap: () => Navigator.push(
                  context,
                  AppPageRoute<void>(
                      page:
                          const LegalDocumentView(document: privacyPolicy)))),
          SettingsRow(
              title: 'Setcraft',
              value: _info['appVersion'] is String
                  ? '${_info['appVersion']} (${_info['buildNumber']})'
                  : 'Version unavailable'),
        ]),
      ]);
}

class SupportTicketForm extends StatefulWidget {
  final SupportRepository repository;
  final String category;
  const SupportTicketForm(
      {super.key, required this.repository, this.category = 'OTHER'});
  @override
  State<SupportTicketForm> createState() => _SupportTicketFormState();
}

class _SupportTicketFormState extends State<SupportTicketForm> {
  final _form = GlobalKey<FormState>(),
      _subject = TextEditingController(),
      _body = TextEditingController();
  late String _category = widget.category;
  bool _busy = false, _diagnostics = false, _picking = false;
  SupportScreenshot? _screenshot;
  String? _error, _fingerprint, _requestId;
  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_picking || _busy) return;
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 80,
          requestFullMetadata: false);
      if (file == null) return;
      final image = SupportScreenshot(await file.readAsBytes());
      image.toJson();
      if (mounted) {
        setState(() {
          _screenshot = image;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is StateError
            ? error.message.toString()
            : 'Could not open this image. Choose a PNG or JPEG screenshot.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _send() async {
    if (_busy || _picking || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{
        'category': _category,
        'subject': _subject.text.trim(),
        'body': _body.text.trim(),
        if (_screenshot != null) 'screenshot': _screenshot!.toJson(),
        if (_diagnostics) 'diagnostics': await SettingsDevice.info()
      };
      final fingerprint = jsonEncode(payload);
      if (fingerprint != _fingerprint) {
        _fingerprint = fingerprint;
        _requestId = supportRequestId();
      }
      final ticket =
          await widget.repository.create({...payload, 'requestId': _requestId});
      if (mounted) Navigator.pop(context, ticket['id'] as String);
    } catch (error) {
      if (mounted) setState(() => _error = accountSettingsError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: SettingsPage(
          title: 'Raise a ticket',
          subtitle: '',
          bottom: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: accountAction('Send ticket', _send, busy: _busy)),
          children: [
            if (_error != null) SettingsNotice(_error!),
            Form(
                key: _form,
                child: Column(children: [
                  SettingsEditorSection(title: 'Ticket details', children: [
                    SettingsDropdown(
                        label: 'Topic',
                        value: _category,
                        choices: supportCategoryLabels,
                        fillColor: DSColors.bgElevated,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _category = v)),
                    TextFormField(
                        controller: _subject,
                        enabled: !_busy,
                        maxLength: 120,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: settingsFieldDecoration(context, 'Subject')
                            .copyWith(fillColor: DSColors.bgElevated),
                        validator: (v) => (v?.trim().length ?? 0) < 4
                            ? 'Add a subject of at least 4 characters.'
                            : null),
                    TextFormField(
                        controller: _body,
                        enabled: !_busy,
                        minLines: 5,
                        maxLines: 10,
                        maxLength: 4000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: settingsFieldDecoration(context, 'Message',
                                hint: 'What happened?')
                            .copyWith(fillColor: DSColors.bgElevated),
                        validator: (v) => (v?.trim().length ?? 0) < 10
                            ? 'Tell us a little more (at least 10 characters).'
                            : null),
                  ]),
                ])),
            SettingsGroup(dividerIndent: 16, children: [
              SettingsRow(
                  title: _screenshot == null
                      ? 'Add a screenshot'
                      : 'Screenshot attached',
                  subtitle: 'Optional · up to 1 MB',
                  onTap: _busy || _picking ? null : _pick,
                  trailingWidget: _screenshot == null
                      ? null
                      : TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _screenshot = null),
                          child: const FitnessText('Remove'))),
              SettingsRow(
                  title: 'Include app diagnostics',
                  subtitle: 'App version & phone OS',
                  trailingWidget: CupertinoSwitch(
                      value: _diagnostics,
                      activeTrackColor: Colors.white,
                      thumbColor: _diagnostics ? Colors.black : Colors.white,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _diagnostics = v))),
            ]),
            if (_screenshot != null)
              ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_screenshot!.bytes,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) => const SettingsNotice(
                          'Screenshot preview unavailable.'))),
            const SizedBox(height: 12),
            const SettingsNotice(
                'Remove private details before attaching a screenshot.'),
          ]));
}

class SupportTicketView extends StatefulWidget {
  final String id;
  final SupportRepository repository;
  const SupportTicketView(
      {super.key, required this.id, required this.repository});
  @override
  State<SupportTicketView> createState() => _SupportTicketViewState();
}

class _SupportTicketViewState extends State<SupportTicketView>
    with WidgetsBindingObserver {
  final _reply = TextEditingController();
  Map<String, dynamic>? _ticket;
  String? _error, _requestId, _lastBody;
  bool _busy = false, _loading = true, _refreshing = false, _foreground = true;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground && !_busy) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _reply.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final ticket = await widget.repository.ticket(widget.id);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = accountSettingsError(error));
    } finally {
      _refreshing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (_busy || body.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    if (body != _lastBody) {
      _requestId = supportRequestId();
      _lastBody = body;
    }
    try {
      await widget.repository
          .reply(widget.id, {'requestId': _requestId, 'body': body});
      _reply.clear();
      _requestId = null;
      _lastBody = null;
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = accountSettingsError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: SettingsPage(
          title:
              _ticket == null ? 'Your ticket' : 'Ticket #${_ticket!['number']}',
          subtitle: '',
          children: [
            if (_error != null) SettingsNotice(_error!),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CupertinoActivityIndicator()))
            else if (_ticket == null)
              TextButton(
                  onPressed: _load, child: const FitnessText('Retry loading'))
            else ...[
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      FitnessText(_ticket!['subject'] as String,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -.5)),
                      const SizedBox(height: 8),
                      FitnessText(supportStatusLabels[_ticket!['status']] ?? '',
                          style: const TextStyle(
                              color: FitnessTheme.muted, fontSize: 12))
                    ])),
                TextButton(
                    onPressed: _busy ? null : () => _load(),
                    child: const FitnessText('Refresh'))
              ]),
              const SizedBox(height: 22),
              for (final message in (_ticket!['messages'] as List).cast<Map>())
                _SupportMessage(
                    key: ValueKey(message['id']),
                    message: Map<String, dynamic>.from(message),
                    repository: widget.repository),
              const SizedBox(height: 12),
              if (_ticket!['status'] == 'RESOLVED')
                const SettingsNotice('Resolved. Reply to reopen.'),
              TextField(
                  controller: _reply,
                  key: const ValueKey('support-reply'),
                  enabled: !_busy,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: settingsFieldDecoration(context, 'Your reply')
                      .copyWith(fillColor: DSColors.bgElevated)),
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _reply,
                  builder: (_, value, child) => accountAction(
                      'Send reply', value.text.trim().isEmpty ? null : _send,
                      busy: _busy)),
            ],
          ]));
}

class _SupportMessage extends StatefulWidget {
  final Map<String, dynamic> message;
  final SupportRepository repository;
  const _SupportMessage(
      {super.key, required this.message, required this.repository});
  @override
  State<_SupportMessage> createState() => _SupportMessageState();
}

class _SupportMessageState extends State<_SupportMessage> {
  Uint8List? _image;
  bool _loading = false;
  String? _error;
  Future<void> _show(String id) async {
    setState(() => _loading = true);
    try {
      final image = await widget.repository.attachment(id);
      if (mounted) setState(() => _image = image);
    } catch (error) {
      if (mounted) setState(() => _error = accountSettingsError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.message['authorRole'] == 'ADMIN';
    return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            color: staff ? const Color(0xFF161618) : DSColors.bgElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DSColors.border, width: .7)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitnessText(staff ? 'Setcraft support' : 'You',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText(widget.message['body'] as String,
              style: const TextStyle(
                  color: FitnessTheme.silver, fontSize: 14, height: 1.6)),
          const SizedBox(height: 10),
          FitnessText(_date(widget.message['createdAt']),
              style: const TextStyle(color: FitnessTheme.muted, fontSize: 11)),
          if (_image == null)
            for (final attachment
                in (widget.message['attachments'] as List? ?? []))
              TextButton(
                  onPressed: _loading
                      ? null
                      : () => _show((attachment as Map)['id'] as String),
                  child:
                      FitnessText(_loading ? 'Loading…' : 'View screenshot')),
          if (_image != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_image!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stack) => const SettingsNotice(
                            'This screenshot could not be displayed.')))),
          if (_error != null) SettingsNotice(_error!),
        ]));
  }
}
