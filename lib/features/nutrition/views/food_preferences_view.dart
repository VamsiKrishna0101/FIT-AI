import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/fitness_form.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/theme/fitness_theme.dart';

class FoodPreferencesView extends StatefulWidget {
  const FoodPreferencesView({super.key});
  @override
  State<FoodPreferencesView> createState() => _FoodPreferencesViewState();
}

class _FoodPreferencesViewState extends State<FoodPreferencesView> {
  final _allergies = TextEditingController(),
      _dislikes = TextEditingController(),
      _custom = TextEditingController();
  String _style = 'NO_PREFERENCE';
  bool _loading = true, _busy = false, _loaded = false;
  String? _error, _owner;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final owner = await CacheScope.userId();
      final response = await ApiClient.shared
          .get<Map<String, dynamic>>(Endpoints.onboarding);
      if (!mounted || owner != await CacheScope.userId()) return;
      final j = response.data!['data'] as Map;
      _owner = owner;
      _style = j['eatingStyle'] as String? ?? 'NO_PREFERENCE';
      _allergies.text = (j['foodAllergies'] as List? ?? []).join(', ');
      _dislikes.text = (j['dislikedFoods'] as List? ?? []).join(', ');
      _custom.text = j['customEatingStyle'] as String? ?? '';
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load your preferences. Please retry.';
        });
      }
    }
  }

  List<String> _list(String text) => text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  Future<void> _save() async {
    final allergies = _list(_allergies.text), dislikes = _list(_dislikes.text);
    if (allergies.length > 20 ||
        dislikes.length > 20 ||
        [...allergies, ...dislikes].any((s) => s.length > 60) ||
        _custom.text.trim().length > 80) {
      setState(() => _error = 'Use up to 20 short food names in each field.');
      return;
    }
    if (await CacheScope.userId() != _owner) {
      if (mounted) {
        setState(
            () => _error = 'Your session changed. Reopen your preferences.');
      }
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiClient.shared.patch(Endpoints.onboarding, data: {
        'eatingStyle': _style,
        'customEatingStyle': _style == 'OTHER' ? _custom.text.trim() : null,
        'foodAllergies': allergies,
        'dislikedFoods': dislikes
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save. Your entry is still here. Try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _allergies.dispose();
    _dislikes.dispose();
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: PopScope(
          canPop: !_busy,
          child: Scaffold(
              appBar: AppBar(
                  backgroundColor: FitnessTheme.canvas,
                  title: const FitnessText('Food preferences',
                      style: TextStyle(fontSize: 18))),
              bottomNavigationBar: !_loaded
                  ? null
                  : SafeArea(
                      top: false,
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: FitnessSubmit(
                              label: 'Save preferences',
                              busy: _busy,
                              onPressed: _save))),
              body: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(padding: const EdgeInsets.all(20), children: [
                      const FitnessText('Make it yours',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      const FitnessText(
                          'Your eating style, allergies and foods you avoid.',
                          style: TextStyle(
                              color: FitnessTheme.muted,
                              fontSize: 14,
                              height: 1.5)),
                      const SizedBox(height: 28),
                      if (_loaded) ...[
                        DropdownButtonFormField<String>(
                            initialValue: _style,
                            decoration: const InputDecoration(
                        label: FitnessText('Eating style')),
                            items: const {
                              'NO_PREFERENCE': 'No preference',
                              'NON_VEGETARIAN': 'Non-vegetarian',
                              'VEGETARIAN': 'Vegetarian',
                              'VEGAN': 'Vegan',
                              'OTHER': 'Other'
                            }
                                .entries
                                .map((e) => DropdownMenuItem(
                                    value: e.key, child: FitnessText(e.value)))
                                .toList(),
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _style = v!)),
                        if (_style == 'OTHER') ...[
                          const SizedBox(height: 14),
                          FitnessInput(
                              label: 'Your eating style', controller: _custom)
                        ],
                        const SizedBox(height: 20),
                        FitnessInput(
                            label: 'Food allergies', controller: _allergies),
                        const SizedBox(height: 8),
                        const FitnessText('Separate foods with commas.',
                            style: TextStyle(
                                fontSize: 12, color: FitnessTheme.muted)),
                        const SizedBox(height: 20),
                        FitnessInput(
                            label: 'Foods you avoid', controller: _dislikes),
                        const SizedBox(height: 28),
                        const FitnessCard(
                            child: FitnessText(
                                'Preferences are saved to your profile. This library has nutrition values, but no verified ingredient or allergen labels. Check the actual label before choosing a food.',
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: FitnessTheme.muted))),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        FitnessText(_error!,
                            style: const TextStyle(color: FitnessTheme.coral)),
                        if (!_loaded)
                          TextButton(
                              onPressed: _load,
                              child: const FitnessText('Retry'))
                      ],
                    ]))));
}
