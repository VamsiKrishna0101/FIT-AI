import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/components/liquid_chrome_button.dart';
import '../../core/localization/fitness_copy.dart';
import '../../core/localization/fitness_text.dart';
import '../../core/navigation/onboarding_page_route.dart';
import '../../core/theme/ds_motion.dart';
import '../../core/theme/fitness_theme.dart';
import '../auth/views/auth_view.dart';
import '../profile/repositories/settings_repository.dart';
import '../profile/views/privacy_settings_view.dart';
import 'subscription_service.dart';

/// Clear store pricing with a short timeline for eligible native trials.
class SubscriptionView extends StatefulWidget {
  final SubscriptionService? service;
  final FutureOr<void> Function()? onContinue;
  final Future<bool> Function()? beforePurchase;
  final bool blocking;
  final SubscriptionPreparation? preparation;
  const SubscriptionView(
      {super.key,
      this.service,
      this.onContinue,
      this.beforePurchase,
      this.blocking = false,
      this.preparation});
  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late final service = widget.service ?? SubscriptionService.shared;
  String _interval = 'annual';
  String? _loadError;
  bool _refreshing = false, _purchasing = false, _leaving = false;
  bool _awaitingUnlock = false, _continuing = false;
  bool _presentedRevenueCat = false;

  @override
  void initState() {
    super.initState();
    service.addListener(_verified);
    final prepared = widget.preparation;
    if (prepared == null ||
        !identical(prepared.service, service) ||
        !prepared.isCurrent) {
      _refresh();
    } else {
      _selectAvailableOffer();
      _scheduleRevenueCatPaywall();
    }
  }

  void _selectAvailableOffer() {
    if (!service.offers.containsKey(_interval) && service.offers.isNotEmpty) {
      _interval = service.offers.keys.first;
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _loadError = null;
    });
    try {
      await service.initialize();
      if (mounted) setState(_selectAvailableOffer);
    } catch (failure) {
      if (mounted) {
        setState(() => _loadError = SubscriptionService.message(failure));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
      _scheduleRevenueCatPaywall();
    }
  }

