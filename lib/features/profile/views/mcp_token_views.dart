import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/mcp_repository.dart';
import 'settings_components.dart';
import 'settings_editor_components.dart';

ButtonStyle get _primary => FilledButton.styleFrom(
    backgroundColor: FitnessTheme.silver,
    foregroundColor: FitnessTheme.canvas,
    minimumSize: const Size(double.infinity, 50),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
String _date(BuildContext c, DateTime d) =>
    DateFormat.yMMMd(Localizations.localeOf(c).toLanguageTag())
        .format(d.toLocal());
void _notice(BuildContext c, String text) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));

/// Settings opens the manager directly, without an intermediate provider menu.
class McpConnectionsView extends StatelessWidget {
  final McpRepository? repository;
  const McpConnectionsView({super.key, this.repository});

  @override
  Widget build(BuildContext context) =>
      ClaudeConnectionView(repository: repository);
}

class ClaudeConnectionView extends StatefulWidget {
  final McpRepository? repository;
  const ClaudeConnectionView({super.key, this.repository});
  @override
  State<ClaudeConnectionView> createState() => _ClaudeConnectionViewState();
}

class _ClaudeConnectionViewState extends State<ClaudeConnectionView>
    with WidgetsBindingObserver {
  late final _repo = widget.repository ?? McpRepository();
  McpTokenList? _data;
  McpIssuedToken? _issued;
  McpAccessToken? _replacement;
  String? _owner, _error, _revoking;
  bool _loading = true, _editing = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final owner = await _repo.currentOwner();
      if (!mounted || request != _request) return;
      setState(() {
        if (_owner != owner) {
          _data = null;
          _issued = null;
          _editing = false;
          _replacement = null;
        }
        _owner = owner;
        _loading = true;
        _error = null;
      });
      final data = await _repo.load();
      await _repo.requireOwner(owner);
      if (mounted && request == _request) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _data = null;
          _loading = false;
          _error = McpRepository.message(error);
        });
      }
    }
  }

  void _create([McpAccessToken? previous]) {
    if (_owner == null || _data?.configured != true) return;
    setState(() {
      _replacement = previous;
      _editing = true;
    });
  }

  Future<void> _finish() async {
    setState(() {
      _issued = null;
      _replacement = null;
      _editing = false;
    });
    await _load();
  }

  Future<void> _revoke(McpAccessToken token) async {
    final owner = _owner;
    if (owner == null || _revoking != null) return;
    final yes = await confirmSettingsAction(context,
        title: 'Revoke access?',
        message:
            '“${token.name}” will stop working. You can create another token later.',
        action: 'Revoke',
        destructive: true);
    if (!yes || !mounted) return;
    setState(() => _revoking = token.id);
    try {
      await _repo.revoke(token.id, expectedOwner: owner);
      if (mounted) await _load();
    } catch (error) {
      if (mounted) _notice(context, McpRepository.message(error));
    } finally {
      if (mounted) setState(() => _revoking = null);
    }
  }

  Future<void> _copyUrl() async {
    final url = _data?.serverUrl, owner = _owner;
    if (url == null || owner == null) return;
    try {
      await _repo.requireOwner(owner);
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) _notice(context, 'Server URL copied');
    } catch (error) {
      if (mounted) _notice(context, McpRepository.message(error));
    }
  }

  Widget _token(McpAccessToken token) {
    final status = token.revokedAt != null
        ? 'Revoked'
        : token.expired
            ? 'Expired'
            : 'Active';
    return ExpansionTile(
      key: ValueKey('mcp-token-${token.id}'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(token.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$status · Expires ${_date(context, token.expiresAt)}',
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: FitnessTheme.muted))),
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•••• ${token.lastFour}',
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted)),
                const SizedBox(height: 10),
                Text(
                    token.scopes
                        .map((scope) => mcpPermissions[scope]?.$1 ?? scope)
                        .join(' · '),
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: FitnessTheme.silver)),
                const SizedBox(height: 8),
                Text(
                    token.lastUsedAt == null
                        ? 'Not used yet'
                        : 'Last used ${_date(context, token.lastUsedAt!)}',
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted)),
                if (token.revokedAt == null)
                  Wrap(spacing: 12, children: [
                    TextButton(
                        onPressed:
                            _revoking == null && _data?.configured == true
                                ? () => _create(token)
                                : null,
                        child: const FitnessText('Replace token')),
                    TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: FitnessTheme.coral),
                        onPressed:
                            _revoking == null ? () => _revoke(token) : null,
                        child: FitnessText(
                            _revoking == token.id ? 'Revoking…' : 'Revoke')),
                  ]),
              ],
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _data?.tokens.where((token) => token.active).length ?? 0;
    return SettingsPage(
      title: 'MCP',
      centerTitle: true,
      subtitle: '',
      bottom: _editing || _issued != null
          ? null
          : FilledButton(
              key: const ValueKey('mcp-create'),
              style: _primary,
              onPressed: !_loading && _data?.configured == true && active < 5
                  ? () => _create()
                  : null,
              child: const FitnessText('Create access token',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
      children: [
        if (_issued != null)
          McpTokenCreatedView(
              repository: _repo,
              issued: _issued!,
              embedded: true,
              onDone: _finish)
        else if (_editing && _owner != null)
          CreateMcpTokenView(
            key: ValueKey(_replacement?.id ?? 'mcp-new-token'),
            repository: _repo,
            owner: _owner!,
            replace: _replacement,
            embedded: true,
            onCancel: () => setState(() {
              _editing = false;
              _replacement = null;
            }),
            onCreated: (issued) => setState(() {
              _issued = issued;
              _editing = false;
            }),
          )
        else ...[
          const SettingsEditorSection(title: 'Claude', children: [
            FitnessText('Read-only access to the data you choose.',
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: FitnessTheme.silver)),
            FitnessText('Body photos are never shared.',
                style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          ]),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CupertinoActivityIndicator()))
          else if (_error != null) ...[
            SettingsNotice(_error!, error: true),
            TextButton(onPressed: _load, child: const FitnessText('Try again')),
          ] else ...[
            if (_data?.configured != true)
              const SettingsNotice(
                  'Connection setup is temporarily unavailable. Please try again later.'),
            if (active >= 5)
              const SettingsNotice(
                  'Five active tokens. Revoke one or replace an existing token to continue.'),
            if (_data?.tokens.isEmpty != false)
              const SettingsNotice(
                  'No access tokens. Create one to set up Claude.')
            else
              SettingsGroup(
                  title: 'Access tokens',
                  dividerIndent: 16,
                  children: [for (final token in _data!.tokens) _token(token)]),
          ],
          SettingsDisclosure(
            title: 'How to connect',
            summary: 'Claude setup · MCP',
            children: [
              const FitnessText(
                  '1. Create an access token.\n2. Add the server URL in Claude.\n3. Set the Authorization header to Bearer followed by your token.',
                  style: TextStyle(
                      fontSize: 13, height: 1.7, color: FitnessTheme.silver)),
              if (_data?.serverUrl != null) ...[
                SelectableText(_data!.serverUrl!,
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted)),
                TextButton(
                    onPressed: _copyUrl,
                    child: const FitnessText('Copy server URL')),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class CreateMcpTokenView extends StatefulWidget {
  final McpRepository repository;
  final String owner;
  final McpAccessToken? replace;
  final bool embedded;
  final ValueChanged<McpIssuedToken>? onCreated;
  final VoidCallback? onCancel;
  const CreateMcpTokenView(
      {super.key,
      required this.repository,
      required this.owner,
      this.replace,
      this.embedded = false,
      this.onCreated,
      this.onCancel});
  @override
  State<CreateMcpTokenView> createState() => _CreateMcpTokenViewState();
}

class _CreateMcpTokenViewState extends State<CreateMcpTokenView> {
  final _form = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.replace?.name ?? 'My Claude');
  late final _scopes = <String>{
    ...?widget.replace?.scopes,
    if (widget.replace == null) ...[
      'training:read',
      'plans:read',
      'workouts:read'
    ],
  };
  int _days = 30;
  bool _busy = false;
  String? _error;
  McpIssuedToken? _issued;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_scopes.isEmpty) {
      setState(() => _error = 'Choose at least one permission.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final issued = await widget.repository.create(
          expectedOwner: widget.owner,
          name: _name.text,
          scopes: _scopes.toList(),
          days: _days,
          replaceId: widget.replace?.id);
      if (!mounted) return;
      if (widget.onCreated != null) {
        widget.onCreated!(issued);
      } else {
        setState(() => _issued = issued);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = McpRepository.message(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_issued != null) {
      return McpTokenCreatedView(
          repository: widget.repository, issued: _issued!);
    }
    final title =
        widget.replace == null ? 'Create access token' : 'Replace token';
    final action = FilledButton(
      key: const ValueKey('mcp-generate'),
      style: _primary,
      onPressed: _busy ? null : _submit,
      child: _busy
          ? const CupertinoActivityIndicator(color: FitnessTheme.canvas)
          : FitnessText(
              widget.replace == null ? 'Generate token' : 'Create replacement',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
    final children = <Widget>[
      if (widget.embedded) ...[
        FitnessText(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 18),
      ],
      Form(
        key: _form,
        child: SettingsEditorSection(title: 'Connection', children: [
          TextFormField(
            controller: _name,
            enabled: !_busy,
            maxLength: 60,
            style: const TextStyle(fontSize: 14, color: FitnessTheme.silver),
            decoration: settingsFieldDecoration(context, 'Token name')
                .copyWith(counterText: ''),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a name for this connection.'
                : null,
          ),
          SettingsDropdown(
              key: const ValueKey('mcp-expiry'),
              label: 'Expires after',
              value: _days.toString(),
              choices: const {'7': '7 days', '30': '30 days', '90': '90 days'},
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _days = int.parse(value))),
        ]),
      ),
      SettingsDisclosure(
        key: const ValueKey('mcp-permissions'),
        title: 'Permissions',
        summary: _scopes.isEmpty
            ? 'Choose at least one permission'
            : _scopes
                .map((scope) => mcpPermissions[scope]?.$1 ?? scope)
                .join(' · '),
        children: [
          for (final permission in mcpPermissions.entries)
            SwitchListTile.adaptive(
              key: ValueKey('mcp-permission-${permission.key}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _scopes.contains(permission.key),
              activeTrackColor: Colors.white,
              activeThumbColor: FitnessTheme.canvas,
              inactiveThumbColor: FitnessTheme.silver,
              title: FitnessText(permission.value.$1,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                        value
                            ? _scopes.add(permission.key)
                            : _scopes.remove(permission.key);
                      }),
            ),
        ],
      ),
      const SettingsNotice('Read-only access. Body photos are never shared.'),
      if (_error != null) SettingsNotice(_error!, error: true),
      if (widget.embedded) ...[
        action,
        const SizedBox(height: 8),
        TextButton(
            onPressed: _busy ? null : widget.onCancel,
            child: const FitnessText('Cancel')),
      ],
    ];
    return PopScope(
      canPop: !_busy,
      child: widget.embedded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children)
          : SettingsPage(
              title: title,
              centerTitle: true,
              subtitle: '',
              bottom: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: action),
              children: children),
    );
  }
}

class McpTokenCreatedView extends StatefulWidget {
  final McpRepository repository;
  final McpIssuedToken issued;
  final bool embedded;
  final VoidCallback? onDone;
  const McpTokenCreatedView(
      {super.key,
      required this.repository,
      required this.issued,
      this.embedded = false,
      this.onDone});
  @override
  State<McpTokenCreatedView> createState() => _McpTokenCreatedViewState();
}

class _McpTokenCreatedViewState extends State<McpTokenCreatedView>
    with WidgetsBindingObserver {
  bool _revealed = false, _copying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(McpClipboard.protectScreen(true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(McpClipboard.protectScreen(false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => _revealed = false);
    }
  }

  Future<void> _copy() async {
    if (_copying) return;
    setState(() => _copying = true);
    try {
      await widget.repository.requireOwner(widget.issued.owner);
      await McpClipboard.copySecret(widget.issued.secret);
      if (mounted) _notice(context, 'Token copied');
    } catch (_) {
      if (mounted) {
        _notice(context,
            'Could not copy this token. Check your session and try again.');
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _reveal() async {
    try {
      await widget.repository.requireOwner(widget.issued.owner);
      if (mounted) setState(() => _revealed = !_revealed);
    } catch (_) {
      if (mounted) {
        _notice(context, 'Your account changed. Reopen MCP.');
      }
    }
  }

  Future<void> _copyUrl() async {
    try {
      await widget.repository.requireOwner(widget.issued.owner);
      await Clipboard.setData(ClipboardData(text: widget.issued.serverUrl));
      if (mounted) _notice(context, 'Server URL copied');
    } catch (_) {
      if (mounted) {
        _notice(context, 'Could not copy the server URL. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = FilledButton(
        style: _primary,
        onPressed: widget.onDone ?? () => Navigator.pop(context, true),
        child: const FitnessText('Done'));
    final children = <Widget>[
      SettingsEditorSection(title: 'Ready to connect', children: [
        Text(widget.issued.token.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const FitnessText('Copy this token now. It is shown only once.',
            style: TextStyle(
                fontSize: 13, height: 1.5, color: FitnessTheme.muted)),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: FitnessTheme.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FitnessTheme.line)),
          child: Text(
              _revealed
                  ? widget.issued.secret
                  : 'sc_mcp_••••••••${widget.issued.token.lastFour}',
              key: const ValueKey('mcp-secret'),
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                  color: FitnessTheme.silver)),
        ),
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                onPressed: _reveal,
                child: FitnessText(_revealed ? 'Hide token' : 'Show token'))),
        FilledButton(
            style: _primary,
            onPressed: _copying ? null : _copy,
            child: const FitnessText('Copy token')),
      ]),
      SettingsDisclosure(
        title: 'Server URL',
        summary: 'Use with your access token',
        children: [
          SelectableText(widget.issued.serverUrl,
              style: const TextStyle(fontSize: 12, color: FitnessTheme.silver)),
          TextButton(
              onPressed: _copyUrl, child: const FitnessText('Copy server URL')),
        ],
      ),
      if (widget.embedded) ...[const SizedBox(height: 8), done],
    ];
    return widget.embedded
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
        : SettingsPage(
            title: 'Access token',
            centerTitle: true,
            subtitle: '',
            bottom: done,
            children: children);
  }
}
