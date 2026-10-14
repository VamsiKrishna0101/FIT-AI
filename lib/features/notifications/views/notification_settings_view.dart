import 'package:app_settings/app_settings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../profile/views/settings_components.dart';
import '../repositories/notifications_repository.dart';
import '../services/notification_service.dart';

String notificationError(Object error) {
  final data = error is DioException ? error.response?.data : null;
  if (data is Map && data['error'] is String) return data['error'] as String;
  if (error is StateError) return error.message.toString();
  return 'Could not save notification settings. Please try again.';
}

class NotificationSettingsView extends StatefulWidget {
  final NotificationsRepository? repository;
  final NotificationService? service;
  const NotificationSettingsView({super.key, this.repository, this.service});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView>
    with WidgetsBindingObserver {
  late final repository = widget.repository ?? NotificationsRepository();
  late final service = widget.service ?? NotificationService.shared;
  Map<String, dynamic>? _preferences;
  String? _error;
  bool _busy = false;

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
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      await service.refresh();
      final preferences = await repository.preferences();
      if (mounted) {
        setState(() {
          _preferences = preferences;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = notificationError(error));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = notificationError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(bool enabled) => _run(() async {
        final preferences =
            enabled ? await service.enable() : await service.disable();
        if (mounted) setState(() => _preferences = preferences);
      });

  Future<void> _time(String key, String title) async {
    final current = (_preferences![key] as String).split(':');
    final value = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: int.parse(current[0]), minute: int.parse(current[1])),
        helpText: title);
    if (value == null || !mounted) return;
    await _run(() async {
      final preferences = await repository.save({
        key:
            '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
      });
      if (mounted) setState(() => _preferences = preferences);
    });
  }

  Future<void> _category(
      String key, String title, String description, String? timeKey) async {
    await Navigator.push(
        context,
        AppPageRoute<void>(
            page: NotificationCategoryView(
          title: title,
          description: description,
          category: key,
          timeKey: timeKey,
          preferences: _preferences!,
          repository: repository,
        )));
    if (mounted) await _load();
  }

  SettingsRow _row(IconData icon, String title, String key, String description,
          String? timeKey) =>
      SettingsRow(
        icon: icon,
        title: title,
        value: _preferences![key] == true ? 'On' : 'Off',
        onTap: _busy ? null : () => _category(key, title, description, timeKey),
      );

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    final enabled = preferences?['enabled'] == true;
    final ready =
        enabled && service.allowed && preferences?['deliveryReady'] == true;

    return SettingsPage(
        title: 'Notifications',
        subtitle: 'A little support. At the right moment.',
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF26292C), Color(0xFF17191B)]),
            ),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [Color(0xFFF0F2F3), Color(0xFFA4ADB3)])),
                  child: const Icon(CupertinoIcons.bell,
                      color: Color(0xFF202428), size: 23)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    FitnessText(
                        ready
                            ? 'Stay in your rhythm'
                            : 'Your pace. Your reminders.',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.3)),
                    const SizedBox(height: 6),
                    FitnessText(
                        ready
                            ? 'Notifications are on for this phone.'
                            : 'Choose what you want to hear from FitAI.',
                        style: const TextStyle(
                            fontSize: 12,
                            color: FitnessTheme.muted,
                            height: 1.5)),
                  ])),
            ]),
          ),
          const SizedBox(height: 22),
          if (_error != null) ...[
            SettingsNotice(_error!, error: true),
            if (preferences == null)
              TextButton(onPressed: _load, child: const FitnessText('Retry')),
          ],
          if (preferences == null && _error == null)
            const Center(
                child: CircularProgressIndicator(color: FitnessTheme.silver)),
          if (preferences != null) ...[
            SettingsGroup(children: [
              NotificationSwitch(
                  title: 'Allow notifications',
                  subtitle: 'You can change this anytime.',
                  value: enabled,
                  onChanged: _busy ? null : _toggle),
            ]),
            if (!service.configured)
              const SettingsNotice(
                  'Push notifications are not configured for this build.'),
            if (enabled && !service.allowed)
              const SettingsNotice(
                  'Notifications are blocked on this phone. Allow them in phone settings.'),
            if (preferences['deliveryReady'] != true)
              const SettingsNotice('Push delivery is not ready on the server.'),
            SettingsGroup(title: 'Your reminders', children: [
              _row(
                  CupertinoIcons.flame,
                  'Workout reminders',
                  'workouts',
                  'On your planned training days, before you complete your workout.',
                  'workoutTime'),
              _row(
                  CupertinoIcons.sparkles,
                  'Weekly plans',
                  'plans',
                  'When your new plan is saved, and once your next week is available to generate.',
                  null),
              _row(
                  CupertinoIcons.moon,
                  'Daily check-in',
                  'checkIns',
                  'An optional reminder to log sleep and how you feel. Only for people who do not use a wearable.',
                  'checkInTime'),
              _row(
                  CupertinoIcons.chart_bar,
                  'Weekly summary',
                  'summaries',
                  'A Sunday reminder to see your progress, when you have completed a workout that week.',
                  'summaryTime'),
              _row(
                  CupertinoIcons.cart,
                  'Meal reminder',
                  'meals',
                  'One reminder for your chosen meal, if you have not logged it yet.',
                  'mealTime'),
            ]),
            SettingsGroup(title: 'Your quiet time', children: [
              SettingsRow(
                  icon: CupertinoIcons.moon_zzz,
                  title: 'Starts',
                  value: preferences['quietStart'] as String,
                  onTap: _busy
                      ? null
                      : () => _time('quietStart', 'Quiet hours start')),
              SettingsRow(
                  icon: CupertinoIcons.sun_max,
                  title: 'Ends',
                  value: preferences['quietEnd'] as String,
                  onTap: _busy
                      ? null
                      : () => _time('quietEnd', 'Quiet hours end')),
            ]),
            const SettingsNotice(
                'Times follow your phone’s timezone. Up to two routine reminders a day; saved-plan updates arrive separately.'),
            SettingsGroup(title: 'This phone', children: [
              SettingsRow(
                  icon: CupertinoIcons.bell,
                  title: 'Phone notification settings',
                  onTap: () => AppSettings.openAppSettings(
                      type: AppSettingsType.notification)),
              SettingsRow(
                  icon: CupertinoIcons.paperplane,
                  title: _busy ? 'Please wait…' : 'Send test notification',
                  subtitle: 'Check delivery on this phone',
                  onTap: !ready || _busy
                      ? null
                      : () => _run(() async {
                            await repository
                                .test(await service.installationId());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: FitnessText(
                                          'Test queued. It should arrive shortly.')));
                            }
                          })),
            ]),
          ],
        ]);
  }
}