  void _scheduleRevenueCatPaywall() {
    if (!mounted ||
        _presentedRevenueCat ||
        !service.usesRevenueCat ||
        !service.plansAvailable ||
        service.access?.hasAccess == true) {
      return;
    }
    _presentedRevenueCat = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Run the existing onboarding validation before opening native checkout.
      await _purchase();
      if (mounted &&
          !widget.blocking &&
          service.access?.hasAccess != true &&
          service.error == null &&
          Navigator.canPop(context)) {
        Navigator.maybePop(context);
      }
    });
  }

  void _verified() {
    if (!_awaitingUnlock || service.access?.hasAccess != true) return;
    _awaitingUnlock = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && service.access?.hasAccess == true) _continue();
    });
  }

  Future<void> _continue() async {
    if (_continuing || service.access?.hasAccess != true) return;
    setState(() => _continuing = true);
    _awaitingUnlock = false;
    try {
      if (widget.onContinue != null) {
        await widget.onContinue!();
      } else if (mounted) {
        Navigator.maybePop(context);
      }
    } finally {
      if (mounted) setState(() => _continuing = false);
    }
  }

  Future<void> _purchase() async {
    if (_purchasing ||
        service.busy ||
        service.awaitingConfirmation ||
        !service.plansAvailable) {
      return;
    }
    setState(() => _purchasing = true);
    _awaitingUnlock = true;
    try {
      if (widget.beforePurchase != null && !await widget.beforePurchase!()) {
        _awaitingUnlock = false;
        return;
      }
      if (!mounted) {
        _awaitingUnlock = false;
        return;
      }
      await service.purchase(_interval);
      _verified();
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    if (service.busy) return;
    _awaitingUnlock = true;
    await service.restore();
    _verified();
  }

  Future<void> _more() async {
    final action = await showModalBottomSheet<String>(
        context: context,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        backgroundColor: FitnessTheme.surface,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ListTile(
                      title: const FitnessText('Privacy & data'),
                      onTap: () => Navigator.pop(context, 'privacy')),
                  ListTile(
                      title: const FitnessText('Sign out'),
                      onTap: () => Navigator.pop(context, 'signout')),
                ]))));
    if (!mounted) return;
    if (action == 'privacy') {
      await Navigator.push(
          context, AppPageRoute<void>(page: const PrivacySettingsView()));
    } else if (action == 'signout' && !_leaving) {
      setState(() => _leaving = true);
      try {
        await SettingsRepository().signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
              AppPageRoute<void>(page: const AuthView(initialSignIn: true)),
              (_) => false);
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _leaving = false;
            _loadError = 'Could not sign out. Please retry.';
          });
        }
      }
    }
  }

  SubscriptionCatalogIssue? get _issue {
    if (_loadError != null) return SubscriptionCatalogIssue.connection;
    if (service.catalogIssue != null) return service.catalogIssue;
    if (!service.android && !service.ios) {
      return SubscriptionCatalogIssue.mobileOnly;
    }
    if (service.access?.billingReady == false) {
      return SubscriptionCatalogIssue.setupPending;
    }
    if (service.offers.isEmpty) {
      return service.storeReady
          ? SubscriptionCatalogIssue.productsMissing
          : SubscriptionCatalogIssue.storeUnavailable;
    }
    return null;
  }

  @override
  void dispose() {
    service.removeListener(_verified);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: AnimatedBuilder(
          animation: service,
          builder: (context, _) {
            final unlocked = service.access?.hasAccess == true;
            final offer = service.offers[_interval];
            final issue = _issue;
            final busy = _refreshing ||
                _purchasing ||
                service.busy ||
                _leaving ||
                _continuing;
            final pending = service.awaitingConfirmation;
            final trial = !unlocked && issue == null && offer?.hasTrial == true;
            final period =
                fitnessText(context, _interval == 'annual' ? 'year' : 'month');
            final renewal = offer == null ? null : '${offer.price}/$period';
            final message = service.error ?? service.notice;
            final action = unlocked
                ? 'Open my plan'
                : trial
                    ? 'Start my 14-day trial'
                    : _interval == 'annual'
                        ? 'Continue with yearly'
                        : 'Continue with monthly';
            return PopScope(
                canPop: !widget.blocking,
                child: Scaffold(
                    backgroundColor: Colors.black,
                    body: SafeArea(
                        child: Center(
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24, 8, 16, 12),
                                          child: Row(children: [
                                            const Expanded(
                                                child: Text('SETCRAFT',
                                                    style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color:
                                                            Color(0xFF606066),
                                                        letterSpacing: -.8))),
                                            if (!widget.blocking &&
                                                Navigator.canPop(context))
                                              IconButton(
                                                  key: const ValueKey(
                                                      'membership-close'),
                                                  tooltip:
                                                      MaterialLocalizations.of(
                                                              context)
                                                          .closeButtonTooltip,
                                                  onPressed: busy
                                                      ? null
                                                      : () =>
                                                          Navigator.maybePop(
                                                              context),
                                                  icon: const Icon(
                                                      Icons.close_rounded,
                                                      size: 22)),
                                          ])),
                                      Expanded(
                                          child: ListView(
                                              key: const ValueKey(
                                                  'membership-scroll'),
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      24, 12, 24, 20),
                                              children: [
                                            FitnessText(
                                                unlocked
                                                    ? 'Your membership is active'
                                                    : trial
                                                        ? 'Your first 14 days are free'
                                                        : 'Unlock your full plan',
                                                key: const ValueKey(
                                                    'membership-headline'),
                                                style: const TextStyle(
                                                    fontSize: 30,
                                                    height: 1.15,
                                                    letterSpacing: -.8,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            if (trial) ...[
                                              const SizedBox(height: 26),
                                              const _TrialTimeline(),
                                            ] else if (!unlocked) ...[
                                              const SizedBox(height: 20),
                                              for (final benefit in [
                                                'Personalized weekly plans',
                                                'Exercise guidance and workout tracking',
                                                'Your progress, over time'
                                              ])
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 10),
                                                    child: Row(children: [
                                                      const Icon(
                                                          Icons.check_rounded,
                                                          color: FitnessTheme
                                                              .silver,
                                                          size: 18),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                          child: FitnessText(
                                                              benefit,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      height:
                                                                          1.4))),
                                                    ])),
                                            ],
                                            if (unlocked) ...[
                                              const SizedBox(height: 16),
                                              FitnessText(
                                                  _accessSummary(
                                                      service.access!),
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      height: 1.5,
                                                      color:
                                                          FitnessTheme.muted))
                                            ] else ...[
                                              const SizedBox(height: 24),
                                              const FitnessText(
                                                  'Choose your membership',
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(height: 14),
                                              for (final interval in [
                                                'annual',
                                                'monthly'
                                              ])
                                                if (service.offers[interval]
                                                    case final candidate?)
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 12),
                                                      child: _PlanChoice(
                                                          key: ValueKey(
                                                              'membership-$interval'),
                                                          interval: interval,
                                                          offer: candidate,
                                                          savings: interval ==
                                                                  'annual'
                                                              ? service
                                                                  .annualSavings
                                                              : null,
                                                          selected: interval ==
                                                              _interval,
                                                          onTap: busy || pending
                                                              ? null
                                                              : () => setState(
                                                                  () => _interval =
                                                                      interval))),
                                              if (_refreshing &&
                                                  service.offers.isEmpty)
                                                const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 20),
                                                    child: Center(
                                                        child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: FitnessTheme
                                                                .silver))),
                                              if (!_refreshing && issue != null)
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    child: _AvailabilityNotice(
                                                        issue: issue,
                                                        store:
                                                            service.storeName,
                                                        detail: _loadError ??
                                                            service
                                                                .catalogError)),
                                              if (!_refreshing &&
                                                  issue != null &&
                                                  issue !=
                                                      SubscriptionCatalogIssue
                                                          .mobileOnly)
                                                Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: TextButton(
                                                        key: const ValueKey(
                                                            'membership-retry'),
                                                        onPressed: busy
                                                            ? null
                                                            : _refresh,
                                                        child:
                                                            const FitnessText(
                                                                'Retry'))),
                                            ],
                                          ])),
                                      Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24, 10, 24, 8),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (message != null)
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 10),
                                                      child: Semantics(
                                                          liveRegion: true,
                                                          child: FitnessText(
                                                              message,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  height: 1.4,
                                                                  color: FitnessTheme
                                                                      .muted)))),
                                                if (!unlocked &&
                                                    renewal != null)
                                                  Padding(
                                                      padding: const EdgeInsets
                                                          .only(bottom: 10),
                                                      child: FitnessText(
                                                          trial
                                                              ? '14 days free, then {price}'
                                                              : 'Billed {price} · auto-renews',
                                                          values: {
                                                            'price': renewal
                                                          },
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              height: 1.4,
                                                              color:
                                                                  FitnessTheme
                                                                      .muted))),
                                                LiquidChromeButton(
                                                    key: const ValueKey(
                                                        'membership-primary-action'),
                                                    title: pending
                                                        ? 'Waiting for confirmation'
                                                        : action,
                                                    loadingTitle: _refreshing
                                                        ? 'Loading prices'
                                                        : _continuing
                                                            ? 'Opening your plan'
                                                            : 'Opening checkout',
                                                    pill: true,
                                                    solid: true,
                                                    showArrow: false,
                                                    isLoading: busy,
                                                    onPressed: busy || pending
                                                        ? null
                                                        : unlocked
                                                            ? _continue
                                                            : service.plansAvailable &&
                                                                    issue ==
                                                                        null
                                                                ? _purchase
                                                                : null),
                                                if (!unlocked && offer != null)
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 8),
                                                      child: FitnessText(
                                                          'Cancel anytime in {store}.',
                                                          values: {
                                                            'store': service
                                                                .storeName
                                                          },
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  FitnessTheme
                                                                      .muted))),
                                                Wrap(
                                                    alignment:
                                                        WrapAlignment.center,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    spacing: 12,
                                                    children: [
                                                      _legal(
                                                          'Restore purchases',
                                                          _restore),
                                                      _legal(
                                                          'Terms',
                                                          () =>
                                                              service.openLegal(
                                                                  'termsUrl')),
                                                      _legal(
                                                          'Privacy',
                                                          () =>
                                                              service.openLegal(
                                                                  'privacyUrl')),
                                                      IconButton(
                                                          tooltip: fitnessText(
                                                              context,
                                                              'More options'),
                                                          onPressed:
                                                              busy || pending
                                                                  ? null
                                                                  : _more,
                                                          icon: const Icon(
                                                              Icons.more_horiz,
                                                              size: 20,
                                                              color:
                                                                  FitnessTheme
                                                                      .muted)),
                                                    ]),
                                              ])),
                                    ]))))));
          }));

  Widget _legal(String label, VoidCallback action) => TextButton(
      style: TextButton.styleFrom(
          foregroundColor: FitnessTheme.muted,
          padding: const EdgeInsets.symmetric(horizontal: 1),
          minimumSize: const Size(40, 44)),
      onPressed: service.busy || _refreshing || _purchasing ? null : action,
      child: FitnessText(label, style: const TextStyle(fontSize: 10)));

  String _accessSummary(SubscriptionAccess access) {
    final end = access.state == 'trial' ? access.trialEnd : access.paidEnd;
    final date = end == null
        ? ''
        : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
            .format(end.toLocal());
    return fitnessText(
        context,
        access.state == 'trial'
            ? 'Trial active until {date}'
            : 'Membership active until {date}',
        values: {'date': date});
  }
}

