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

/// Always 12-hour, e.g. "6:00 PM", whatever the phone's 24-hour setting.
String formatReminderTime(BuildContext context, String hhmm) {
  final parts = hhmm.split(':').map(int.parse).toList();
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('h:mm a', locale)
      .format(DateTime(2000, 1, 1, parts[0], parts[1]));
}

const _mealDetails = {
  'BREAKFAST': 'If breakfast isn’t logged · {time}',
  'LUNCH': 'If lunch isn’t logged · {time}',
  'DINNER': 'If dinner isn’t logged · {time}',
  'SNACK': 'If a snack isn’t logged · {time}',
};

const _mealNames = {
  'BREAKFAST': 'Breakfast',
  'LUNCH': 'Lunch',
  'DINNER': 'Dinner',
  'SNACK': 'Snack',
};

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
  bool _busy = false, _localAlertsAvailable = false;

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
    // Device plugins are optional to viewing/saving the account's preferences.
    // A stale native binary or denied local-alert setup must not hide the page.
    try {
      await service.refresh();
    } catch (_) {/* Retry on the next refresh. */}
    var localAvailable = false;
    try {
      await rest.initialize();
      if (rest.available) {
        await rest.refresh();
        localAvailable = true;
      }
    } catch (_) {/* Account preferences remain available. */}
    if (mounted) setState(() => _localAlertsAvailable = localAvailable);
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

  Future<void> _save(Map<String, dynamic> changes) => _run(() async {
        final data = await repository.save(changes);
        if (mounted) setState(() => _preferences = data);
      });

  Future<void> _toggle(bool enabled) => _run(() async {
        final value =
            enabled ? await service.enable() : await service.disable();
        if (mounted) setState(() => _preferences = value);
      });

  String _time(String key) =>
      formatReminderTime(context, _preferences![key] as String);

  Future<void> _pickTime(String key, String title) async {
    final parts =
        (_preferences![key] as String).split(':').map(int.parse).toList();
    final value = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
        helpText: fitnessText(context, title),
        // Always show the 12-hour picker with AM/PM.
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: false),
            child: child!));
    if (value == null || !mounted) return;
    await _save({
      key:
          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
    });
  }

  Future<void> _pickMeal() async {
    final meal = await showModalBottomSheet<String>(
      context: context,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      backgroundColor: FitnessTheme.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final entry in _mealNames.entries)
          ListTile(
              title: FitnessText(entry.value),
              trailing: entry.key == _preferences!['mealType']
                  ? const Icon(CupertinoIcons.checkmark, size: 18)
                  : null,
              onTap: () => Navigator.pop(context, entry.key)),
        const SizedBox(height: 8),
      ])),
    );
    if (meal == null || !mounted) return;
    if (meal != _preferences!['mealType']) await _save({'mealType': meal});
    if (mounted) await _pickTime('mealTime', 'Meal reminder');
  }

  Widget _reminder(
          {required String key,
          required String title,
          required String detail,
          String? timeKey,
          required bool enabled,
          VoidCallback? onEdit}) =>
      ReminderRow(
          key: ValueKey('reminder-$key'),
          title: title,
          detail: detail,
          detailValues: timeKey == null ? const {} : {'time': _time(timeKey)},
          value: _preferences![key] == true,
          onEdit: enabled && !_busy && _preferences![key] == true
              ? onEdit
              : null,
          onChanged:
              enabled && !_busy ? (value) => _save({key: value}) : null);

  String? _trialDetail(Map<String, dynamic> preferences) {
    final billing = preferences['billingInfo'];
    if (billing is Map && billing['state'] == 'trial') {
      if (billing['trialSource'] == 'legacy') {
        return 'Trial ending · No automatic charge';
      }
      if (billing['trialSource'] == 'store') {
        return billing['cancelAtPeriodEnd'] == true
            ? 'Trial ending · Renewal cancelled'
            : 'Trial ending · Manage renewal in your app store';
      }
    }
    return null;
  }

  String _status(Map<String, dynamic> preferences, bool enabled, bool ready,
      DateTime? pause) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (!enabled) return fitnessText(context, 'Notifications are off.');
    if (pause != null) {
      return fitnessText(context, 'Paused until {date}, {time}.', values: {
        'date': DateFormat.MMMd(locale).format(pause.toLocal()),
        'time': DateFormat('h:mm a', locale).format(pause.toLocal()),
      });
    }
    final next = preferences['nextWorkoutReminder'];
    final date =
        next is Map ? DateTime.tryParse(next['date'] as String? ?? '') : null;
    if (ready && date != null && preferences['workouts'] == true) {
      return fitnessText(context, 'Next: {date} · {time} workout', values: {
        'date': DateFormat.MMMEd(locale).format(date),
        'time': formatReminderTime(context, next['time'] as String),
      });
    }
    return ready ? fitnessText(context, 'Notifications are on.') : '';
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    final enabled = preferences?['enabled'] == true;
    final ready =
        enabled && service.allowed && preferences?['deliveryReady'] == true;
    final pauseDate =
        DateTime.tryParse(preferences?['pausedUntil'] as String? ?? '');
    final pause =
        pauseDate != null && pauseDate.isAfter(DateTime.now()) ? pauseDate : null;
    final quietOff = preferences != null &&
        preferences['quietStart'] == preferences['quietEnd'];

    return SettingsPage(
        title: 'Notifications',
        subtitle: preferences == null
            ? ''
            : _status(preferences, enabled, ready, pause),
        children: [
          if (_error != null) ...[
            SettingsNotice(_error!, error: true),
            if (preferences == null)
              TextButton(onPressed: _load, child: const FitnessText('Retry')),
          ],
          if (preferences == null && _error == null)
            const Center(
                child: CircularProgressIndicator(color: FitnessTheme.silver)),
          if (preferences != null) ...[
            SettingsGroup(dividerIndent: 16, children: [
              ReminderRow(
                  key: const ValueKey('remote-notifications'),
                  title: 'Allow notifications',
                  detail: '',
                  value: enabled,
                  onChanged: _busy ? null : _toggle),
              if (enabled && service.configured && !service.allowed)
                SettingsRow(
                    title: 'Turned off in phone settings',
                    subtitle: 'Tap to allow Setcraft notifications',
                    onTap: () => AppSettings.openAppSettings(
                        type: AppSettingsType.notification)),
            ]),
            if (!service.configured)
              const SettingsNotice(
                  'Reminders aren’t available in this version. Rest timer alerts still work.')
            else if (enabled && preferences['deliveryReady'] != true)
              const SettingsNotice(
                  'Couldn’t reach the notification service. Try again later.'),
            SettingsGroup(dividerIndent: 16, title: 'Reminders', children: [
              _reminder(
                  key: 'workouts',
                  title: 'Workout reminders',
                  detail: 'Training days · {time}',
                  timeKey: 'workoutTime',
                  enabled: enabled,
                  onEdit: () => _pickTime('workoutTime', 'Workout reminders')),
              _reminder(
                  key: 'checkIns',
                  title: 'Daily check-in',
                  detail: 'How you slept and feel · {time}',
                  timeKey: 'checkInTime',
                  enabled: enabled,
                  onEdit: () => _pickTime('checkInTime', 'Daily check-in')),
              _reminder(
                  key: 'meals',
                  title: 'Meal reminder',
                  detail: _mealDetails[preferences['mealType']] ??
                      _mealDetails['LUNCH']!,
                  timeKey: 'mealTime',
                  enabled: enabled,
                  onEdit: _pickMeal),
              _reminder(
                  key: 'summaries',
                  title: 'Weekly summary',
                  detail: 'Sundays · {time}',
                  timeKey: 'summaryTime',
                  enabled: enabled,
                  onEdit: () => _pickTime('summaryTime', 'Weekly summary')),
              _reminder(
                  key: 'plans',
                  title: 'New weekly plan',
                  detail: 'When next week’s plan is ready',
                  enabled: enabled),
              _reminder(
                  key: 'billing',
                  title: 'Trial & billing',
                  detail: _trialDetail(preferences) ??
                      'Before your trial ends or access changes',
                  enabled: enabled),
            ]),
            const SettingsNotice(
                'Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.'),
            SettingsGroup(dividerIndent: 16, title: 'Quiet hours', children: [
              SettingsRow(
                  title: 'Quiet from',
                  value: _time('quietStart'),
                  onTap: _busy
                      ? null
                      : () => _pickTime('quietStart', 'Quiet hours start')),
              SettingsRow(
                  title: 'Quiet until',
                  value: _time('quietEnd'),
                  onTap: _busy
                      ? null
                      : () => _pickTime('quietEnd', 'Quiet hours end')),
            ]),
            SettingsNotice(quietOff
                ? 'Quiet hours are off. Set different times to turn them on.'
                : 'Reminders due during quiet hours arrive when they end.'),
            SettingsGroup(dividerIndent: 16, children: [
              SettingsRow(
                  title: pause != null ? 'Resume reminders' : 'Pause reminders',
                  subtitle: pause != null
                      ? 'Trial & billing alerts still arrive'
                      : 'Stop all reminders for 7 days',
                  onTap: !enabled || _busy
                      ? null
                      : () => _save({
                            'pausedUntil': pause != null
                                ? null
                                : DateTime.now()
                                    .add(const Duration(days: 7))
                                    .toUtc()
                                    .toIso8601String()
                          })),
            ]),
            if (rest.supported && _localAlertsAvailable)
              SettingsGroup(
                  dividerIndent: 16,
                  title: 'During workouts',
                  children: [
                    ReminderRow(
                        key: const ValueKey('rest-notifications'),
                        title: 'Rest timer alerts',
                        detail: 'When a rest timer you start ends',
                        value: rest.enabled,
                        onChanged: _busy
                            ? null
                            : (value) => _run(() async {
                                  await rest.setEnabled(value);
                                  if (mounted) setState(() {});
                                })),
                    if (rest.enabled && !rest.exactAllowed)
                      SettingsRow(
                          title: 'Precise timer alerts',
                          subtitle: 'Allow alerts at the exact second',
                          onTap: _busy
                              ? null
                              : () => _run(() async {
                                    await rest.requestPreciseTiming();
                                    if (mounted) setState(() {});
                                  })),
                  ]),
            SettingsGroup(dividerIndent: 16, title: 'This phone', children: [
              SettingsRow(
                  title: 'Phone notification settings',
                  onTap: () => AppSettings.openAppSettings(
                      type: AppSettingsType.notification)),
              SettingsRow(
                  title: _busy ? 'Please wait…' : 'Send test notification',
                  onTap: !ready || _busy
                      ? null
                      : () => _run(() async {
                            await repository
                                .test(await service.installationId());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: FitnessText(
                                          'Test sent. It should arrive shortly.')));
                            }
                          })),
            ]),
          ],
        ]);
  }
}

/// One reminder: title, a detail line (with its time) and a switch.
/// Tapping the text changes the time when [onEdit] is set.
class ReminderRow extends StatelessWidget {
  final String title, detail;
  final Map<String, Object> detailValues;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onEdit;
  const ReminderRow(
      {super.key,
      required this.title,
      required this.detail,
      this.detailValues = const {},
      required this.value,
      required this.onChanged,
      this.onEdit});

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Opacity(
      opacity: disabled ? .45 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
              child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEdit,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FitnessText(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    FitnessText(detail,
                        values: detailValues,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: onEdit != null
                                ? FitnessTheme.silver
                                : FitnessTheme.muted)),
                  ],
                ]),
          )),
          const SizedBox(width: 10),
          Semantics(
              label: title,
              child: CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: FitnessTheme.silver,
                  thumbColor: value ? Colors.black : Colors.white70)),
        ]),
      ),
    );
  }
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
