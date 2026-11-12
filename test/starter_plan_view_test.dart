import 'package:setcraft/features/auth/views/auth_view.dart';
import 'package:setcraft/features/body_scan/views/body_entry_view.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/onboarding/data/starter_plan_repository.dart';
import 'package:setcraft/features/onboarding/views/starter_plan_view.dart';
import 'package:setcraft/features/subscription/subscription_service.dart';
import 'package:setcraft/features/subscription/subscription_view.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

Map<String, dynamic> complete() => {
      'id': 'starter-run',
      'status': 'COMPLETED',
      'plan': {
        'id': 'starter-plan',
        'status': 'DRAFT',
        'payload': null,
        'preview': {
          'source': 'rules',
          'weekStart': '2026-10-19',
          'muscleGroups': [
            {
              'region': 'chest',
              'exerciseCount': 2,
              'lockedCount': 1,
              'exercises': [
                {
                  'exerciseId': 'preview-press',
                  'name': 'Dumbbell floor press',
                  'sets': 2,
                  'repsMin': 10,
                  'repsMax': 10
                }
              ]
            },
            {
              'region': 'back',
              'exerciseCount': 3,
              'lockedCount': 2,
              'exercises': [
                {
                  'name': 'Dumbbell row',
                  'sets': 2,
                  'repsMin': 10,
                  'repsMax': 10
                }
              ]
            },
            {
              'region': 'legs',
              'exerciseCount': 3,
              'lockedCount': 3,
              'exercises': []
            },
            for (final region in ['shoulders', 'biceps', 'triceps', 'core'])
              {
                'region': region,
                'exerciseCount': 2,
                'lockedCount': 2,
                'exercises': []
              },
          ],
          'workouts': [
            for (var i = 0; i < 7; i++)
              {
                'date': '2026-10-${19 + i}',
                'name': i.isEven ? 'Full body' : 'Rest day',
                'restDay': i.isOdd,
                'estimatedMinutes': i.isOdd ? 0 : 30
              }
          ],
          'firstWorkout': {
            'name': 'Full body',
            'date': '2026-10-19',
            'exerciseCount': 4,
            'exercises': [
              {
                'exerciseId': 'preview-press',
                'name': 'Dumbbell floor press',
                'sets': 2,
                'repsMin': 10,
                'repsMax': 10
              },
              {
                'exerciseId': 'preview-row',
                'name': 'Dumbbell row',
                'sets': 2,
                'repsMin': 10,
                'repsMax': 10
              }
            ]
          },
        }
      },
    };

class StarterRepo extends StarterPlanRepository {
  Map<String, dynamic> value = complete();
  int starts = 0, polls = 0, activations = 0;
  int validations = 0, staleValidations = 0, staleActivations = 0;
  bool alwaysStale = false, refreshFails = false;
  Map<String, dynamic>? refreshValue;
  Completer<void>? validationGate;
  final activatedIds = <String>[];
  bool activationFails = false;
  bool validationFails = false;
  @override
  Future<void> prepareUnlock(String id) async {
    validations++;
    await validationGate?.future;
    if (staleValidations > 0 || alwaysStale) {
      staleValidations--;
      throw stalePlan();
    }
    if (validationFails) {
      throw StateError('Your setup changed. Review your plan.');
    }
  }

  @override
  Future<Map<String, dynamic>> start() async {
    starts++;
    if (starts > 1) {
      if (refreshFails) {
        throw StateError('Could not update your plan. Try again.');
      }
      if (refreshValue != null) value = refreshValue!;
    }
    return value;
  }

  @override
  Future<Map<String, dynamic>> run(String id) async {
    polls++;
    return value;
  }

  @override
  Future<void> activate(String id) async {
    activations++;
    activatedIds.add(id);
    if (staleActivations > 0) {
      staleActivations--;
      throw stalePlan();
    }
    if (activationFails) {
      throw StateError('Could not activate. Please try again.');
    }
  }
}

DioException stalePlan() {
  final options = RequestOptions(path: '/api/plans/starter/validate');
  return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: options, statusCode: 409, data: {
        'code': 'STALE_PLAN',
        'error':
            'Your history or preferences changed. Generate an updated plan.'
      }));
}

Map<String, dynamic> refreshedPlan() {
  final result = complete();
  (result['plan'] as Map)['id'] = 'refreshed-plan';
  return result;
}

