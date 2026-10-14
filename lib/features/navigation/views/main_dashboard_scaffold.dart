import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/components/animated_tab_stack.dart';
import '../../../core/components/liquid_silver_bottom_bar.dart';
import '../../../core/localization/fitai_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../../core/cache/app_data_mode.dart';
import '../../../core/health/health_sync_service.dart';
import '../../../core/health/phone_sleep_service.dart';
import '../../wellness/repositories/wellness_repository.dart';
import '../../body_scan/views/body_view.dart';
import '../../history/views/progress_view.dart';
import '../../profile/views/profile_view.dart';
import '../../today/views/today_home_view.dart';
import '../../train/views/train_view.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/storage/secure_session_store.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/views/notification_settings_view.dart';
import '../../planner/views/weekly_plan_view.dart';
import '../../wellness/views/sleep_entry_view.dart';
import '../../nutrition/views/food_library_view.dart';
import '../../today/repositories/today_repository.dart';
import '../../subscription/subscription_gate.dart';
import '../../subscription/subscription_view.dart';
import '../../subscription/subscription_service.dart';

class MainDashboardScaffold extends StatefulWidget {
  final int initialIndex;

  const MainDashboardScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainDashboardScaffold> createState() => _MainDashboardScaffoldState();
}

class _MainDashboardScaffoldState extends State<MainDashboardScaffold>
    with WidgetsBindingObserver {
  late int _currentIndex;
  final Set<int> _visitedTabs = {0};
  bool _modeReady = false;
  StreamSubscription<Map<String, String>>? _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
        HealthSyncService.shared.syncIfEnabled().catchError((Object _) {}));
    unawaited(_resumePhoneSleep());
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _visitedTabs.add(_currentIndex);
    AppDataMode.shared.addListener(_datasetChanged);
    SubscriptionService.shared.addListener(_datasetChanged);
    unawaited(_initializeMode());
    _notifications =
        NotificationService.shared.opened.listen((_) => _takeNotification());
    unawaited(NotificationService.shared.refresh());
  }

  @override
  void dispose() {
    _notifications?.cancel();
    AppDataMode.shared.removeListener(_datasetChanged);
    SubscriptionService.shared.removeListener(_datasetChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _datasetChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
          HealthSyncService.shared.syncIfEnabled().catchError((Object _) {}));
      unawaited(_resumePhoneSleep());
    }
  }

  Future<void> _resumePhoneSleep() async {
    if (!PhoneSleepService.shared.supported) return;
    try {
      await WellnessRepository.shared.wearableUsage();
      await PhoneSleepService.shared.resume();
    } catch (_) {
      /* No permission prompts or guessed preference when offline. */
    }
  }

  Future<void> _initializeMode() async {
    await AppDataMode.shared.initialize();
    if (mounted) setState(() => _modeReady = true);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _takeNotification());
    }
  }

  Future<void> _takeNotification() async {
    if (!mounted || !_modeReady) return;
    final data = NotificationService.shared.takePending();
    if (data == null ||
        data['userId'] != await SecureSessionStore.shared.userId ||
        !mounted) {
      return;
    }
    final dashboard = ModalRoute.of(context);
    Navigator.of(context).popUntil((route) => route == dashboard);

    switch (data['type']) {
      case 'TRIAL_ENDING':
      case 'TRIAL_EXPIRED':
        _openRoute(const SubscriptionView());
        break;
      case 'WORKOUT':
        _onTabSelected(1);
        break;
      case 'SUMMARY':
        _onTabSelected(3);
        break;
      case 'PLAN_READY':
      case 'PLAN_AVAILABLE':
        _openRoute(WeeklyPlanView(initialPlanId: data['targetId']));
        break;
      case 'CHECK_IN':
        await Navigator.of(context).push(AppPageRoute<void>(
            page: SleepEntryView(
                initialDate: DateTime.tryParse(data['date'] ?? ''))));
        TodayRepository.shared.invalidate();
        break;
      case 'MEAL':
        _openRoute(FoodLibraryView(
            initialMealType: data['targetId'] ?? 'LUNCH',
            onMealAdded: () => TodayRepository.shared.invalidate()));
        break;
      case 'TEST':
        _openRoute(const NotificationSettingsView());
        break;
    }
  }

  void _onTabSelected(int index) {
    final next = index.clamp(0, 3);
    if (next == _currentIndex) return;
    setState(() {
      _currentIndex = next;
      _visitedTabs.add(next);
    });
  }

  void _openRoute(Widget page) {
    Navigator.of(context).push(AppPageRoute<void>(page: page));
  }

  @override
  Widget build(BuildContext context) {
    final copy = FitAiCopy.of(context);
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) _onTabSelected(0);
      },
      child: Scaffold(
        backgroundColor: DSColors.dashboardBg,
        extendBody: true,
        // Let nested page Scaffolds paint through the dock's artificial safe area.
        // Each scroll view reserves its own space using scrollBottomInset.
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.paddingOf(context).copyWith(bottom: 0),
          ),
          child: Column(children: [
            const SubscriptionBanner(),
            Expanded(
                child: MediaQuery.removePadding(
                    context: context,
                    removeTop: AppDataMode.shared.available ||
                        (SubscriptionService.shared.access != null &&
                            !(SubscriptionService.shared.access!.state ==
                                    'active' &&
                                SubscriptionService.shared.access!.hasAccess)),
                    child: !_modeReady
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white54))
                        : AnimatedTabStack(
                            key: ValueKey(AppDataMode.shared.dataset),
                            index: _currentIndex,
                            children: <Widget>[
                              _visitedTabs.contains(0)
                                  ? TodayHomeView(
                                      isActive: _currentIndex == 0,
                                      onSelectTab: _onTabSelected,
                                      onOpenProfile: () =>
                                          _openRoute(const ProfileView()),
                                    )
                                  : const SizedBox.shrink(),
                              _visitedTabs.contains(1)
                                  ? TrainView(isActive: _currentIndex == 1)
                                  : const SizedBox.shrink(),
                              _visitedTabs.contains(2)
                                  ? BodyView(
                                      onTrain: () => _onTabSelected(1),
                                      isActive: _currentIndex == 2)
                                  : const SizedBox.shrink(),
                              _visitedTabs.contains(3)
                                  ? ProgressView(isActive: _currentIndex == 3)
                                  : const SizedBox.shrink(),
                            ]
                                .asMap()
                                .entries
                                .map((entry) => TickerMode(
                                    enabled: _currentIndex == entry.key,
                                    child: entry.value))
                                .toList(),
                          ))),
          ]),
        ),
        bottomNavigationBar: LiquidSilverBottomBar(
          selectedIndex: _currentIndex,
          onTabSelected: _onTabSelected,
          labels: [
            copy.text('today'),
            copy.text('train'),
            copy.text('body'),
            copy.text('progress'),
          ],
        ),
      ),
    );
  }
}
