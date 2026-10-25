import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/branding/setcraft_brand.dart';
import '../../core/components/liquid_chrome_button.dart';
import '../../core/localization/fitness_text.dart';
import '../../core/localization/fitness_copy.dart';
import '../../core/navigation/onboarding_page_route.dart';
import '../../core/theme/fitness_theme.dart';
import '../auth/views/auth_view.dart';
import '../onboarding/components/training_hero.dart';
import '../profile/repositories/settings_repository.dart';
import '../profile/views/privacy_settings_view.dart';
import 'subscription_service.dart';

/// One membership decision, with the real store offer and price on the page.
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
  bool _refreshing = false, _leaving = false;
  @override
  void initState() {
    super.initState();
    final prepared = widget.preparation;
    if (prepared == null ||
        !identical(prepared.service, service) ||
        !prepared.isCurrent) {
      _refresh();
    } else if (!service.offers.containsKey(_interval) &&
        service.offers.isNotEmpty) {
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
      if (mounted) {
        setState(() {
          if (!service.offers.containsKey(_interval) &&
              service.offers.isNotEmpty) {
            _interval = service.offers.keys.first;
          }
        });
      }
    } catch (failure) {
      if (mounted) {
        setState(() => _loadError = SubscriptionService.message(failure));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _continue() {
    if (service.access?.hasAccess != true) return;
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _purchase() async {
    await service.purchase(_interval);
    if (mounted && service.access?.hasAccess == true) _continue();
  }

  String _date(DateTime value) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
          .format(value.toLocal());
  Future<void> _account() async {
    final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF171717),
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FitnessText('Your account',
                          style: TextStyle(
                              fontSize: 23, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      const FitnessText(
                          'Your answers and saved progress stay with your account.',
                          style: TextStyle(
                              color: FitnessTheme.muted, height: 1.5)),
                      const SizedBox(height: 14),
                      TextButton(
                          onPressed: () => Navigator.pop(context, 'privacy'),
                          child: const FitnessText('Privacy & data')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, 'signout'),
                          child: const FitnessText('Sign out')),
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

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: AnimatedBuilder(
          animation: service,
          builder: (context, _) {
            final access = service.access;
            final unlocked = access?.hasAccess == true;
            final offer = service.offers[_interval];
            final trial = !unlocked && offer?.hasTrial == true;
            final period =
                fitnessText(context, _interval == 'annual' ? 'year' : 'month');
            final compact = MediaQuery.sizeOf(context).height < 740;
            final pending = service.awaitingConfirmation;
            final canBuy = !_refreshing &&
                !service.busy &&
                !pending &&
                service.plansAvailable &&
                offer != null;
            final message = _loadError ?? service.error ?? service.notice;
            final renewal = offer == null ? null : '${offer.price}/$period';
            return PopScope(
                canPop: !widget.blocking,
                child: Scaffold(
                  backgroundColor: Colors.black,
                  body: SafeArea(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                            child: Row(children: [
                              if (!widget.blocking && Navigator.canPop(context))
                                IconButton(
                                    tooltip: 'Back',
                                    onPressed: service.busy
                                        ? null
                                        : () => Navigator.maybePop(context),
                                    icon:
                                        const Icon(Icons.arrow_back, size: 22))
                              else
                                const SizedBox(width: 12),
                              const SetcraftMark(size: 28),
                              const SizedBox(width: 8),
                              const Text('SETCRAFT',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.4)),
                              const Spacer(),
                              TextButton(
                                  onPressed: _leaving ? null : _account,
                                  child: const FitnessText('Account',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: FitnessTheme.muted))),
                            ])),
                        Expanded(
                            child: ListView(
                                key: const ValueKey('membership-scroll'),
                                padding: EdgeInsets.zero,
                                children: [
                              TrainingHero(height: compact ? 155 : 200),
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 4, 24, 24),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const FitnessText(
                                            'YOUR PLAN. YOUR PROGRESS.',
                                            style: TextStyle(
                                                fontSize: 10,
                                                letterSpacing: 1.7,
                                                color: FitnessTheme.muted,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 13),
                                        FitnessText(
                                            unlocked
                                                ? 'You’re ready to train.'
                                                : trial
                                                    ? 'Your first 14 days\nare on us.'
                                                    : 'Make every\nworkout count.',
                                            key: const ValueKey(
                                                'membership-headline'),
                                            style: TextStyle(
                                                fontSize: compact ? 32 : 36,
                                                fontWeight: FontWeight.w700,
                                                height: 1.08,
                                                letterSpacing: -1.2)),
                                        const SizedBox(height: 12),
                                        FitnessText(
                                            unlocked
                                                ? _accessSummary(access!)
                                                : trial
                                                    ? fitnessText(context,
                                                        'Try your complete training and nutrition plan. Then {price}, unless you cancel.',
                                                        values: {
                                                            'price': renewal!
                                                          })
                                                    : 'A plan built for your body, your equipment and the time you have.',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                                color: FitnessTheme.muted)),
                                        const SizedBox(height: 24),
                                        if (!unlocked) ...[
                                          if (service.offers.isNotEmpty) ...[
                                            for (final interval in [
                                              'annual',
                                              'monthly'
                                            ])
                                              if (service.offers[interval]
                                                  case final candidate?)
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 10),
                                                    child: _PlanChoice(
                                                        key: ValueKey(
                                                            'membership-$interval'),
                                                        interval: interval,
                                                        offer: candidate,
                                                        selected: _interval ==
                                                            interval,
                                                        savings: interval ==
                                                                'annual'
                                                            ? service
                                                                .annualSavings
                                                            : null,
                                                        onTap: service.busy ||
                                                                pending
                                                            ? null
                                                            : () => setState(
                                                                () => _interval =
                                                                    interval))),
                                            const SizedBox(height: 18),
                                          ] else if (_refreshing) ...[
                                            const Center(
                                                child: Padding(
                                                    padding: EdgeInsets.all(20),
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white))),
                                            const FitnessText(
                                                'Loading your store prices…',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: FitnessTheme.muted,
                                                    fontSize: 13)),
                                            const SizedBox(height: 20),
                                          ] else ...[
                                            const _AvailabilityNotice(),
                                            const SizedBox(height: 24),
                                          ],
                                          if (trial)
                                            _TrialTimeline(
                                                price: renewal!,
                                                storeName: service.storeName),
                                          if (trial) const SizedBox(height: 28),
                                        ],
                                        const _IncludedFeatures(),
                                        const SizedBox(height: 20),
                                        const FitnessText(
                                            'Built around your experience, goals and schedule. Your progress helps shape what comes next.',
                                            style: TextStyle(
                                                color: FitnessTheme.muted,
                                                fontSize: 12,
                                                height: 1.5)),
                                        if (unlocked) ...[
                                          const SizedBox(height: 16),
                                          if (access!.state == 'active' ||
                                              !access.legacyTrial)
                                            OutlinedButton(
                                                onPressed: service.busy
                                                    ? null
                                                    : service.manage,
                                                child: const FitnessText(
                                                    'Manage subscription')),
                                        ],
                                      ])),
                            ])),
                        Container(
                            key: const ValueKey('membership-footer'),
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                            decoration: const BoxDecoration(
                                color: Colors.black,
                                border: Border(
                                    top: BorderSide(color: Color(0xFF242424)))),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (message != null)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Semantics(
                                            liveRegion: true,
                                            child: FitnessText(message,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFFD0D0D0),
                                                    height: 1.35)))),
                                  if (!unlocked && offer != null) ...[
                                    FitnessText(
                                        trial
                                            ? '14 days free, then {price}'
                                            : '{price} · auto-renewing',
                                        values: {'price': renewal!},
                                        key: const ValueKey(
                                            'membership-renewal-price'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 10),
                                  ],
                                  LiquidChromeButton(
                                      pill: true,
                                      solid: true,
                                      showArrow: false,
                                      title: unlocked
                                          ? 'Continue to my plan'
                                          : _refreshing
                                              ? 'Loading plans'
                                              : pending
                                                  ? 'Waiting for confirmation'
                                                  : offer == null
                                                      ? 'Retry loading plans'
                                                      : trial
                                                          ? 'Start my 14-day free trial'
                                                          : 'Subscribe & continue',
                                      isLoading: service.busy || _refreshing,
                                      onPressed: unlocked
                                          ? _continue
                                          : offer == null && !_refreshing
                                              ? _refresh
                                              : canBuy
                                                  ? _purchase
                                                  : null),
                                  if (!unlocked && offer != null)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 9),
                                        child: FitnessText(
                                            trial
                                                ? 'No charge today. Cancel in {store} before your trial ends to avoid payment.'
                                                : 'Cancel in {store}. Access continues until the end of your billing period.',
                                            values: {
                                              'store': service.storeName
                                            },
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: FitnessTheme.muted,
                                                height: 1.4))),
                                  Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      children: [
                                        _legal('Restore purchases', () async {
                                          await service.restore();
                                          if (mounted &&
                                              service.access?.hasAccess ==
                                                  true) {
                                            _continue();
                                          }
                                        }),
                                        _legal(
                                            'Terms',
                                            () =>
                                                service.openLegal('termsUrl')),
                                        _legal(
                                            'Privacy',
                                            () => service
                                                .openLegal('privacyUrl')),
                                      ]),
                                ])),
                      ])),
                ));
          }));
  Widget _legal(String label, VoidCallback action) => TextButton(
      style: TextButton.styleFrom(
          foregroundColor: FitnessTheme.muted,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          minimumSize: const Size(44, 44)),
      onPressed: service.busy ? null : action,
      child: FitnessText(label, style: const TextStyle(fontSize: 10)));
  String _accessSummary(SubscriptionAccess access) {
    if (access.state == 'trial') {
      return access.legacyTrial
          ? 'Your trial runs until ${_date(access.trialEnd!)}. No automatic charge applies to this existing trial.'
          : 'Your trial runs until ${_date(access.trialEnd!)}. Manage renewal in ${service.storeName}.';
    }
    return access.data['cancelAtPeriodEnd'] == true
        ? 'Your membership stays active until ${_date(access.paidEnd!)}.'
        : 'Your membership is active. Your next renewal is ${_date(access.paidEnd!)}.';
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
    final equivalent = NumberFormat.simpleCurrency(
            name: offer.currencyCode,
            locale: Localizations.localeOf(context).toLanguageTag())
        .format(offer.amount / 12);
    return Semantics(
        button: true,
        selected: selected,
        child: Material(
            color: selected ? const Color(0xFF242424) : const Color(0xFF151515),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                    color: selected
                        ? const Color(0xFFE2E2E2)
                        : const Color(0xFF303030),
                    width: selected ? 1.3 : 1)),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              width: 19,
                              height: 19,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF707070),
                                      width: selected ? 5 : 1))),
                          const SizedBox(width: 13),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 5,
                                    children: [
                                      FitnessText(annual ? 'Yearly' : 'Monthly',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                      if (savings != null)
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFE2E2E2),
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            child: FitnessText(
                                                'Save {percent}%',
                                                values: {'percent': savings!},
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700))),
                                    ]),
                                const SizedBox(height: 6),
                                FitnessText(
                                    '${offer.price}/${fitnessText(context, annual ? 'year' : 'month')}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                FitnessText(
                                    annual
                                        ? fitnessText(
                                            context,
                                            offer.hasTrial
                                                ? '{price}/month, billed yearly after your trial'
                                                : '{price}/month, billed yearly',
                                            values: {
                                                'price': equivalent
                                              })
                                        : offer.hasTrial
                                            ? '14 days free, then billed monthly'
                                            : 'Billed monthly',
                                    style: const TextStyle(
                                        color: FitnessTheme.muted,
                                        fontSize: 11,
                                        height: 1.4)),
                              ])),
                        ])))));
  }
}

