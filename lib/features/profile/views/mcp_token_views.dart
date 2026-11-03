import 'package:setcraft/core/theme/ds_motion.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/mcp_repository.dart';
import 'settings_components.dart';

ButtonStyle get _primary => FilledButton.styleFrom(
    backgroundColor: FitnessTheme.silver,
    foregroundColor: FitnessTheme.canvas,
    minimumSize: const Size(double.infinity, 50),
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
        title: 'MCP & Integrations',
        subtitle: '',
        children: [
          Container(
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
                  child: const Icon(CupertinoIcons.link,
                      size: 22, color: FitnessTheme.silver),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Model Context Protocol',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Secure AI client integrations',
                        style: TextStyle(
                          color: FitnessTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SettingsGroup(
            title: 'AI Apps',
            children: [
              SettingsRow(
                icon: CupertinoIcons.sparkles,
                title: 'Claude',
                subtitle: 'Personal access token',
                value: 'Manage',
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute<void>(
                    page: ClaudeConnectionView(repository: repository),
                  ),
                ),
              ),
              const SettingsRow(
                icon: CupertinoIcons.bubble_left_bubble_right,
                title: 'ChatGPT',
                subtitle: 'OAuth integration',
                value: 'Coming soon',
              ),
            ],
          ),
        ],
      );
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
        animationStyle: DSMotion.dialogStyle(context),
        context: context,
        builder: (c) => AlertDialog(
                backgroundColor: FitnessTheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Revoke access?'),
                content: Text(
                    '“${token.name}” will stop working. You can create another token later.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Revoke',
                          style: TextStyle(color: FitnessTheme.coral)))
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
      subtitle: '',
      bottom: FilledButton(
          style: _primary,
          onPressed: !_loading && _data?.configured == true && active < 5
              ? () => _create()
              : null,
          child: const Text('Create access token')),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                child: const Icon(CupertinoIcons.sparkles,
                    size: 22, color: FitnessTheme.silver),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setcraft × Claude',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Read-only access · No body photos',
                      style: TextStyle(
                        fontSize: 12,
                        color: FitnessTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your access tokens',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '$active / 5 active',
                  style: const TextStyle(
                    color: FitnessTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_data?.tokens.isEmpty != false)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DSColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DSColors.border, width: .7),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.shield,
                        size: 18, color: FitnessTheme.silver),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready when you are',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Create a token to connect with Claude.',
                          style: TextStyle(
                            fontSize: 12,
                            color: FitnessTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          for (final token in _data?.tokens ?? <McpAccessToken>[]) ...[
            _card(context, token),
            const SizedBox(height: 12)
          ],
        ],
        const SizedBox(height: 20),
        SettingsGroup(
          title: 'Setup Guide',
          children: [
            const SettingsRow(
              icon: CupertinoIcons.lock,
              title: '1. Create a token',
              subtitle: 'Choose permissions and expiry date',
            ),
            const SettingsRow(
              icon: CupertinoIcons.link,
              title: '2. Add connector in Claude',
              subtitle: 'Customize → Connectors → Add custom',
            ),
            const SettingsRow(
              icon: CupertinoIcons.doc_on_clipboard,
              title: '3. Add Authorization header',
              subtitle: 'Bearer followed by your access token',
            ),
            if (_data?.serverUrl != null)
              SettingsRow(
                icon: CupertinoIcons.link,
                title: 'Copy server URL',
                value: 'Copy',
                onTap: () async {
                  await Clipboard.setData(
                      ClipboardData(text: _data!.serverUrl!));
                  if (context.mounted) _notice(context, 'Server URL copied');
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _card(BuildContext c, McpAccessToken t) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DSColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DSColors.border, width: .7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.revokedAt != null
                        ? 'Revoked'
                        : t.expired
                            ? 'Expired'
                            : 'Active',
                    style: TextStyle(
                      color: t.revokedAt != null || t.expired
                          ? FitnessTheme.muted
                          : FitnessTheme.silver,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '•••• ${t.lastFour}',
              style: const TextStyle(
                fontSize: 12,
                color: FitnessTheme.muted,
                letterSpacing: 1,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t.scopes.map((s) => mcpPermissions[s]?.$1 ?? s).join(' · '),
              style: const TextStyle(
                fontSize: 12,
                color: FitnessTheme.silver,
              ),
            ),
            const SizedBox(height: 6),
            Text('Expires ${_date(c, t.expiresAt)}',
                style:
                    const TextStyle(color: FitnessTheme.muted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              t.lastUsedAt == null
                  ? 'Not used yet'
                  : 'Last used ${_date(c, t.lastUsedAt!)}',
              style: const TextStyle(color: FitnessTheme.muted, fontSize: 11),
            ),
            if (t.revokedAt == null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0x14FFFFFF)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: _revoking == null && _data?.configured == true
                        ? () => _create(t)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: FitnessTheme.silver,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('Replace token',
                        style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: _revoking == null ? () => _revoke(t) : null,
                    style: TextButton.styleFrom(
                      foregroundColor: FitnessTheme.coral,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(
                      _revoking == t.id ? 'Revoking…' : 'Revoke',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
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
        title: widget.replace == null ? 'Create access token' : 'Replace token',
        subtitle: '',
        bottom: FilledButton(
          style: _primary,
          onPressed: _busy ? null : _submit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_busy) ...[
                const CupertinoActivityIndicator(radius: 8),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  _busy
                      ? 'Creating…'
                      : widget.replace == null
                          ? 'Generate token'
                          : 'Create replacement',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        children: [
          Form(
            key: _form,
            child: TextFormField(
              controller: _name,
              enabled: !_busy,
              maxLength: 60,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: DSColors.bgCard,
                labelText: 'Token name',
                labelStyle: const TextStyle(color: FitnessTheme.muted),
                hintText: 'For example, My Claude',
                hintStyle: const TextStyle(color: DSColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: DSColors.border, width: .7),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: DSColors.border, width: .7),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: FitnessTheme.silver, width: 1),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a name for this connection.'
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          SettingsGroup(
            title: 'Permissions',
            children: [
              for (final p in mcpPermissions.entries)
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile.adaptive(
                    value: _scopes.contains(p.key),
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                              v ? _scopes.add(p.key) : _scopes.remove(p.key);
                            }),
                    activeTrackColor: FitnessTheme.silver,
                    title: Text(
                      p.value.$1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      p.value.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        color: FitnessTheme.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'EXPIRES AFTER',
              style: TextStyle(
                color: DSColors.textTertiary,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final days in [7, 30, 90])
                ChoiceChip(
                  label: Text('$days days'),
                  selected: _days == days,
                  selectedColor: FitnessTheme.silver,
                  backgroundColor: DSColors.bgCard,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _days == days ? Colors.white : DSColors.border,
                      width: .7,
                    ),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _days == days
                        ? FitnessTheme.canvas
                        : FitnessTheme.silver,
                  ),
                  onSelected:
                      _busy ? null : (_) => setState(() => _days = days),
                ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  style: const TextStyle(color: FitnessTheme.coral)),
            ),
        ],
      );
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
        title: 'Access token',
        subtitle: '',
        bottom: FilledButton(
          style: _primary,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Done'),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DSColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DSColors.border, width: .7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.checkmark_shield,
                      size: 24, color: FitnessTheme.silver),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ready to connect',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.issued.token.name,
                  style: const TextStyle(
                    color: FitnessTheme.silver,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.035),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _revealed
                              ? widget.issued.secret
                              : 'sc_mcp_••••••••${widget.issued.token.lastFour}',
                          key: const ValueKey('mcp-secret'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: FitnessTheme.silver,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: FitnessTheme.silver,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
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
                          size: 16,
                        ),
                        label: Text(
                          _revealed ? 'Hide token' : 'Show token',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: _primary,
                  onPressed: _copying ? null : _copy,
                  icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 16),
                  label: const Text('Copy token'),
                ),
              ],
            ),
          ),
        ],
      );
}