class NotificationSwitch extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const NotificationSwitch(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                FitnessText(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                FitnessText(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted, height: 1.4)),
              ])),
          const SizedBox(width: 10),
          Semantics(
              label: title,
              child: CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: FitnessTheme.silver,
                  thumbColor:
                      value ? const Color(0xFF292D30) : Colors.white70)),
        ]),
      );
}

class NotificationCategoryView extends StatefulWidget {
  final String title, description, category;
  final String? timeKey;
  final Map<String, dynamic> preferences;
  final NotificationsRepository repository;
  const NotificationCategoryView(
      {super.key,
      required this.title,
      required this.description,
      required this.category,
      required this.timeKey,
      required this.preferences,
      required this.repository});

  @override
  State<NotificationCategoryView> createState() =>
      _NotificationCategoryViewState();
}

class _NotificationCategoryViewState extends State<NotificationCategoryView> {
  late Map<String, dynamic> _preferences = Map.from(widget.preferences);
  bool _busy = false;
  String? _error;

  Future<void> _save(Map<String, dynamic> changes) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preferences = await widget.repository.save(changes);
      if (mounted) setState(() => _preferences = preferences);
    } catch (error) {
      if (mounted) setState(() => _error = notificationError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _time() async {
    final key = widget.timeKey!;
    final current = (_preferences[key] as String).split(':');
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: int.parse(current[0]), minute: int.parse(current[1])));
    if (time != null && mounted) {
      await _save({
        key:
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
      });
    }
  }

  @override
  Widget build(BuildContext context) => SettingsPage(
          title: widget.title,
          subtitle: widget.description,
          children: [
            if (_error != null) SettingsNotice(_error!, error: true),
            SettingsGroup(children: [
              NotificationSwitch(
                  title: widget.title,
                  subtitle: 'Included when notifications are enabled.',
                  value: _preferences[widget.category] == true,
                  onChanged: _busy
                      ? null
                      : (value) => _save({widget.category: value})),
              if (widget.timeKey != null)
                SettingsRow(
                    icon: CupertinoIcons.clock,
                    title: 'Reminder time',
                    value: _preferences[widget.timeKey] as String,
                    onTap: _busy ? null : _time),
              if (widget.category == 'meals')
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      const Expanded(
                          child: FitnessText('Meal',
                              style: TextStyle(fontSize: 14))),
                      DropdownButton<String>(
                          value: _preferences['mealType'] as String,
                          underline: const SizedBox(),
                          items: ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK']
                              .map((slot) => DropdownMenuItem(
                                  value: slot,
                                  child: Text(
                                      '${slot[0]}${slot.substring(1).toLowerCase()}',
                                      style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: _busy
                              ? null
                              : (slot) {
                                  if (slot != null) _save({'mealType': slot});
                                }),
                    ])),
            ]),
            const SettingsNotice(
                'Quiet hours always apply. Completed activities do not need a reminder.'),
          ]);
}

Future<void> offerNotificationReminders(BuildContext context) async {
  final service = NotificationService.shared;
  await service.initialize();
  if (!service.configured) return;
  final owner = await SecureSessionStore.shared.userId;
  if (owner == null) return;
  final storage = await SharedPreferences.getInstance();
  final key = 'fitai_notification_offer_$owner';
  if (storage.getBool(key) == true) return;
  try {
    final preferences = await service.repository.preferences();
    if (preferences['enabled'] == true ||
        preferences['deliveryReady'] != true ||
        !context.mounted ||
        owner != await SecureSessionStore.shared.userId) {
      return;
    }
    await storage.setBool(key, true);
    if (!context.mounted) return;
    final enable = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: FitnessTheme.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(CupertinoIcons.bell,
                        size: 34, color: FitnessTheme.silver),
                    const SizedBox(height: 20),
                    const FitnessText('Stay on track',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.8)),
                    const SizedBox(height: 10),
                    const FitnessText(
                        'Get workout reminders and updates when your next plan is ready.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: FitnessTheme.muted,
                            fontSize: 14,
                            height: 1.5)),
                    const SizedBox(height: 24),
                    LiquidChromeButton(
                        title: 'Enable reminders',
                        showArrow: false,
                        onPressed: () => Navigator.pop(context, true)),
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const FitnessText('Later')),
                  ]))),
    );
    if (enable == true &&
        context.mounted &&
        owner == await SecureSessionStore.shared.userId) {
      if (!context.mounted) return;
      try {
        await service.enable();
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: FitnessText(notificationError(error))));
        }
      }
      if (!context.mounted || owner != await SecureSessionStore.shared.userId) {
        return;
      }
      if (!context.mounted) return;
      await Navigator.push(
          context, AppPageRoute<void>(page: const NotificationSettingsView()));
    }
  } catch (_) {
    // An optional invitation should never block access to a saved plan.
  }
}
