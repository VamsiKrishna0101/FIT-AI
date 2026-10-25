import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/components/premium_surface.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/mcp_repository.dart';
import 'settings_components.dart';

const _muted = TextStyle(color: FitnessTheme.muted, fontSize: 13, height: 1.5);
ButtonStyle get _primary => FilledButton.styleFrom(
    backgroundColor: FitnessTheme.silver,
    foregroundColor: FitnessTheme.canvas,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)));
String _date(BuildContext c, DateTime d) =>
    DateFormat.yMMMd(Localizations.localeOf(c).toLanguageTag())
        .format(d.toLocal());
void _notice(BuildContext c, String text) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));

class McpConnectionsView extends StatelessWidget {
  final McpRepository? repository;
  const McpConnectionsView({super.key, this.repository});
  @override
  Widget build(BuildContext context) => SettingsPage(
          title: 'MCP & integrations',
          subtitle: 'Your fitness context, connected on your terms.',
          children: [
            const PremiumSurface(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Icon(CupertinoIcons.link,
                      size: 30, color: FitnessTheme.silver),
                  SizedBox(height: 18),
                  Text('A connection you control',
                      style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.5)),
                  SizedBox(height: 10),
                  Text(
                      'Give an AI app the context you choose. Manage its access here, whenever you need.',
                      style: _muted),
                ])),
            const SizedBox(height: 26),
            SettingsGroup(title: 'AI apps', children: [
              SettingsRow(
                  icon: CupertinoIcons.sparkles,
                  title: 'Claude',
                  subtitle: 'Connect with a personal access token.',
                  value: 'Manage',
                  onTap: () => Navigator.push(
                      context,
                      AppPageRoute<void>(
                          page: ClaudeConnectionView(repository: repository)))),
              const SettingsRow(
                  icon: CupertinoIcons.bubble_left_bubble_right,
                  title: 'ChatGPT',
                  subtitle: 'An OAuth connection is planned separately.',
                  value: 'Coming soon'),
            ]),
            const SettingsNotice(
                'Creating a token does not connect an AI app automatically. You choose where to use it.'),
          ]);
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
  String? _owner, _error, _revoking;
  bool _loading = true;
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
        if (_owner != owner) _data = null;
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
    } catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _data = null;
          _loading = false;
          _error = McpRepository.message(e);
        });
      }
    }
  }

  Future<void> _create([McpAccessToken? previous]) async {
    final owner = _owner;
    if (owner == null || _data?.configured != true) return;
    await Navigator.push(
        context,
        AppPageRoute<bool>(
            page: CreateMcpTokenView(
                repository: _repo, owner: owner, replace: previous)));
    if (mounted) await _load();
  }

  Future<void> _revoke(McpAccessToken token) async {
    final owner = _owner;
    if (owner == null || _revoking != null) return;
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Revoke access?'),
                content: Text(
                    '“${token.name}” will stop working. You can create another token later.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Revoke'))
                ]));
    if (yes != true || !mounted) return;
    setState(() => _revoking = token.id);
    try {
      await _repo.revoke(token.id, expectedOwner: owner);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) _notice(context, McpRepository.message(e));
    } finally {
      if (mounted) setState(() => _revoking = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _data?.tokens.where((t) => t.active).length ?? 0;
    return SettingsPage(
        title: 'Claude',
        subtitle: 'Your training, with more context.',
        bottom: FilledButton(
            style: _primary,
            onPressed: !_loading && _data?.configured == true && active < 5
                ? () => _create()
                : null,
            child: const Text('Create access token')),
        children: [
          const PremiumSurface(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Icon(CupertinoIcons.sparkles,
                    size: 30, color: FitnessTheme.silver),
                SizedBox(height: 16),
                Text('Setcraft × Claude',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.7)),
                SizedBox(height: 10),
                Text(
                    'A clear view of your workouts. Only the details you choose to share.',
                    style: _muted),
                SizedBox(height: 16),
                Row(children: [
                  Icon(CupertinoIcons.lock_shield,
                      size: 16, color: FitnessTheme.silver),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('Read-only access · No body photos',
                          style: TextStyle(
                              fontSize: 12, color: FitnessTheme.silver)))
                ]),
              ])),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CupertinoActivityIndicator()))
          else if (_error != null) ...[
            SettingsNotice(_error!),
            TextButton(onPressed: _load, child: const Text('Try again'))
          ] else ...[
            if (_data?.configured != true)
              const SettingsNotice(
                  'Connection setup is temporarily unavailable. Please try again later.'),
            if (active >= 5)
              const SettingsNotice(
                  'Five active tokens. Revoke one or replace an existing token to continue.'),
            Row(children: [
              const Expanded(
                  child: Text('Your access tokens',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500))),
              Text('$active / 5 active',
                  style:
                      const TextStyle(color: FitnessTheme.muted, fontSize: 12))
            ]),
            const SizedBox(height: 12),
            if (_data?.tokens.isEmpty != false)
              const PremiumSurface(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Ready when you are',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Text(
                        'Create a token, then add it to your Claude connector settings. Nothing is shared until the connection is used.',
                        style: _muted),
                  ])),
            for (final token in _data?.tokens ?? <McpAccessToken>[]) ...[
              _card(context, token),
              const SizedBox(height: 12)
            ],
          ],
          const SizedBox(height: 22),
          const SettingsGroup(title: 'How to connect', children: [
            SettingsRow(
                icon: CupertinoIcons.lock,
                title: '1. Create a token',
                subtitle: 'Choose permissions and an expiry date.'),
            SettingsRow(
                icon: CupertinoIcons.link,
                title: '2. Add Setcraft in Claude',
                subtitle:
                    'Open Customize → Connectors → Add custom connector. Use the server URL.'),
            SettingsRow(
                icon: CupertinoIcons.doc_on_clipboard,
                title: '3. Add the request header',
                subtitle:
                    'Use Authorization as the name, and Bearer followed by a space and your token as its value. Choose fixed credentials, without OAuth sign-in.'),
          ]),
          if (_data?.serverUrl != null)
            OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: _data!.serverUrl!));
                  if (context.mounted) _notice(context, 'Server URL copied');
                },
                icon: const Icon(CupertinoIcons.link, size: 16),
                label: const Text('Copy server URL')),
          const SizedBox(height: 12),
          const SettingsNotice(
              'Use your personal Claude connection. A shared workspace credential can give other members access to the same Setcraft account.'),
        ]);
  }

  Widget _card(BuildContext c, McpAccessToken t) => PremiumSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(t.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w500))),
          const SizedBox(width: 10),
          Text(
              t.revokedAt != null
                  ? 'Revoked'
                  : t.expired
                      ? 'Expired'
                      : 'Active',
              style: const TextStyle(color: FitnessTheme.muted, fontSize: 12))
        ]),
        const SizedBox(height: 8),
        Text('•••• ${t.lastFour}',
            style: const TextStyle(
                fontSize: 12, color: FitnessTheme.muted, letterSpacing: 1)),
        const SizedBox(height: 12),
        Text(t.scopes.map((s) => mcpPermissions[s]?.$1 ?? s).join(' · '),
            style: const TextStyle(
                fontSize: 12, height: 1.5, color: FitnessTheme.silver)),
        const SizedBox(height: 10),
        Text('Expires ${_date(c, t.expiresAt)}', style: _muted),
        Text(
            t.lastUsedAt == null
                ? 'Not used yet'
                : 'Last used ${_date(c, t.lastUsedAt!)}',
            style: _muted),
        if (t.revokedAt == null) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            TextButton(
                onPressed: _revoking == null && _data?.configured == true
                    ? () => _create(t)
                    : null,
                child: const Text('Replace token')),
            TextButton(
                onPressed: _revoking == null ? () => _revoke(t) : null,
                child: Text(_revoking == t.id ? 'Revoking…' : 'Revoke'))
          ])
        ],
      ]));
}

