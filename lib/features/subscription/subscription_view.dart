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
            _loadError = 'Could not sign out · Please retry';
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
                                                          creatorDiscountPct:
                                                              interval ==
                                                                      'annual'
                                                                  ? service
                                                                      .creatorDiscountPercent
                                                                  : null,
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
                                              _CreatorCodeCard(
                                                  service: service),
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
                                                              ? '14 days free, then {price}. Auto-renews.'
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
                                                          'Cancel anytime in {store}',
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
  final double? creatorDiscountPct;
  final VoidCallback? onTap;
  const _PlanChoice(
      {super.key,
      required this.interval,
      required this.offer,
      required this.selected,
      this.savings,
      this.creatorDiscountPct,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    final annual = interval == 'annual';
    final hasDiscount =
        annual && creatorDiscountPct != null && creatorDiscountPct! > 0;
    final effectiveAmount = hasDiscount
        ? offer.amount * (1 - (creatorDiscountPct! / 100))
        : offer.amount;
    final discountedPrice = hasDiscount
        ? NumberFormat.simpleCurrency(
                name: offer.currencyCode,
                locale: Localizations.localeOf(context).toLanguageTag())
            .format(effectiveAmount)
        : null;
    final month = NumberFormat.simpleCurrency(
            name: offer.currencyCode,
            locale: Localizations.localeOf(context).toLanguageTag())
        .format(effectiveAmount / 12);
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
                            if (hasDiscount)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text('-${creatorDiscountPct!.toInt()}%',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black)),
                              )
                            else if (annual && savings != null)
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
                              spacing: 8,
                              children: [
                                if (hasDiscount) ...[
                                  Text(discountedPrice!,
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -.6,
                                          color: Colors.white)),
                                  Text(offer.price,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: FitnessTheme.muted)),
                                ] else
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

class _CreatorCodeCard extends StatefulWidget {
  final SubscriptionService service;
  const _CreatorCodeCard({required this.service});

  @override
  State<_CreatorCodeCard> createState() => _CreatorCodeCardState();
}

class _CreatorCodeCardState extends State<_CreatorCodeCard> {
  bool _expanded = false;
  bool _loading = false;
  String? _error;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.validateAndApplyCreatorCode(code);
      if (mounted) {
        setState(() {
          _controller.clear();
          _expanded = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('StateError: ', '').replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.service.appliedCreatorCode;
    if (applied != null) {
      final name = widget.service.creatorName ?? 'Creator';
      final pct = widget.service.creatorDiscountPercent?.toInt() ?? 20;
      return Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141517),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF28282B)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$applied applied',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pct% Creator Discount with $name',
                    style: const TextStyle(
                      fontSize: 11,
                      color: FitnessTheme.silver,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: FitnessTheme.muted),
              tooltip: 'Remove creator code',
              onPressed: () {
                widget.service.removeCreatorCode();
                setState(() => _error = null);
              },
            ),
          ],
        ),
      );
    }

    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: FitnessTheme.silver,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          onPressed: () => setState(() => _expanded = true),
          icon: const Icon(Icons.local_offer_outlined, size: 16),
          label: const Text(
            'Have a Creator Code?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141517),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF28282B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, size: 16, color: FitnessTheme.silver),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Creator Discount Code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close_rounded, size: 18, color: FitnessTheme.muted),
                onPressed: () => setState(() {
                  _expanded = false;
                  _error = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0E10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A2E)),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: .5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. ALEX20',
                        hintStyle: TextStyle(
                          color: Color(0xFF5A5A60),
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _apply(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _apply,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'APPLY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFFF6B6B),
              ),
            ),
          ],
          if (widget.service.ios) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => widget.service.presentCodeRedemptionSheet(),
                child: const Text(
                  'Have an App Store offer code? Redeem',
                  style: TextStyle(
                    fontSize: 11,
                    color: FitnessTheme.silver,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
        'Membership is available in the iOS and Android app',
      SubscriptionCatalogIssue.setupPending =>
        'Your plan is saved · Please try again later',
      SubscriptionCatalogIssue.storeUnavailable =>
        'Open {store} and try again',
      SubscriptionCatalogIssue.productsMissing => 'Please try again shortly',
      SubscriptionCatalogIssue.connection =>
        detail ?? 'Please try again shortly',
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
      ('Day 12', "We'll email you a reminder", Icons.mark_email_unread_rounded),
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
