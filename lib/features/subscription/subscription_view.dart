import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/components/liquid_chrome_button.dart';
import '../../core/localization/fitness_copy.dart';
import '../../core/localization/fitness_text.dart';
import '../../core/navigation/onboarding_page_route.dart';
import '../../core/theme/ds_motion.dart';
import '../../core/theme/fitness_theme.dart';
import '../auth/views/auth_view.dart';
import '../onboarding/components/training_hero.dart';
import '../profile/repositories/settings_repository.dart';
import '../profile/views/privacy_settings_view.dart';
import 'subscription_service.dart';

/// One store-backed decision, with a fixed action and a short trial timeline.
class SubscriptionView extends StatefulWidget {
  final SubscriptionService? service;
  final VoidCallback? onContinue;
  final bool blocking;
  final SubscriptionPreparation? preparation;
  const SubscriptionView(
      {super.key,
      this.service,
      this.onContinue,
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
    }
  }

  void _verified() {
    if (!_awaitingUnlock || service.access?.hasAccess != true) return;
    _awaitingUnlock = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && service.access?.hasAccess == true) _continue();
    });
  }

  void _continue() {
    if (_continuing || service.access?.hasAccess != true) return;
    _continuing = true;
    _awaitingUnlock = false;
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.maybePop(context);
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

  String _money(MembershipOffer offer, double amount) =>
      NumberFormat.simpleCurrency(
              name: offer.currencyCode,
              locale: Localizations.localeOf(context).toLanguageTag())
          .format(amount);

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
            final access = service.access;
            final unlocked = access?.hasAccess == true;
            final offer = service.offers[_interval];
            final issue = _issue;
            final trial = !unlocked && issue == null && offer?.hasTrial == true;
            final period =
                fitnessText(context, _interval == 'annual' ? 'year' : 'month');
            final renewal = offer == null ? null : '${offer.price}/$period';
            final pending = service.awaitingConfirmation;
            final busy = _refreshing || _purchasing || service.busy || _leaving;
            final canBuy =
                !busy && !pending && issue == null && service.plansAvailable;
            final compact = MediaQuery.sizeOf(context).height < 740;
            final message = service.error ?? service.notice;
            final action = unlocked
                ? 'Continue to my plan'
                : _refreshing
                    ? 'Loading plans'
                    : pending
                        ? 'Waiting for confirmation'
                        : issue != null
                            ? (issue == SubscriptionCatalogIssue.mobileOnly
                                ? 'Available in the mobile app'
                                : issue == SubscriptionCatalogIssue.setupPending
                                    ? 'Check availability'
                                    : 'Try again')
                            : trial
                                ? fitnessText(context, 'Try for {price}',
                                    values: {'price': _money(offer!, 0)})
                                : 'Subscribe & continue';
            return PopScope(
                canPop: !widget.blocking,
                child: Scaffold(
                    backgroundColor: Colors.black,
                    body: SafeArea(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          Expanded(
                              child: ListView(
                                  key: const ValueKey('membership-scroll'),
                                  padding: EdgeInsets.zero,
                                  children: [
                                Stack(children: [
                                  TrainingHero(
                                      height: compact
                                          ? 165
                                          : (MediaQuery.sizeOf(context).width *
                                                  .58)
                                              .clamp(195, 270)),
                                  if (!widget.blocking &&
                                      Navigator.canPop(context))
                                    Positioned(
                                        top: 12,
                                        left: 16,
                                        child: IconButton.filled(
                                            key: const ValueKey(
                                                'membership-close'),
                                            tooltip: MaterialLocalizations.of(
                                                    context)
                                                .closeButtonTooltip,
                                            style: IconButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    const Color(0x99000000)),
                                            onPressed: _purchasing ||
                                                    service.busy ||
                                                    _leaving
                                                ? null
                                                : () =>
                                                    Navigator.maybePop(context),
                                            icon: const Icon(
                                                Icons.close_rounded,
                                                size: 28))),
                                ]),
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        22, 10, 22, 22),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          FitnessText(
                                              unlocked
                                                  ? 'You’re ready to train.'
                                                  : trial
                                                      ? 'Your first 14 days are free'
                                                      : 'Unlock your full plan',
                                              key: const ValueKey(
                                                  'membership-headline'),
                                              style: TextStyle(
                                                  fontSize: compact ? 27 : 28,
                                                  height: 1.12,
                                                  letterSpacing: -.9,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 12),
                                          if (unlocked)
                                            FitnessText(_accessSummary(access!),
                                                style: const TextStyle(
                                                    color: FitnessTheme.muted,
                                                    fontSize: 13,
                                                    height: 1.5))
                                          else if (offer != null) ...[
                                            FitnessText(
                                                trial
                                                    ? '14 days free, then {price}'
                                                    : '{price} · auto-renewing',
                                                values: {'price': renewal!},
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    height: 1.45)),
                                            if (_interval == 'annual')
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: FitnessText(
                                                      '{price}/month, billed yearly',
                                                      values: {
                                                        'price': _money(offer,
                                                            offer.amount / 12)
                                                      },
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: FitnessTheme
                                                              .muted))),
                                          ],
                                          if (!unlocked &&
                                              _refreshing &&
                                              offer == null)
                                            const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 24),
                                                child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white)))
                                          else if (!unlocked &&
                                              issue != null) ...[
                                            const SizedBox(height: 22),
                                            _AvailabilityNotice(
                                                issue: issue,
                                                store: service.storeName,
                                                detail: _loadError ??
                                                    service.catalogError),
                                          ],
                                          if (trial) ...[
                                            const SizedBox(height: 26),
                                            _TrialTimeline(
                                                price: renewal!,
                                                storeName: service.storeName),
                                          ],
                                          if (!unlocked &&
                                              service.offers.isNotEmpty) ...[
                                            const SizedBox(height: 24),
                                            Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  for (final interval in [
                                                    'annual',
                                                    'monthly'
                                                  ])
                                                    if (service.offers[interval]
                                                        case final candidate?)
                                                      Expanded(
                                                          child: Padding(
                                                              padding: EdgeInsets.only(
                                                                  right: interval == 'annual' &&
                                                                          service.offers.length >
                                                                              1
                                                                      ? 10
                                                                      : 0),
                                                              child: _PlanChoice(
                                                                  key: ValueKey(
                                                                      'membership-$interval'),
                                                                  interval:
                                                                      interval,
                                                                  offer:
                                                                      candidate,
                                                                  selected:
                                                                      interval ==
                                                                          _interval,
                                                                  onTap: busy ||
                                                                          pending
                                                                      ? null
                                                                      : () =>
                                                                          setState(() => _interval = interval)))),
                                                ]),
                                          ],
                                          const SizedBox(height: 20),
                                          const _IncludedFeatures(),
                                          if (unlocked &&
                                              (access!.state == 'active' ||
                                                  !access.legacyTrial))
                                            TextButton(
                                                onPressed: busy
                                                    ? null
                                                    : service.manage,
                                                child: const FitnessText(
                                                    'Manage subscription')),
                                        ])),
                              ])),
                          Container(
                              key: const ValueKey('membership-footer'),
                              color: Colors.black,
                              padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (message != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Semantics(
                                              liveRegion: true,
                                              child: FitnessText(message,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: FitnessTheme
                                                          .muted)))),
                                    if (!unlocked && renewal != null) ...[
                                      FitnessText(
                                          trial
                                              ? '14 days free, then {price}. Auto-renews.'
                                              : '{price} · auto-renewing',
                                          values: {'price': renewal},
                                          key: const ValueKey(
                                              'membership-renewal-price'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              height: 1.4,
                                              color: FitnessTheme.muted)),
                                      const SizedBox(height: 8),
                                    ],
                                    LiquidChromeButton(
                                        key: const ValueKey(
                                            'membership-primary-action'),
                                        title: action,
                                        loadingTitle: _refreshing
                                            ? 'Loading plans'
                                            : 'Opening checkout…',
                                        pill: true,
                                        solid: true,
                                        showArrow: false,
                                        isLoading: busy,
                                        onPressed: busy || pending
                                            ? null
                                            : unlocked
                                                ? _continue
                                                : issue ==
                                                        SubscriptionCatalogIssue
                                                            .mobileOnly
                                                    ? null
                                                    : issue != null
                                                        ? _refresh
                                                        : canBuy
                                                            ? _purchase
                                                            : null),
                                    if (!unlocked && offer != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: FitnessText(
                                              'Cancel anytime in {store}.',
                                              values: {
                                                'store': service.storeName
                                              },
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: FitnessTheme.muted))),
                                    Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 12,
                                        children: [
                                          _legal('Restore purchases', _restore),
                                          _legal(
                                              'Terms',
                                              () => service
                                                  .openLegal('termsUrl')),
                                          _legal(
                                              'Privacy',
                                              () => service
                                                  .openLegal('privacyUrl')),
                                          IconButton(
                                              tooltip: fitnessText(
                                                  context, 'More options'),
                                              onPressed: busy || pending
                                                  ? null
                                                  : _more,
                                              icon: const Icon(Icons.more_horiz,
                                                  size: 20,
                                                  color: FitnessTheme.muted)),
                                        ]),
                                  ])),
                        ]))));
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
  final VoidCallback? onTap;
  const _PlanChoice(
      {super.key,
      required this.interval,
      required this.offer,
      required this.selected,
      this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      child: Material(
          color: selected ? const Color(0xFF232323) : Colors.black,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: selected ? Colors.white : FitnessTheme.line)),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: FitnessText(
                                  interval == 'annual' ? 'Yearly' : 'Monthly',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600))),
                          Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 17,
                              color:
                                  selected ? Colors.white : FitnessTheme.muted)
                        ]),
                        const SizedBox(height: 5),
                        Text(offer.price,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ])))));
}