class CreateMcpTokenView extends StatefulWidget {
  final McpRepository repository;
  final String owner;
  final McpAccessToken? replace;
  const CreateMcpTokenView(
      {super.key, required this.repository, required this.owner, this.replace});
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
    ]
  };
  int _days = 30;
  bool _busy = false;
  String? _error;
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
      if (mounted) {
        await Navigator.pushReplacement(
            context,
            AppPageRoute<bool>(
                page: McpTokenCreatedView(
                    repository: widget.repository, issued: issued)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = McpRepository.message(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SettingsPage(
          title:
              widget.replace == null ? 'Create access token' : 'Replace token',
          subtitle: 'Choose what this connection can read.',
          bottom: FilledButton(
              style: _primary,
              onPressed: _busy ? null : _submit,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_busy) ...[
                  const CupertinoActivityIndicator(radius: 8),
                  const SizedBox(width: 10)
                ],
                Flexible(
                    child: Text(
                        _busy
                            ? 'Creating…'
                            : widget.replace == null
                                ? 'Generate token'
                                : 'Create replacement',
                        textAlign: TextAlign.center))
              ])),
          children: [
            if (widget.replace != null)
              const SettingsNotice(
                  'Creating the replacement immediately revokes the old token. Update it in Claude afterwards.'),
            Form(
                key: _form,
                child: TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    maxLength: 60,
                    decoration: const InputDecoration(
                        labelText: 'Token name',
                        hintText: 'For example, My Claude'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter a name for this connection.'
                        : null)),
            const SizedBox(height: 22),
            SettingsGroup(title: 'Permissions', children: [
              for (final p in mcpPermissions.entries)
                Material(
                    color: Colors.transparent,
                    child: SwitchListTile.adaptive(
                        value: _scopes.contains(p.key),
                        onChanged: _busy
                            ? null
                            : (v) => setState(() {
                                  v
                                      ? _scopes.add(p.key)
                                      : _scopes.remove(p.key);
                                }),
                        activeTrackColor: FitnessTheme.silver,
                        title: Text(p.value.$1,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                            '${p.key == 'nutrition:read' || p.key == 'measurements:read' ? 'Optional. ' : ''}${p.value.$2}',
                            style: _muted)))
            ]),
            const Text('Expires after', style: _muted),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final days in [7, 30, 90])
                ChoiceChip(
                    label: Text('$days days'),
                    selected: _days == days,
                    selectedColor: FitnessTheme.silver,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        color: _days == days
                            ? FitnessTheme.canvas
                            : FitnessTheme.silver),
                    onSelected:
                        _busy ? null : (_) => setState(() => _days = days))
            ]),
            const SizedBox(height: 22),
            const SettingsNotice(
                'Read access only. No body photos, workout changes, billing access, or permission to create other tokens.'),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: _muted)),
          ]);
}

