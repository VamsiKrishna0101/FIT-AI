import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/components/liquid_chrome_button.dart';
import '../../core/components/motion.dart';
import '../../core/localization/fitness_copy.dart';
import '../../core/localization/fitness_text.dart';
import '../../core/theme/ds_colors.dart';
import '../../core/theme/ds_motion.dart';
import '../../core/theme/fitness_theme.dart';
import 'subscription_service.dart';

class SubscriptionPricingView extends StatefulWidget {
  final SubscriptionService service;
  final VoidCallback? onContinue;
  const SubscriptionPricingView(
      {super.key, required this.service, this.onContinue});

  @override
  State<SubscriptionPricingView> createState() =>
      _SubscriptionPricingViewState();
}

class _SubscriptionPricingViewState extends State<SubscriptionPricingView> {
  Map<String, dynamic>? _catalog;
  String? _country, _error;
  String _interval = 'annual';
  bool _loading = false;
  int _request = 0;
  SubscriptionService get service => widget.service;

  List<Map<String, dynamic>> get _countries =>
      (_catalog?['countries'] as List? ?? [])
          .whereType<Map>()
          .map((value) => Map<String, dynamic>.from(value))
          .toList();

  Map<String, dynamic>? get _countryPrice => _countries
      .where((row) => row['code'] == (_country ?? _catalog?['countryCode']))
      .firstOrNull;

  bool get _live => _country == null && service.plansAvailable;