class TrialService extends SubscriptionService {
  int starts = 0;
  int pricingLoads = 0;
  @override
  bool get android => true;
  @override
  Future<void> initialize() async {
    pricingLoads++;
    storeReady = true;
    final product = ProductDetails(
        id: 'annual',
        title: 'Annual',
        description: 'Fixture',
        price: '\$69.00',
        rawPrice: 69,
        currencyCode: 'USD');
    offers['monthly'] = MembershipOffer(
        product: ProductDetails(
            id: 'monthly',
            title: 'Monthly',
            description: 'Fixture',
            price: '\$9.99',
            rawPrice: 9.99,
            currencyCode: 'USD'),
        price: '\$9.99',
        amount: 9.99);
    offers['annual'] = MembershipOffer(
        product: product,
        price: product.price,
        amount: product.rawPrice,
        trialDays: 14);
  }

  @override
  Future<void> purchase(String interval) async {
    await startTrial();
    notifyListeners();
  }

  bool fail = false;
  VoidCallback? onRefresh;
  TrialService() {
    available();
  }
  void available() => access = SubscriptionAccess({
        'state': 'available',
        'billingReady': true,
        'serverTime': '2026-10-19T12:00:00Z'
      });
  @override
  Future<void> refresh() async {
    onRefresh?.call();
  }

  @override
  Future<Map<String, dynamic>> loadPricing() async {
    pricingLoads++;
    return {
      'countryCode': 'GB',
      'countries': [
        {
          'code': 'GB',
          'name': 'United Kingdom',
          'currency': 'GBP',
          'monthly': 9.99,
          'annual': 59.99
        },
      ]
    };
  }

  @override
  Future<void> startTrial() async {
    starts++;
    if (fail) {
      error = 'Could not start your trial. Please try again.';
      return;
    }
    access = SubscriptionAccess({
      'state': 'trial',
      'serverTime': '2026-10-19T12:00:00Z',
      'trialEndsAt': '2026-11-02T12:00:00Z'
    });
  }
}

Widget screen(
        StarterRepo repo, TrialService service, ValueChanged<String?> done,
        {double scale = 1,
        Locale locale = const Locale('en', 'GB'),
        Key? capture}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('en', 'GB'),
        Locale('de', 'DE'),
        Locale('de', 'CH')
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              disableAnimations: true, textScaler: TextScaler.linear(scale)),
          child: child!),
      home: RepaintBoundary(
          key: capture,
          child: StarterPlanView(
              requestAiConsent: (_) async => true,
              repository: repo,
              subscription: service,
              onComplete: done,
              profileLoader: () async => {
                    'name': 'Nora',
                    'gender': 'FEMALE',
                    'workingToward': 'BUILD_MUSCLE',
                    'experience': 'BEGINNER',
                    'trainingLocation': 'HOME',
                    'equipmentIds': ['dumbbells'],
                    'focusMuscles': <String>[]
                  })),
    );
