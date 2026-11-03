import '../../../core/theme/ds_motion.dart';
import 'package:app_settings/app_settings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../profile/views/settings_components.dart';
import '../repositories/notifications_repository.dart';
import '../services/notification_service.dart';
import '../services/rest_notification_service.dart';

String notificationError(Object error) {
  final data = error is DioException ? error.response?.data : null;
  if (data is Map && data['error'] is String) return data['error'] as String;
  if (error is StateError) return error.message.toString();
  return 'Could not save notification settings. Please try again.';
}

bool notificationTimeIsQuiet(String time, Map<String, dynamic> preferences) {
  int value(String time) {
    final parts = time.split(':').map(int.parse).toList();
    return parts[0] * 60 + parts[1];
  }

  final start = value(preferences['quietStart'] as String);
  final end = value(preferences['quietEnd'] as String);
  final current = value(time);
  return start != end &&
      (start < end
          ? current >= start && current < end
          : current >= start || current < end);
}

class NotificationSettingsView extends StatefulWidget {
  final NotificationsRepository? repository;
  final NotificationService? service;
  final RestNotificationService? restService;
  const NotificationSettingsView(
      {super.key, this.repository, this.service, this.restService});
  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView>
    with WidgetsBindingObserver {
  late final repository = widget.repository ?? NotificationsRepository();
  late final service = widget.service ?? NotificationService.shared;
  late final rest = widget.restService ?? RestNotificationService.shared;
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
      await rest.initialize();
      await rest.refresh();
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
        final value =
            enabled ? await service.enable() : await service.disable();
        if (mounted) setState(() => _preferences = value);
      });

  String _clock(String value) {
    final parts = value.split(':').map(int.parse).toList();
    return TimeOfDay(hour: parts[0], minute: parts[1]).format(context);
  }

  Future<void> _time(String key, String title) async {
    final parts =
        (_preferences![key] as String).split(':').map(int.parse).toList();
    final value = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
        helpText: fitnessText(context, title));
    if (value == null || !mounted) return;
    await _run(() async {
      final data = await repository.save({
        key:
            '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
      });
      if (mounted) setState(() => _preferences = data);
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
          subtitle: timeKey != null && _preferences![key] == true
              ? _clock(_preferences![timeKey] as String)
              : null,
          onTap:
              _busy ? null : () => _category(key, title, description, timeKey));

  String _trialDescription(Map<String, dynamic> preferences) {
    final billing = preferences['billingInfo'];
    if (billing is Map &&
        billing['state'] == 'trial' &&
        billing['trialSource'] == 'store') {
      return billing['cancelAtPeriodEnd'] == true
          ? 'Your trial ends soon. Your subscription is set to end without renewal.'
          : 'Your trial ends soon. Manage or cancel your subscription in your app store before renewal.';
    }
    if (billing is Map &&
        billing['state'] == 'trial' &&
        billing['trialSource'] == 'legacy') {
      return 'No automatic charge applies to your existing trial. Subscribe when you’re ready to keep going.';
    }
    return 'Get updates before your trial ends and when access changes.';
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    final enabled = preferences?['enabled'] == true;
    final ready =
        enabled && service.allowed && preferences?['deliveryReady'] == true;
    final pause =
        DateTime.tryParse(preferences?['pausedUntil'] as String? ?? '');
    final paused = pause != null && pause.isAfter(DateTime.now());
    final next = preferences?['nextWorkoutReminder'];
    final nextDate =
        next is Map ? DateTime.tryParse(next['date'] as String? ?? '') : null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final heroTitle = paused
        ? 'Paused'
        : ready && nextDate != null
            ? 'Next workout reminder'
            : ready
                ? 'Stay in your rhythm'
                : 'Your pace. Your reminders.';
    final heroBody = paused
        ? DateFormat.yMMMd(locale).add_jm().format(pause.toLocal())
        : ready && nextDate != null
            ? '${DateFormat.MMMEd(locale).format(nextDate)} · ${_clock(next['time'] as String)}'
            : ready && preferences?['workouts'] == true
                ? fitnessText(context, 'No upcoming workout reminder.')
                : fitnessText(
                    context,
                    ready
                        ? 'Notifications are on for this phone.'
                        : 'Choose what you want to hear from Setcraft.');

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
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [Color(0xFFF0F2F3), Color(0xFFA4ADB3)])),
                  child: Icon(
                      paused ? CupertinoIcons.pause : CupertinoIcons.bell,
                      color: const Color(0xFF202428),
                      size: 21)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    FitnessText(heroTitle,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.3)),
                    const SizedBox(height: 6),
                    Text(heroBody,
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
                  key: const ValueKey('remote-notifications'),
                  title: 'Allow notifications',
                  subtitle: 'You can change this anytime.',
                  value: enabled,
                  onChanged: _busy ? null : _toggle),
            ]),
            if (!service.configured)
              const SettingsNotice(
                  'Remote reminders are not available yet. Rest timer alerts still work on this phone.'),
            if (enabled && !service.allowed)
              const SettingsNotice(
                  'Notifications are blocked on this phone. Allow them in phone settings.'),
            if (service.configured && preferences['deliveryReady'] != true)
              const SettingsNotice(
                  'Reminders are temporarily unavailable. Please try again later.'),
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
                  CupertinoIcons.chart_bar,
                  'Weekly summary',
                  'summaries',
                  'A Sunday reminder to see your progress, when you have completed a workout that week.',
                  'summaryTime'),
              _row(
                  CupertinoIcons.moon,
                  'Daily check-in',
                  'checkIns',
                  'An optional reminder to log sleep and how you feel. Only for people who do not use a wearable.',
                  'checkInTime'),
              _row(
                  CupertinoIcons.cart,
                  'Meal reminder',
                  'meals',
                  'One reminder for your chosen meal, if you have not logged it yet.',
                  'mealTime'),
            ]),
            if (rest.supported)
              SettingsGroup(title: 'During workouts', children: [
                NotificationSwitch(
                    key: const ValueKey('rest-notifications'),
                    title: 'Rest timer alerts',
                    subtitle:
                        'Only for timers you start. Works while your phone is locked.',
                    value: rest.enabled,
                    onChanged: _busy
                        ? null
                        : (value) => _run(() async {
                              await rest.setEnabled(value);
                              if (mounted) setState(() {});
                            })),
                if (rest.enabled && !rest.exactAllowed)
                  SettingsRow(
                      icon: CupertinoIcons.timer,
                      title: 'Precise timer alerts',
                      subtitle:
                          'Allow alarms and reminders for on-time rest alerts.',
                      onTap: _busy
                          ? null
                          : () => _run(() async {
                                await rest.requestPreciseTiming();
                                if (mounted) setState(() {});
                              })),
              ]),
            SettingsGroup(title: 'Your quiet time', children: [
              SettingsRow(
                  icon: CupertinoIcons.moon_zzz,
                  title: 'Starts',
                  value: _clock(preferences['quietStart'] as String),
                  onTap: _busy
                      ? null
                      : () => _time('quietStart', 'Quiet hours start')),
              SettingsRow(
                  icon: CupertinoIcons.sun_max,
                  title: 'Ends',
                  value: _clock(preferences['quietEnd'] as String),
                  onTap: _busy
                      ? null
                      : () => _time('quietEnd', 'Quiet hours end')),
              SettingsRow(
                  icon: paused ? CupertinoIcons.play : CupertinoIcons.pause,
                  title: paused ? 'Resume reminders' : 'Pause reminders',
                  value: paused ? null : 'For 7 days',
                  onTap: !enabled || _busy
                      ? null
                      : () => _run(() async {
                            final data = await repository.save({
                              'pausedUntil': paused
                                  ? null
                                  : DateTime.now()
                                      .add(const Duration(days: 7))
                                      .toUtc()
                                      .toIso8601String()
                            });
                            if (mounted) setState(() => _preferences = data);
                          })),
            ]),
            SettingsNotice(preferences['quietStart'] == preferences['quietEnd']
                ? 'Quiet hours are off.'
                : 'Reminders during quiet hours arrive after quiet time ends.'),
            if (paused)
              const SettingsNotice(
                  'Account reminders stay on while training reminders are paused.'),
            const SettingsNotice(
                'Times follow your phone’s timezone. Up to two routine reminders a day; saved-plan updates arrive separately.'),
            SettingsGroup(title: 'Account', children: [
              _row(CupertinoIcons.creditcard, 'Trial and renewal reminders',
                  'billing', _trialDescription(preferences), null),
            ]),
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
              if (widget.timeKey != null &&
                  notificationTimeIsQuiet(
                      _preferences[widget.timeKey] as String, _preferences))
                const SettingsNotice(
                    'Reminders during quiet hours arrive after quiet time ends.'),
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
                                      fitnessText(context,
                                          '${slot[0]}${slot.substring(1).toLowerCase()}'),
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
      sheetAnimationStyle: DSMotion.sheetStyle(context),
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