class McpTokenCreatedView extends StatefulWidget {
  final McpRepository repository;
  final McpIssuedToken issued;
  const McpTokenCreatedView(
      {super.key, required this.repository, required this.issued});
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

  @override
  Widget build(BuildContext context) => SettingsPage(
          title: 'Your access token',
          subtitle: 'One token. Only your chosen permissions.',
          bottom: FilledButton(
              style: _primary,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Done')),
          children: [
            PremiumSurface(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Icon(CupertinoIcons.checkmark_shield,
                      size: 32, color: FitnessTheme.silver),
                  const SizedBox(height: 18),
                  const Text('Ready to connect',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.5)),
                  const SizedBox(height: 10),
                  Text(widget.issued.token.name, style: _muted),
                  const SizedBox(height: 20),
                  Text(
                      _revealed
                          ? widget.issued.secret
                          : 'sc_mcp_••••••••${widget.issued.token.lastFour}',
                      key: const ValueKey('mcp-secret'),
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.7,
                          color: FitnessTheme.silver)),
                  TextButton.icon(
                      onPressed: () async {
                        try {
                          await widget.repository
                              .requireOwner(widget.issued.owner);
                          if (mounted) setState(() => _revealed = !_revealed);
                        } catch (_) {
                          if (context.mounted) {
                            _notice(context,
                                'Your account changed. Reopen AI connections.');
                          }
                        }
                      },
                      icon: Icon(
                          _revealed
                              ? CupertinoIcons.eye_slash
                              : CupertinoIcons.eye,
                          size: 17),
                      label: Text(_revealed ? 'Hide token' : 'Show token')),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                      style: _primary,
                      onPressed: _copying ? null : _copy,
                      icon: const Icon(CupertinoIcons.doc_on_doc, size: 17),
                      label: const Text('Copy token')),
                ])),
            const SizedBox(height: 18),
            const SettingsNotice(
                'Copy this token before leaving. We cannot show it again. If you lose it, replace it from your token list.'),
            const SizedBox(height: 18),
            Text('Expires ${_date(context, widget.issued.token.expiresAt)}',
                style: _muted),
            const SizedBox(height: 18),
            OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: widget.issued.serverUrl));
                  if (context.mounted) _notice(context, 'Server URL copied');
                },
                icon: const Icon(CupertinoIcons.link, size: 17),
                label: const Text('Copy server URL')),
            const SizedBox(height: 18),
            const SettingsNotice(
                'In Claude’s custom connector, add a request header named Authorization. Its value is Bearer, a space, then your token. Paste it into settings, never into a chat message.'),
          ]);
}