void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues(
      {'fitai_access_token': 'opaque', 'fitai_user_id': 'starter-test'}));

  final action = find.byKey(const ValueKey('membership-primary-action'));
  Future<void> tapAction(WidgetTester tester) async {
    if (find.byType(SubscriptionView).evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('starter-unlock')));
      await tester.pumpAndSettle();
      if (find.byType(SubscriptionView).evaluate().isEmpty) return;
    }
    await tester.tap(action);
  }

  testWidgets('Visual plan opens membership only after Unlock full plan',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('Your plan is ready'), findsOneWidget);
    expect(find.byType(SubscriptionView), findsNothing);
    expect(find.byType(BodyEntryView), findsNothing);
    expect(find.text('Dumbbell floor press'), findsOneWidget);
    expect(find.text('Unlock full plan').hitTestable(), findsOneWidget);
    expect(repo.validations, 0);
    await tester.tap(find.byKey(const ValueKey('starter-unlock')));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 12'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('membership-monthly')), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('\$9.99'), findsOneWidget);
    expect(find.text('\$69.00'), findsOneWidget);
    expect(find.text('Save 42%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('membership-close')));
    await tester.pumpAndSettle();
    expect(find.text('Your plan is ready'), findsOneWidget);
    expect(repo.activations, 0);
    expect(service.starts, 0);
  });
  testWidgets(
      'One action validates, opens payment, and activates the verified plan',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(service.starts, 1);
    expect(repo.validations, 2);
    expect(repo.activations, 1);
    expect(opened, 'starter-plan');
  });
  testWidgets('Existing access opens directly without another purchase',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    service.access = SubscriptionAccess({
      'state': 'active',
      'paidUntil': '2099-01-01T00:00:00Z',
      'serverTime': '2026-10-19T12:00:00Z'
    });
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    expect(find.text('Open my plan'), findsOneWidget);
    expect(find.byKey(const ValueKey('membership-annual')), findsNothing);
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(repo.activations, 1);
    expect(service.starts, 0);
    expect(opened, 'starter-plan');
  });
  testWidgets('Unverified or failed payment keeps the same plan preview',
      (tester) async {
    final repo = StarterRepo(), service = TrialService()..fail = true;
    var left = false;
    await tester.pumpWidget(screen(repo, service, (_) => left = true));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(repo.activations, 0);
    expect(left, false);
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(find.text('Could not start your trial. Please try again.'),
        findsOneWidget);
  });
  testWidgets('Validation errors stay inline and never charge', (tester) async {
    final repo = StarterRepo()..validationFails = true;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(find.text('Your setup changed. Review your plan.'), findsOneWidget);
    expect(find.byType(SubscriptionView), findsNothing);
    expect(service.starts, 0);
    expect(repo.activations, 0);
  });
  testWidgets('Repeated taps cannot open duplicate payment while validating',
      (tester) async {
    final gate = Completer<void>();
    final repo = StarterRepo()..validationGate = gate;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pump();
    await tapAction(tester);
    await tester.pump();
    expect(repo.validations, 1);
    expect(service.starts, 0);
    gate.complete();
    await tester.pumpAndSettle();
    expect(service.starts, 1);
    expect(repo.activations, 1);
  });
  testWidgets(
      'Leaving membership during validation never opens payment afterward',
      (tester) async {
    final gate = Completer<void>();
    final repo = StarterRepo()..validationGate = gate;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('starter-unlock')));
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pump();
    Navigator.of(tester.element(find.byType(SubscriptionView))).pop();
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(service.starts, 0);
    expect(repo.activations, 0);
    expect(find.text('Your plan is ready'), findsOneWidget);
  });
  testWidgets('Stale preview is refreshed before any payment opens',
      (tester) async {
    final repo = StarterRepo()
      ..staleValidations = 1
      ..refreshValue = refreshedPlan();
    final service = TrialService();
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(repo.starts, 2);
    expect(service.starts, 0);
    expect(find.text('Your plan is ready'), findsOneWidget);
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(opened, 'refreshed-plan');
    expect(repo.activatedIds, ['refreshed-plan']);
    expect(service.starts, 1);
  });
  testWidgets(
      'Queued refresh pauses in background and returns to the same decision',
      (tester) async {
    final repo = StarterRepo()
      ..staleValidations = 1
      ..refreshValue = {
        'id': 'starter-run',
        'status': 'QUEUED',
        'stage': 'queued'
      };
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    repo.value = refreshedPlan();
    await tester.pump(const Duration(seconds: 6));
    expect(repo.polls, 0);
    expect(service.starts, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsNothing);
    expect(service.starts, 0);
  });
  testWidgets('Refresh failure saves answers and offers a working retry',
      (tester) async {
    final repo = StarterRepo()
      ..staleValidations = 1
      ..refreshFails = true;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(find.text('Could not update your plan. Try again.'), findsOneWidget);
    expect(service.starts, 0);
    repo.refreshFails = false;
    repo.refreshValue = refreshedPlan();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Your plan is ready'), findsOneWidget);
    expect(repo.starts, 3);
  });
  testWidgets(
      'Staleness after verified payment refreshes without charging again',
      (tester) async {
    final repo = StarterRepo()
      ..staleActivations = 1
      ..refreshValue = refreshedPlan();
    final service = TrialService();
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(repo.activatedIds, ['starter-plan', 'refreshed-plan']);
    expect(service.starts, 1);
    expect(opened, 'refreshed-plan');
  });
  testWidgets(
      'Activation retry uses verified membership without another purchase',
      (tester) async {
    final repo = StarterRepo()..activationFails = true;
    final service = TrialService();
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(find.text('Could not activate. Please try again.'), findsOneWidget);
    repo.activationFails = false;
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(service.starts, 1);
    expect(repo.activations, 2);
    expect(opened, 'starter-plan');
  });
  testWidgets('Account change during validation cannot charge or activate',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    service.onRefresh = () => FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'other', 'fitai_user_id': 'other-user'});
    await tapAction(tester);
    await tester.pumpAndSettle();
    expect(service.starts, 0);
    expect(repo.activations, 0);
  });
  for (final code in [
    'PLAN_QUALITY',
    'CATALOG_GAP',
    'STARTER_REVIEW_REQUIRED'
  ]) {
    testWidgets(
        'Planner failure keeps answers and appropriate recovery for $code',
        (tester) async {
      final repo = StarterRepo()
        ..value = {
          'id': 'starter-run',
          'status': 'FAILED',
          'errorCode': code,
          'canRetry': true
        };
      final service = TrialService();
      await tester.pumpWidget(screen(repo, service, (_) {}));
      await tester.pumpAndSettle();
      if (code == 'PLAN_QUALITY') {
        expect(
            find.text(
                'Your answers are saved. You do not need to fill them in again.'),
            findsOneWidget);
      }
      expect(find.text('Review equipment'),
          code == 'CATALOG_GAP' ? findsOneWidget : findsNothing);
      expect(find.text('Review movement notes'),
          code == 'STARTER_REVIEW_REQUIRED' ? findsOneWidget : findsNothing);
      repo.value = complete();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Your plan is ready'), findsOneWidget);
      expect(service.starts, 0);
    });
  }
  for (final locale in [const Locale('en', 'GB'), const Locale('de', 'DE')]) {
    testWidgets('Plan preview fits narrow large text ${locale.toLanguageTag()}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(screen(StarterRepo(), TrialService(), (_) {},
          scale: 1.6, locale: locale));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('starter-unlock')).hitTestable(),
          findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Fallback screen shows View membership and top-right Sign out',
      (tester) async {
    final repo = StarterRepo()
      ..value = {
        'id': 'starter-run',
        'status': 'FAILED',
        'errorCode': 'GENERATION_FAILED',
        'canRetry': false
      };
    final service = TrialService();
    var signedOut = false;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: StarterPlanView(
        requestAiConsent: (_) async => true,
        repository: repo,
        subscription: service,
        onComplete: (_) {},
        onSignOut: () async {
          signedOut = true;
        },
        profileLoader: () async => {'gender': 'FEMALE'},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('We could not finish your plan'), findsNothing);
    expect(find.byKey(const ValueKey('starter-view-membership')), findsOneWidget);
    expect(find.byKey(const ValueKey('starter-sign-out')), findsOneWidget);
    expect(find.byKey(const ValueKey('starter-back')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('starter-view-membership')));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('membership-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('starter-sign-out')));
    await tester.pumpAndSettle();
    expect(signedOut, true);
    expect(find.byType(AuthView), findsOneWidget);
  });

  testWidgets('Building screen keeps Back and View membership available',
      (tester) async {
    final repo = StarterRepo()
      ..value = {'id': 'starter-run', 'status': 'RUNNING'};
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: StarterPlanView(
        requestAiConsent: (_) async => true,
        repository: repo,
        subscription: TrialService(),
        onComplete: (_) {},
        profileLoader: () async => {},
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('starter-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('starter-view-membership')), findsOneWidget);
    expect(find.byKey(const ValueKey('starter-sign-out')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Preview shows injury adaptation note and top-right Sign out',
      (tester) async {
    final repo = StarterRepo();
    ((repo.value['plan'] as Map)['preview'] as Map)['adaptationNote'] =
        'Adapted for your movement needs: shoulder-safe.';
    final service = TrialService();
    var signedOut = false;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: StarterPlanView(
        requestAiConsent: (_) async => true,
        repository: repo,
        subscription: service,
        onComplete: (_) {},
        onSignOut: () async {
          signedOut = true;
        },
        profileLoader: () async => {'gender': 'FEMALE'},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('starter-adaptation-note')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('starter-sign-out')));
    await tester.pumpAndSettle();
    expect(signedOut, true);
    expect(find.byType(AuthView), findsOneWidget);
  });
}
