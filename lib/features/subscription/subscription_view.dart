import '../../core/theme/ds_motion.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/components/liquid_chrome_button.dart';
import '../../core/localization/fitness_copy.dart';
import '../../core/localization/fitness_text.dart';
import '../../core/theme/ds_colors.dart';
import '../../core/theme/fitness_theme.dart';
import '../profile/views/privacy_settings_view.dart';
import '../../core/navigation/onboarding_page_route.dart';
import 'subscription_service.dart';
import 'subscription_pricing_view.dart';
import 'trial_access_hero.dart';

class SubscriptionView extends StatefulWidget {
  final SubscriptionService? service;
  final VoidCallback? onContinue;
  const SubscriptionView({super.key, this.service, this.onContinue});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late final service = widget.service ?? SubscriptionService.shared;
  String _interval = 'annual';
  String? _loadError;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await service.refresh();
      // Store availability is separate from confirmed trial access.
      try {
        await service.loadProducts();
      } catch (_) {
        // The plans message offers another attempt; the trial stays usable.
      }
      if (mounted) {
        setState(() {
          _loadError = null;
          if (!service.products.containsKey(_interval) &&
              service.products.isNotEmpty) {
            _interval = service.products.keys.first;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = SubscriptionService.message(error));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _viewPlans() async {
    await Navigator.push(
        context,
        AppPageRoute<void>(
          page:
              SubscriptionPricingView(service: service, onContinue: _continue),
        ));
  }

  void _continue() {
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _start() async {
    await service.startTrial();
    if (mounted && service.access?.hasAccess == true) _continue();
  }

  String _date(DateTime date) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
          .format(date.toLocal());

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final access = service.access;
          final available = access?.trialAvailable == true;
          final trial = access?.state == 'trial' && access!.hasAccess;
          final active = access?.state == 'active' && access!.hasAccess;
          final plansRequested =
              access != null && !active && (!available && !trial);
          final plans = plansRequested && service.plansAvailable;
          final unavailablePlans = plansRequested && !plans;
          final reduced = MediaQuery.disableAnimationsOf(context);
          final duration = reduced ? Duration.zero : DSMotion.regular;
          final title = active
              ? 'Your membership'
              : trial
                  ? 'Make these days yours'
                  : 'Keep your progress moving';

          return Scaffold(
            backgroundColor: DSColors.bg,
            appBar: AppBar(
              backgroundColor: DSColors.bg,
              surfaceTintColor: Colors.transparent,
              title: const FitnessText('FitAI Premium',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              leading: IconButton(
                  onPressed: _continue,
                  tooltip: fitnessText(context, 'Back'),
                  icon: const Icon(CupertinoIcons.chevron_left)),
            ),
            body: SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    if (access == null && _loadError == null)
                      const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white54)),
                    if (access != null) ...[
                      if (available)
                        _trialIntroduction()
                      else ...[
                        const SizedBox(height: 12),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: reduced ? Duration.zero : DSMotion.chart,
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 10),
                                  child: child)),
                          child: Column(children: [
                            if (trial) ...[
                              TrialAccessHero(days: access.daysRemaining),
                              const SizedBox(height: 14),
                              Text(
                                  fitnessText(
                                      context, '{days} days left in your trial',
                                      values: {'days': access.daysRemaining}),
                                  style: const TextStyle(
                                      fontSize: 13, color: DSColors.silver)),
                            ] else
                              _TrialRing(
                                  active: active,
                                  showDays: false,
                                  days: access.daysRemaining,
                                  reduced: reduced),
                            const SizedBox(height: 24),
                            FitnessText(title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 29,
                                    height: 1.15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -.8)),
                            const SizedBox(height: 12),
                            FitnessText(
                                active
                                    ? 'Your training, together in one place.'
                                    : trial
                                        ? 'Full access to your plans, photo scans and progress.'
                                        : 'Your trial has ended. Your saved progress stays with you.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: DSColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.5)),
                          ]),
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (trial)
                        _surface(Column(children: [
                          _timeline(CupertinoIcons.sparkles, 'Today',
                              'Start exploring every feature.'),
                          _timeline(
                              CupertinoIcons.bell,
                              'Before your trial ends',
                              'We’ll remind you 2 days before it ends. Push reminders need notifications enabled.'),
                          _timeline(
                              CupertinoIcons.checkmark_shield,
                              'After 14 days',
                              'Choose a plan if you want to continue. Nothing is charged automatically.',
                              last: true),
                        ])),
                      if (trial)
                        Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                                fitnessText(context, 'Trial ends {date}',
                                    values: {'date': _date(access.trialEnd!)}),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: DSColors.textSecondary,
                                    fontSize: 12))),
                      if (active)
                        _surface(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FitnessText(
                                  access.data['cancelAtPeriodEnd'] == true
                                      ? 'Access until'
                                      : 'Next renewal',
                                  style: const TextStyle(
                                      color: DSColors.textSecondary,
                                      fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(_date(access.paidEnd!),
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500)),
                              if (access.data['paymentIssue'] == true)
                                const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: FitnessText(
                                        'Update your payment method in Google Play to keep access.')),
                              TextButton(
                                  onPressed: service.manage,
                                  child: const FitnessText(
                                      'Manage in Google Play')),
                            ])),
                      if (plans) ...[
                        const SizedBox(height: 24),
                        for (final interval in ['annual', 'monthly']
                            .where(service.products.containsKey)) ...[
                          _plan(interval, duration),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 16),
                        const FitnessText(
                            'Charged when you subscribe. Automatically renews until canceled in Google Play.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: DSColors.textSecondary,
                                fontSize: 12,
                                height: 1.5)),
                      ],
                      if (unavailablePlans) ...[
                        const SizedBox(height: 24),
                        _surface(_plansMessage()),
                        if (service.android && access.billingReady)
                          TextButton(
                              onPressed: _refreshing ? null : _refresh,
                              child: const FitnessText('Check again')),
                      ],
                      if (!active && !available) ...[
                        const SizedBox(height: 24),
                        const FitnessText('Everything for your next step',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        _feature(
                            CupertinoIcons.flame,
                            'Personalized weekly plans',
                            'Exercises, sets, reps and weights adapted to your history.'),
                        _feature(
                            CupertinoIcons.camera,
                            'Photo scans & measurements',
                            'Understand your physique and track changes.'),
                        _feature(CupertinoIcons.heart, 'Nutrition & recovery',
                            'Food recommendations, logging and your daily readiness.'),
                        _feature(
                            CupertinoIcons.chart_bar,
                            'Your progress, over time',
                            'Your workouts, saved routines and training history.'),
                      ],
                    ],
                    if (_loadError != null || service.error != null) ...[
                      const SizedBox(height: 16),
                      FitnessText(_loadError ?? service.error!,
                          style: const TextStyle(
                              color: DSColors.textSecondary, height: 1.4)),
                      TextButton(
                          onPressed: service.busy ? null : _refresh,
                          child: const FitnessText('Retry')),
                    ],
                    const SizedBox(height: 18),
                    Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          if (access?.data['termsUrl'] != null)
                            TextButton(
                                onPressed: () => service.openLegal('termsUrl'),
                                child: const FitnessText('Terms',
                                    style: TextStyle(fontSize: 12))),
                          if (access?.data['privacyUrl'] != null)
                            TextButton(
                                onPressed: () =>
                                    service.openLegal('privacyUrl'),
                                child: const FitnessText('Privacy policy',
                                    style: TextStyle(fontSize: 12))),
                          if (service.android && access?.billingReady == true)
                            TextButton(
                                onPressed:
                                    service.busy ? null : service.restore,
                                child: const FitnessText('Restore purchases',
                                    style: TextStyle(fontSize: 12))),
                          TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  AppPageRoute<void>(
                                      page: const PrivacySettingsView())),
                              child: const FitnessText('Photos & privacy',
                                  style: TextStyle(fontSize: 12))),
                        ]),
                  ],
                )),
            bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (plans && service.products[_interval] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                            '${service.products[_interval]!.price} · ${fitnessText(context, _interval == 'annual' ? 'per year' : 'per month')}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, color: DSColors.textSecondary)),
                      ),
                    LiquidChromeButton(
                      title: access == null
                          ? 'Retry'
                          : plans
                              ? 'Subscribe now'
                              : available
                                  ? 'Start my 14-day trial'
                                  : active
                                      ? 'Continue'
                                      : trial
                                          ? 'Continue your trial'
                                          : 'View saved records',
                      isLoading: service.busy || _refreshing,
                      onPressed: service.busy ||
                              _refreshing ||
                              (plans &&
                                  (!service.android ||
                                      !access.billingReady ||
                                      service.products[_interval] == null))
                          ? null
                          : access == null
                              ? _refresh
                              : plans
                                  ? () => service.purchase(_interval)
                                  : available
                                      ? _start
                                      : _continue,
                    ),
                    if (available)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: FitnessText(
                            'No payment details. No automatic charge.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                color: DSColors.textSecondary,
                                height: 1.4)),
                      ),
                    if (trial && !plans)
                      TextButton(
                          onPressed: _refreshing ? null : _viewPlans,
                          child: const FitnessText('View subscription plans',
                              style: TextStyle(fontSize: 12))),
                    if (available || plans)
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (available)
                              Flexible(
                                  child: TextButton(
                                      onPressed: service.busy || _refreshing
                                          ? null
                                          : _viewPlans,
                                      child: const FitnessText('See pricing',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: DSColors.silver)))),
                            Flexible(
                                child: TextButton(
                                    onPressed: _continue,
                                    child: FitnessText(
                                        available
                                            ? 'Not now'
                                            : 'View saved records',
                                        style: const TextStyle(
                                            color: DSColors.textSecondary,
                                            fontSize: 12)))),
                          ]),
                  ],
                )),
          );
        },
      ));

  Widget _trialIntroduction() => Column(
        key: const ValueKey('trial-introduction'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TrialAccessHero(),
          const SizedBox(height: 22),
          const FitnessText('Your next chapter starts here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28,
                  height: 1.16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.8)),
          const SizedBox(height: 10),
          const FitnessText(
              'Explore your training, nutrition and progress together.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, height: 1.5, color: DSColors.textSecondary)),
          const SizedBox(height: 24),
          _trialBenefit(CupertinoIcons.flame, 'Personalized weekly plans'),
          _trialBenefit(CupertinoIcons.camera, 'Photo scans & measurements'),
          _trialBenefit(CupertinoIcons.heart, 'Nutrition & recovery'),
          const SizedBox(height: 18),
        ],
      );

  Widget _trialBenefit(IconData icon, String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: DSColors.bgCard, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: DSColors.silver),
          ),
          const SizedBox(width: 13),
          Expanded(
              child: FitnessText(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w400))),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.checkmark,
              size: 12, color: DSColors.textSecondary),
        ]),
      );

  Widget _plansMessage() {
    final trial = service.access?.state == 'trial' && service.access!.hasAccess;
    final comingSoon = !service.android || service.access?.billingReady != true;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(CupertinoIcons.creditcard,
          size: 28, color: DSColors.textSecondary),
      const SizedBox(height: 16),
      FitnessText(
          comingSoon
              ? 'Subscriptions are coming soon'
              : 'We couldn’t load plans',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      FitnessText(
          trial
              ? 'Your trial is still active. Keep exploring all your features.'
              : 'Your saved progress is available. Check back for subscription options.',
          style: const TextStyle(
              color: DSColors.textSecondary, fontSize: 14, height: 1.5)),
    ]);
  }

  Widget _surface(Widget child) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: DSColors.bgCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: DSColors.border)),
      child: child);

  Widget _timeline(IconData icon, String title, String body,
          {bool last = false}) =>
      Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 22),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: DSColors.textPrimary),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                FitnessText(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                FitnessText(body,
                    style: const TextStyle(
                        color: DSColors.textSecondary,
                        fontSize: 12,
                        height: 1.5)),
              ])),
        ]),
      );

  Widget _feature(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 19, color: DSColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                FitnessText(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                FitnessText(subtitle,
                    style: const TextStyle(
                        color: DSColors.textSecondary,
                        fontSize: 12,
                        height: 1.4)),
              ])),
        ]),
      );

  Widget _plan(String interval, Duration duration) {
    final product = service.products[interval];
    final selected = _interval == interval;
    final savings = service.annualSavings;
    return Semantics(
        button: true,
        selected: selected,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: service.busy || product == null
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _interval = interval);
                      },
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: selected ? DSColors.bgRaised : DSColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? Colors.white60 : DSColors.border)),
                  child: Row(children: [
                    Icon(
                        selected
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          FitnessText(
                              interval == 'annual' ? 'Annual' : 'Monthly',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500)),
                          if (interval == 'annual' && savings != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                    fitnessText(context, 'Save {percent}%',
                                        values: {'percent': savings}),
                                    style: const TextStyle(
                                        color: DSColors.textSecondary,
                                        fontSize: 12))),
                        ])),
                    Flexible(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                          Text(
                              product?.price ??
                                  fitnessText(context, 'Unavailable'),
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w500)),
                          FitnessText(
                              interval == 'annual' ? 'per year' : 'per month',
                              style: const TextStyle(
                                  color: DSColors.textSecondary, fontSize: 11)),
                        ])),
                  ]),
                ))));
  }
}

class _TrialRing extends StatelessWidget {
  final int days;
  final bool active, reduced, showDays;
  const _TrialRing(
      {required this.days,
      required this.active,
      required this.reduced,
      required this.showDays});

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 124 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
      height: 124 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: active || !showDays ? 1 : days / 14),
              duration: reduced ? Duration.zero : DSMotion.chart,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => SizedBox.expand(
                  child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      backgroundColor: DSColors.bgRaised,
                      color: DSColors.textPrimary))),
          Column(mainAxisSize: MainAxisSize.min, children: [
            if (active)
              const Icon(CupertinoIcons.checkmark, size: 34)
            else if (!showDays)
              const Icon(CupertinoIcons.flame, size: 34)
            else
              Text('$days',
                  style: const TextStyle(
                      fontSize: 43,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -2)),
            const SizedBox(height: 2),
            FitnessText(
                active
                    ? 'Active'
                    : showDays
                        ? 'DAYS'
                        : 'FitAI Premium',
                style: const TextStyle(
                    color: DSColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1.5)),
          ]),
        ],
      ));
}