class _PlanChoice extends StatelessWidget {
  final String interval;
  final MembershipOffer offer;
  final bool selected;
  final int? savings;
  final VoidCallback? onTap;
  const _PlanChoice(
      {super.key,
      required this.interval,
      required this.offer,
      required this.selected,
      this.savings,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    final annual = interval == 'annual';
    final month = NumberFormat.simpleCurrency(
            name: offer.currencyCode,
            locale: Localizations.localeOf(context).toLanguageTag())
        .format(offer.amount / 12);
    return Semantics(
        button: true,
        selected: selected,
        child: Material(
            color: selected ? const Color(0xFF242427) : const Color(0xFF171719),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                    color: selected
                        ? const Color(0xFFE1E1E5)
                        : Colors.transparent)),
            child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onTap,
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(
                                child: FitnessText(
                                    annual ? 'Yearly' : 'Monthly',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600))),
                            if (annual && savings != null)
                              FitnessText('Save {percent}%',
                                  values: {'percent': savings!},
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: FitnessTheme.silver)),
                            const SizedBox(width: 10),
                            Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: selected
                                    ? Colors.white
                                    : FitnessTheme.muted)
                          ]),
                          const SizedBox(height: 8),
                          Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(offer.price,
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -.6)),
                                FitnessText(annual ? '/year' : '/month',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: FitnessTheme.muted)),
                              ]),
                          const SizedBox(height: 5),
                          FitnessText(
                              annual
                                  ? '{price}/month, billed yearly'
                                  : 'Billed monthly',
                              values: {'price': month},
                              style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: FitnessTheme.muted)),
                        ])))));
  }
}