  @override
  void initState() {
    super.initState();
    if (service.plansAvailable && !service.products.containsKey(_interval)) {
      _interval = service.products.keys.first;
    }
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await service.loadPricing();
      if (mounted && request == _request) {
        setState(() => _catalog = catalog);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'Could not load pricing. Please try again.');
      }
    } finally {
      if (mounted && request == _request) {
        setState(() => _loading = false);
      }
    }
  }

  String _money(num amount, String currency) => NumberFormat.simpleCurrency(
        locale: Localizations.localeOf(context).toLanguageTag(),
        name: currency,
        decimalDigits: amount % 1 == 0 ? 0 : 2,
      ).format(amount);

  Future<void> _chooseCountry() async {
    final countries = _countries;
    countries.sort((a, b) => fitnessText(context, a['name'] as String)
        .compareTo(fitnessText(context, b['name'] as String)));
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DSColors.bgCard,
      showDragHandle: true,
      isScrollControlled: true,
      sheetAnimationStyle: DSMotion.sheetStyle(context),
      builder: (sheetContext) => SafeArea(
          child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .7,
        child: Column(children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: FitnessText('Compare country prices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
          Expanded(
              child: ListView(children: [
            if (service.plansAvailable)
              ListTile(
                leading: const Icon(CupertinoIcons.bag),
                title: const FitnessText('Use Google Play prices'),
                onTap: () {
                  setState(() => _country = null);
                  Navigator.pop(sheetContext);
                },
              ),
            for (final country in countries)
              ListTile(
                key: ValueKey('pricing-country-${country['code']}'),
                title: FitnessText(country['name'] as String,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(country['currency'] as String,
                    style: const TextStyle(
                        fontSize: 11, color: DSColors.textSecondary)),
                trailing:
                    country['code'] == (_country ?? _catalog?['countryCode'])
                        ? const Icon(CupertinoIcons.checkmark, size: 17)
                        : null,
                onTap: () {
                  setState(() => _country = country['code'] as String);
                  Navigator.pop(sheetContext);
                },
              ),
          ])),
        ]),
      )),
    );
  }

  void _continue() {
    Navigator.pop(context);
    widget.onContinue?.call();
  }

  Future<void> _startTrial() async {
    await service.startTrial();
    if (mounted && service.access?.hasAccess == true) _continue();
  }

  Future<void> _purchase() async {
    // Recheck the current mode when tapped; a country preview cannot buy a plan.
    if (!_live || service.products.isEmpty || service.busy) return;
    final interval = service.products.containsKey(_interval)
        ? _interval
        : service.products.keys.first;
    await service.purchase(interval);
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final available = service.access?.trialAvailable == true;
          final trial =
              service.access?.state == 'trial' && service.access!.hasAccess;
          final active =
              service.access?.state == 'active' && service.access!.hasAccess;
          final live = _live;
          final country = _countryPrice;
          final currency = live
              ? service.products.values.first.currencyCode
              : country?['currency'] as String?;
          final monthly = live
              ? service.products['monthly']?.rawPrice
              : country?['monthly'] as num?;
          final annual = live
              ? service.products['annual']?.rawPrice
              : country?['annual'] as num?;
          final sameCurrency = !live ||
              service.products['monthly'] == null ||
              service.products['annual'] == null ||
              service.products['monthly']!.currencyCode ==
                  service.products['annual']!.currencyCode;
          final saving =
              monthly != null && annual != null && monthly > 0 && sameCurrency
                  ? ((1 - annual / (monthly * 12)) * 100).round().clamp(0, 99)
                  : 0;
          final intervals = [
            if (annual != null) 'annual',
            if (monthly != null) 'monthly'
          ];
          final selected =
              intervals.contains(_interval) ? _interval : intervals.firstOrNull;
          final purchaseReady =
              live && selected != null && !available && !trial && !active;

          return Scaffold(
            backgroundColor: DSColors.bg,
            appBar: AppBar(
                backgroundColor: DSColors.bg,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: fitnessText(context, 'Back'),
                    icon: const Icon(CupertinoIcons.chevron_left)),
                title: const FitnessText('Membership',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                children: [
                  MotionEntrance(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF292929),
                                      Color(0xFF121212)
                                    ]),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: DSColors.border)),
                            child: const Padding(
                                padding: EdgeInsets.all(9),
                                child:
                                    CustomPaint(painter: _MembershipEmblem()))),
                        const SizedBox(height: 20),
                        const FitnessText('One membership. Every feature.',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                height: 1.15,
                                letterSpacing: -.8)),
                        const SizedBox(height: 10),
                        const FitnessText(
                            'Choose the rhythm that works for you.',
                            style: TextStyle(
                                fontSize: 13,
                                color: DSColors.textSecondary,
                                height: 1.5)),
                      ])),
                  const SizedBox(height: 22),
                  Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: DSColors.bgCard,
                                borderRadius: BorderRadius.circular(20)),
                            child: FitnessText(
                                live ? 'Google Play pricing' : 'Planned prices',
                                style: const TextStyle(
                                    fontSize: 11, color: DSColors.silver))),
                        if (currency != null)
                          Text(currency,
                              style: const TextStyle(
                                  fontSize: 11, color: DSColors.textSecondary)),
                        if (_countries.isNotEmpty)
                          TextButton.icon(
                              onPressed: _chooseCountry,
                              icon: const Icon(CupertinoIcons.globe, size: 14),
                              label: FitnessText(
                                  live
                                      ? 'Compare countries'
                                      : country?['name'] as String? ??
                                          'Choose a country',
                                  style: const TextStyle(fontSize: 12))),
                      ]),
                  if (_loading)
                    const Padding(
                        padding: EdgeInsets.all(20),
                        child: CupertinoActivityIndicator()),
                  if (_error != null) ...[
                    FitnessText(_error!,
                        style: const TextStyle(
                            fontSize: 12, color: DSColors.textSecondary)),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: _load,
                            child: const FitnessText('Retry'))),
                  ],
                  if (currency != null) ...[
                    const SizedBox(height: 10),
                    for (final interval in intervals) ...[
                      _plan(
                          interval: interval,
                          selected: selected == interval,
                          live: live,
                          currency: currency,
                          amount: interval == 'annual' ? annual! : monthly!,
                          saving: saving),
                      const SizedBox(height: 12),
                    ],
                    if (saving > 0 && monthly != null && annual != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 3, bottom: 8),
                          child: Text(
                              fitnessText(context, 'Save {amount} a year',
                                  values: {
                                    'amount':
                                        _money(monthly * 12 - annual, currency)
                                  }),
                              style: const TextStyle(
                                  fontSize: 12, color: DSColors.silver))),
                    const FitnessText(
                        'Annual savings are compared with 12 monthly payments.',
                        style: TextStyle(
                            fontSize: 11,
                            color: DSColors.textSecondary,
                            height: 1.5)),
                  ] else if (!_loading && _error == null)
                    const FitnessText(
                        'Choose a country to preview monthly and annual prices.',
                        style: TextStyle(
                            fontSize: 13,
                            color: DSColors.textSecondary,
                            height: 1.5)),
                  const SizedBox(height: 20),
                  FitnessText(
                      live
                          ? 'Your store confirms the final price before payment.'
                          : 'These are planned prices. Final prices will be confirmed in your app store.',
                      style: const TextStyle(
                          fontSize: 11,
                          color: DSColors.textSecondary,
                          height: 1.5)),
                  if (_country != null && service.plansAvailable)
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: () => setState(() => _country = null),
                            child:
                                const FitnessText('Use Google Play prices'))),
                  const SizedBox(height: 22),
                  const FitnessText('Included with either plan',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  for (final label in [
                    'Personalized weekly plans',
                    'Photo scans & measurements',
                    'Nutrition & recovery',
                    'Your progress, over time'
                  ])
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(children: [
                          const Icon(CupertinoIcons.checkmark,
                              size: 13, color: DSColors.silver),
                          const SizedBox(width: 12),
                          Expanded(
                              child: FitnessText(label,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: DSColors.textSecondary))),
                        ])),
                  if (purchaseReady) ...[
                    const SizedBox(height: 20),
                    const FitnessText(
                        'Charged when you subscribe. Automatically renews until canceled in Google Play.',
                        style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: DSColors.textSecondary)),
                  ],
                  if (service.error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FitnessText(service.error!,
                            style: const TextStyle(
                                fontSize: 12, color: DSColors.textSecondary))),
                  Wrap(spacing: 8, children: [
                    if (service.access?.data['termsUrl'] != null)
                      TextButton(
                          onPressed: () => service.openLegal('termsUrl'),
                          child: const FitnessText('Terms',
                              style: TextStyle(fontSize: 11))),
                    if (service.access?.data['privacyUrl'] != null)
                      TextButton(
                          onPressed: () => service.openLegal('privacyUrl'),
                          child: const FitnessText('Privacy policy',
                              style: TextStyle(fontSize: 11))),
                  ]),
                ]),
            bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (available)
                    const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: FitnessText(
                            'No payment details. No automatic charge.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: DSColors.textSecondary))),
                  LiquidChromeButton(
                    title: available
                        ? 'Start my 14-day trial'
                        : trial
                            ? 'Continue your trial'
                            : active
                                ? 'Continue'
                                : purchaseReady
                                    ? 'Subscribe now'
                                    : 'View saved records',
                    isLoading: service.busy,
                    onPressed: service.busy
                        ? null
                        : available
                            ? _startTrial
                            : purchaseReady
                                ? _purchase
                                : _continue,
                  ),
                ])),
          );
        },
      ));

  Widget _plan(
      {required String interval,
      required bool selected,
      required bool live,
      required String currency,
      required num amount,
      required int saving}) {
    final annual = interval == 'annual';
    final product = live ? service.products[interval] : null;
    return MotionPress(
        child: Material(
      color: selected ? DSColors.bgCard : DSColors.bgElevated,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
              color: selected
                  ? DSColors.silver.withValues(alpha: .65)
                  : DSColors.border,
              width: selected ? 1 : .7)),
      child: InkWell(
        key: ValueKey('pricing-$interval'),
        borderRadius: BorderRadius.circular(22),
        onTap: service.busy
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() => _interval = interval);
              },
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                    selected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: 19,
                    color: selected ? DSColors.silver : DSColors.muted),
                const SizedBox(width: 10),
                Expanded(
                    child: FitnessText(annual ? 'Annual' : 'Monthly',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500))),
                if (annual && saving > 0)
                  Flexible(
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                              color: DSColors.bgRaised,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                              fitnessText(context, 'Save {percent}%',
                                  values: {'percent': saving}),
                              style: const TextStyle(
                                  fontSize: 11, color: DSColors.silver)))),
              ]),
              const SizedBox(height: 15),
              Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  runSpacing: 4,
                  children: [
                    Text(product?.price ?? _money(amount, currency),
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.7)),
                    FitnessText(annual ? 'per year' : 'per month',
                        style: const TextStyle(
                            fontSize: 12, color: DSColors.textSecondary)),
                  ]),
              const SizedBox(height: 8),
              Text(
                  annual
                      ? fitnessText(
                          context, '{price} per month, billed yearly', values: {
                          'price': _money(
                              amount / 12, product?.currencyCode ?? currency)
                        })
                      : fitnessText(
                          context, 'Billed monthly. Cancel in your app store.'),
                  style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: DSColors.textSecondary)),
            ])),
      ),
    ));
  }
}

class _MembershipEmblem extends CustomPainter {
  const _MembershipEmblem();

  @override
  void paint(Canvas canvas, Size size) {
    // Curved shoulders keep the four-point mark soft at small sizes.
    final star = Path()
      ..moveTo(.5, .04)
      ..cubicTo(.57, .35, .65, .43, .96, .5)
      ..cubicTo(.65, .57, .57, .65, .5, .96)
      ..cubicTo(.43, .65, .35, .57, .04, .5)
      ..cubicTo(.35, .43, .43, .35, .5, .04)
      ..close();

    canvas.save();
    canvas.scale(size.width, size.height);

    const bounds = Rect.fromLTWH(0, 0, 1, 1);
    canvas.drawPath(
        star,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFE5E7E8), Color(0xFF899296)],
            stops: [0, .48, 1],
          ).createShader(bounds));

    canvas.clipPath(star);
    canvas.drawPath(
        Path()
          ..moveTo(.5, .04)
          ..lineTo(.5, .5)
          ..lineTo(.04, .5)
          ..close(),
        Paint()..color = const Color(0x38FFFFFF));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MembershipEmblem oldDelegate) => false;
}