class _TrialTimeline extends StatelessWidget {
  final String price, storeName;
  const _TrialTimeline({required this.price, required this.storeName});
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            width: 32,
            decoration: BoxDecoration(
                color: const Color(0xFF209FE5),
                borderRadius: BorderRadius.circular(22)),
            child: const Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Icon(Icons.lock_open_rounded, size: 19)),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Icon(Icons.tune_rounded, size: 19)),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Icon(Icons.star_rounded, size: 20)),
                ])),
        const SizedBox(width: 15),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _step(context, 'Today', 'Start your free trial'),
          _step(
              context,
              'Anytime',
              fitnessText(context, 'Cancel in {store}.',
                  values: {'store': storeName})),
          _step(context, 'Day 14', price, last: true),
        ])),
      ]));
  Widget _step(BuildContext context, String title, String detail,
          {bool last = false}) =>
      Padding(
          padding: EdgeInsets.only(top: 8, bottom: last ? 8 : 22),
          child: Wrap(
              spacing: 6,
              runSpacing: 3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FitnessText('${fitnessText(context, title)}:',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                FitnessText(detail,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
              ]));
}

class _IncludedFeatures extends StatelessWidget {
  const _IncludedFeatures();
  @override
  Widget build(BuildContext context) => Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
          key: const ValueKey('membership-included'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: const FitnessText('This is included',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          children: [
            Row(children: [
              const Expanded(child: SizedBox()),
              _cell(context, label: 'Preview'),
              _cell(context, label: 'Premium', included: true)
            ]),
            for (final feature in const [
              'Personalized weekly workouts',
              'Exercise videos & instructions',
              'Nutrition around your goals',
              'Workout logging & history'
            ])
              Row(children: [
                Expanded(
                    child: FitnessText(feature,
                        style: const TextStyle(fontSize: 13, height: 1.4))),
                _cell(context),
                _cell(context, included: true)
              ]),
          ]));
  Widget _cell(BuildContext context, {String? label, bool included = false}) =>
      Container(
          width: MediaQuery.sizeOf(context).width < 350 ? 62 : 76,
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          color: included ? const Color(0xFF17251A) : null,
          child: label != null
              ? FitnessText(label,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 11, color: FitnessTheme.muted))
              : Icon(included ? Icons.check_rounded : Icons.remove_rounded,
                  size: 20,
                  color: included ? Colors.white : FitnessTheme.muted));
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
      SubscriptionCatalogIssue.setupPending => 'Membership opens soon',
      SubscriptionCatalogIssue.storeUnavailable => 'Connect to {store}',
      SubscriptionCatalogIssue.productsMissing =>
        'Membership is unavailable right now',
      SubscriptionCatalogIssue.connection => 'Check your connection',
    };
    final text = switch (issue) {
      SubscriptionCatalogIssue.mobileOnly =>
        'Membership is available in the iOS and Android app.',
      SubscriptionCatalogIssue.setupPending =>
        'Your plan is saved. Check back shortly.',
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