class _AvailabilityNotice extends StatelessWidget {
  final SubscriptionCatalogIssue issue;
  final String store;
  final String? detail;
  const _AvailabilityNotice(
      {required this.issue, required this.store, this.detail});
  @override
  Widget build(BuildContext context) {
    final title = switch (issue) {
      SubscriptionCatalogIssue.mobileOnly => 'Continue on your phone',
      SubscriptionCatalogIssue.setupPending =>
        'Payment is unavailable right now',
      SubscriptionCatalogIssue.storeUnavailable => 'Connect to {store}',
      SubscriptionCatalogIssue.productsMissing =>
        'Membership is unavailable right now',
      SubscriptionCatalogIssue.connection => 'Check your connection',
    };
    final text = switch (issue) {
      SubscriptionCatalogIssue.mobileOnly =>
        'Membership is available in the iOS and Android app.',
      SubscriptionCatalogIssue.setupPending =>
        'Your plan is saved. Please try again later.',
      SubscriptionCatalogIssue.storeUnavailable =>
        'Open {store} and try again.',
      SubscriptionCatalogIssue.productsMissing => 'Please try again shortly.',
      SubscriptionCatalogIssue.connection =>
        detail ?? 'Please try again shortly.',
    };
    return Semantics(
        liveRegion: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitnessText(title,
              values: {'store': store},
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          FitnessText(text,
              values: {'store': store},
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: FitnessTheme.muted)),
        ]));
  }
}

class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline();
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Day 1', 'Explore your full plan', Icons.lock_open_rounded),
      ('Day 12', 'Two days left in your trial', Icons.hourglass_bottom_rounded),
      ('Day 14', 'Your membership begins', Icons.check_rounded),
    ];
    return Column(key: const ValueKey('membership-trial-timeline'), children: [
      for (var i = 0; i < rows.length; i++)
        IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              width: 30,
              child: Column(children: [
                Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6), shape: BoxShape.circle),
                    child: Icon(rows[i].$3, size: 15, color: Colors.white)),
                if (i < rows.length - 1)
                  Expanded(
                      child:
                          Container(width: 1, color: const Color(0xFF3B82F6))),
              ])),
          const SizedBox(width: 16),
          Expanded(
              child: Padding(
                  padding:
                      EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FitnessText(rows[i].$1,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        FitnessText(rows[i].$2,
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: FitnessTheme.muted)),
                      ]))),
        ])),
    ]);
  }
}