class _TrialTimeline extends StatelessWidget {
  final String price, storeName;
  const _TrialTimeline({required this.price, required this.storeName});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const FitnessText('How your trial works',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        _step(
            '01', 'Today', 'Unlock your full plan and every included feature.'),
        _step(
            '02',
            'You’re in control',
            fitnessText(context, 'Manage or cancel anytime in {store}.',
                values: {'store': storeName})),
        _step(
            '03',
            'After 14 days',
            fitnessText(
                context, '{price}. Renews automatically unless canceled.',
                values: {'price': price}),
            last: true),
      ]);
  Widget _step(String number, String title, String detail,
          {bool last = false}) =>
      IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
            width: 27,
            child: Column(children: [
              Text(number,
                  style: const TextStyle(
                      color: Color(0xFFD5D5D5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              if (!last)
                Expanded(
                    child: Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: const Color(0xFF383838))),
            ])),
        const SizedBox(width: 16),
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FitnessText(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      FitnessText(detail,
                          style: const TextStyle(
                              color: FitnessTheme.muted,
                              fontSize: 12,
                              height: 1.5)),
                    ]))),
      ]));
}

class _IncludedFeatures extends StatelessWidget {
  const _IncludedFeatures();
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const FitnessText('See what’s included.',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.5)),
        const SizedBox(height: 9),
        const FitnessText(
            'Every feature below is included in your trial and paid membership.',
            style: TextStyle(
                color: FitnessTheme.muted, fontSize: 12, height: 1.5)),
        const SizedBox(height: 20),
        ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DecoratedBox(
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF303030)),
                    borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  _comparisonRow(
                      context,
                      const FitnessText('Your membership',
                          style: TextStyle(
                              fontSize: 12, color: FitnessTheme.muted)),
                      header: true),
                  _comparisonRow(
                      context,
                      const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FitnessText('Personalized weekly workouts',
                                style: TextStyle(fontSize: 13, height: 1.45)),
                            SizedBox(height: 5),
                            FitnessText('Sets, reps & weight guidance',
                                style: TextStyle(
                                    fontSize: 11,
                                    height: 1.45,
                                    color: FitnessTheme.muted)),
                          ])),
                  for (final feature in const [
                    'Warm-ups for your workout',
                    'Exercise videos & instructions',
                    'Saved routines & custom exercises',
                    'Workout logging & history',
                    'Muscle maps & strength trends',
                    'Personal records & exercise progress',
                    'Nutrition around your goals',
                    'Calories, macros & water logging',
                    'Training readiness & sleep check-ins',
                    'Body measurements & progress',
                    'Progress photos & comparisons',
                  ])
                    _comparisonRow(
                        context,
                        FitnessText(feature,
                            style:
                                const TextStyle(fontSize: 13, height: 1.45))),
                ]))),
      ]);
  Widget _comparisonRow(BuildContext context, Widget label,
          {bool header = false}) =>
      IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: Container(
                padding: const EdgeInsets.fromLTRB(15, 18, 10, 18),
                decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFF292929)))),
                alignment: Alignment.centerLeft,
                child: label)),
        _comparisonCell(context, header: header, included: false),
        _comparisonCell(context, header: header, included: true),
      ]));
  Widget _comparisonCell(BuildContext context,
          {required bool header, required bool included}) =>
      Container(
          width: MediaQuery.sizeOf(context).width < 350 ? 59 : 68,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
          decoration: BoxDecoration(
              color:
                  included ? const Color(0xFF232323) : const Color(0xFF101010),
              border:
                  const Border(bottom: BorderSide(color: Color(0xFF303030)))),
          child: header
              ? FitnessText(included ? 'With\nSetcraft' : 'Without\nSetcraft',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: included ? Colors.white : FitnessTheme.muted))
              : Semantics(
                  label: included
                      ? 'Included with Setcraft'
                      : 'Membership required',
                  child: ExcludeSemantics(
                      child: Icon(
                          included ? Icons.check_rounded : Icons.close_rounded,
                          size: included ? 24 : 19,
                          color: included
                              ? const Color(0xFFE4E4E4)
                              : const Color(0xFF626262)))));
}

class _AvailabilityNotice extends StatelessWidget {
  const _AvailabilityNotice();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF303030))),
      child:
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText('We couldn’t load your plans.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        SizedBox(height: 7),
        FitnessText(
            'Check your connection and try again. Your answers are saved. You won’t be charged without confirming in the store.',
            style: TextStyle(
                color: FitnessTheme.muted, fontSize: 12, height: 1.5)),
      ]));
}
