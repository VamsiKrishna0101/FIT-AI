import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/branding/setcraft_launch_screen.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/storage/local_cache.dart';
import '../components/onboarding_scaffold.dart';
import '../data/discovery_repository.dart';

/// Only mounted by the starter-onboarding gate, after a saved account/profile.
/// An optional marketing answer must never grant or obstruct membership access.
class DiscoveryOnboardingGate extends StatefulWidget {
  final Widget child;
  final DiscoveryRepository repository;
  final DiscoveryPreparation? preparation;
  const DiscoveryOnboardingGate(
      {super.key,
      required this.child,
      this.repository = const DiscoveryRepository(),
      this.preparation});

  @override
  State<DiscoveryOnboardingGate> createState() =>
      _DiscoveryOnboardingGateState();
}

class _DiscoveryOnboardingGateState extends State<DiscoveryOnboardingGate> {
  String? _owner, _selected, _error;
  bool _loading = true, _show = false, _saving = false;
  String get _cacheKey => 'discovery-completed-$_owner';

  @override
  void initState() {
    super.initState();
    final prepared = widget.preparation;
    if (prepared != null) {
      _owner = prepared.owner;
      _show = prepared.show;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<bool> _sameOwner() async =>
      mounted && _owner != null && await widget.repository.owner() == _owner;

  Future<void> _load() async {
    try {
      _owner = await widget.repository.owner();
      if (_owner == null) return;
      final local = await LocalCache.shared.getString(_cacheKey) == '1';
      final completed = local || await widget.repository.completed(_owner!);
      if (await _sameOwner()) setState(() => _show = !completed);
    } catch (_) {
      // If survey status cannot be checked, continue to the membership flow.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finish() async {
    if (!await _sameOwner()) return;
    try {
      await LocalCache.shared.saveString(_cacheKey, '1');
    } catch (_) {/* The server response still remembers completion. */}
    if (await _sameOwner()) setState(() => _show = false);
  }

  Future<void> _save() async {
    if (_saving || _selected == null || !await _sameOwner()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.save(_owner!, _selected);
      await _finish();
    } catch (_) {
      if (await _sameOwner()) {
        setState(() => _error = 'Could not save your answer. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _skip() async {
    if (_saving || !await _sameOwner()) return;
    final owner = _owner!;
    setState(() => _saving = true);
    // Skipping is immediate even offline. The idempotent endpoint remembers it
    // across devices when reachable; local completion is account-scoped.
    await _finish();
    unawaited(widget.repository.save(owner, null).catchError((Object _) {}));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => _loading
      ? const SetcraftLaunchScreen()
      : !_show
          ? widget.child
          : OnboardingScaffold(
              step: 8,
              showProgress: false,
              canPop: false,
              sectionLabel: 'Optional',
              title: 'Where did you first hear about Setcraft?',
              subtitle:
                  'Your answer helps us understand how people discover Setcraft.',
              actionTitle: 'Continue',
              onContinue: _selected == null || _saving ? null : _save,
              loading: _saving,
              actionMessage: _error,
              secondaryAction: TextButton(
                  key: const ValueKey('skip-discovery'),
                  onPressed: _saving ? null : _skip,
                  child: const FitnessText('Skip')),
              children: [
                for (final entry in const {
                  'INSTAGRAM': 'Instagram',
                  'TIKTOK': 'TikTok',
                  'YOUTUBE': 'YouTube',
                  'APP_STORE': 'App Store / Google Play',
                  'GOOGLE_SEARCH': 'Google search',
                  'FRIEND_FAMILY': 'Friend or family',
                  'OTHER': 'Other',
                  'DONT_REMEMBER': 'Don’t remember',
                }.entries)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: IgnorePointer(
                          ignoring: _saving,
                          child: OnboardingChoice(
                              key: ValueKey('discovery-${entry.key}'),
                              title: entry.value,
                              selected: _selected == entry.key,
                              onTap: () => setState(() {
                                    _selected = entry.key;
                                    _error = null;
                                  })))),
              ],
            );
}
