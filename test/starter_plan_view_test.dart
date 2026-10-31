import 'package:setcraft/features/body_scan/models/body_assessment_models.dart';
import 'package:setcraft/features/body_scan/views/body_entry_view.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
                'name': 'Dumbbell floor press',
                'sets': 2,
                'repsMin': 10,
                'repsMax': 10
              },
              {'name': 'Dumbbell row', 'sets': 2, 'repsMin': 10, 'repsMax': 10}
            ]
          },
        }
      },
    };

class BaselineStarterRepo extends StarterRepo {
  bool unavailable = false;
  @override
  Future<Map<String, dynamic>> start() async {
    starts++;
    final request = RequestOptions(path: '/api/plans/starter');
    throw DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 422, data: {
          'code': 'MEASUREMENTS_REQUIRED',
          'error': 'Complete your measurements.'
        }));
  }

  @override
  Future<BodyOverview> bodyOverview() async {
    if (unavailable)
      throw StateError('Could not load measurements. Try again.');
    return BodyOverview.fromJson({
      'profile': {'height': 175},
      'records': []
    });
  }
}

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
        price: '€99.99',
        rawPrice: 99.99,
        currencyCode: 'EUR');
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

  testWidgets('Starter requires baseline setup before generation or checkout',
      (tester) async {
    final repo = BaselineStarterRepo(), service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('Complete your measurements'), findsOneWidget);
    expect(find.text('Add measurements'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(service.starts, 0);
    expect(repo.activations, 0);
    await tester.tap(find.text('Add measurements'));
    await tester.pumpAndSettle();
    expect(find.byType(BodyEntryView), findsOneWidget);
    expect(
        tester
            .widget<BodyEntryView>(find.byType(BodyEntryView))
            .requireBaseline,
        isTrue);
  });
  testWidgets('Starter shows a retryable error when baseline cannot load',
      (tester) async {
    final repo = BaselineStarterRepo()..unavailable = true;
    await tester.pumpWidget(screen(repo, TrialService(), (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add measurements'));
    await tester.pumpAndSettle();
    expect(
        find.text('Could not load measurements. Try again.'), findsOneWidget);
    expect(find.text('Add measurements'), findsOneWidget);
  });
  testWidgets(
      'Preview reveals real details, then verified store checkout activates the plan',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    expect(find.text('How this plan was built'), findsNothing);
    expect(find.text('Not now'), findsNothing);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
    expect(find.byIcon(Icons.view_week_outlined), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    expect(find.text('Dumbbell floor press'), findsOneWidget);
    expect(find.text('Your recommended week'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('starter-day-2026-10-19')), findsOneWidget);
    expect(find.text('Rest day'), findsNWidgets(3));
    expect(find.text('Unlock your full plan'), findsOneWidget);
    expect(service.starts, 0);
    expect(repo.activations, 0);
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    expect(service.starts, 0);
    expect(repo.activations, 0);
    await tester.tap(find.byKey(const ValueKey('membership-primary-action')));
    await tester.pumpAndSettle();
    expect(service.starts, 1);
    expect(repo.activations, 1);
    expect(opened, 'starter-plan');
  });
  testWidgets(
      'Visible pricing opens without starting trial or activating the plan',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = StarterRepo(), service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('Membership'), findsNothing);
    final pricing = find.text('Unlock my plan');
    expect(pricing.hitTestable(), findsOneWidget);
    await tester.tap(pricing);
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(service.pricingLoads, 1);
    expect(service.starts, 0);
    expect(repo.activations, 0);
  });
  testWidgets(
      'Existing trial access opens the plan without another membership prompt',
      (tester) async {
    final repo = StarterRepo();
    final service = TrialService()
      ..access = SubscriptionAccess({
        'state': 'trial',
        'serverTime': DateTime.now().toUtc().toIso8601String(),
        'trialEndsAt': DateTime.now()
            .add(const Duration(days: 7))
            .toUtc()
            .toIso8601String(),
      });
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    expect(find.text('Open my full plan'), findsOneWidget);
    expect(find.text('Choose your membership next'), findsNothing);
    expect(find.text('Unlock your full plan'), findsNothing);
    await tester.tap(find.text('Open my full plan'));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsNothing);
    expect(repo.activations, 1);
    expect(service.starts, 0);
    expect(opened, 'starter-plan');
  });
  testWidgets('Trial failure never activates a plan', (tester) async {
    final repo = StarterRepo(), service = TrialService()..fail = true;
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('membership-primary-action')));
    await tester.pumpAndSettle();
    expect(repo.activations, 0);
    expect(service.access!.trialAvailable, true);
  });
  testWidgets(
      'Planner failure keeps saved answers and retries without preferences',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const capture = ValueKey('starter-failure-preview');
    final repo = StarterRepo()
      ..value = {
        'id': 'starter-run',
        'status': 'FAILED',
        'errorCode': 'PLAN_QUALITY',
        'canRetry': true,
      };
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}, capture: capture));
    await tester.pumpAndSettle();
    expect(find.text('We could not finish your plan'), findsOneWidget);
    expect(
        find.text(
            'Your answers are saved. You do not need to fill them in again.'),
        findsOneWidget);
    expect(find.text('Review preferences'), findsNothing);
    expect(
        find.text('Your plan needs a little more information'), findsNothing);
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(capture))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/starter-recovery-preview.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    repo.value = complete();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repo.starts, 2);
    expect(find.text('Nora, your plan is ready'), findsOneWidget);
    expect(service.starts, 0);
    expect(repo.activations, 0);
  });
  testWidgets('Only a catalogue gap offers equipment review', (tester) async {
    final repo = StarterRepo()
      ..value = {
        'id': 'starter-run',
        'status': 'FAILED',
        'errorCode': 'CATALOG_GAP',
        'canRetry': true,
      };
    await tester.pumpWidget(screen(repo, TrialService(), (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('Review equipment'), findsOneWidget);
    expect(find.text('Review preferences'), findsNothing);
  });
  testWidgets(
      'Exhausted attempts leave clearly instead of repeating a failed run',
      (tester) async {
    final repo = StarterRepo()
      ..value = {
        'id': 'starter-run',
        'status': 'FAILED',
        'errorCode': 'RETRY_EXHAUSTED',
        'canRetry': false,
      };
    final service = TrialService();
    var closed = false;
    await tester.pumpWidget(screen(repo, service, (_) => closed = true));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsNothing);
    await tester.tap(find.text('View membership'));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(repo.starts, 1);
    expect(service.starts, 0);
  });
  testWidgets('A validation failure never starts checkout', (tester) async {
    final repo = StarterRepo()..validationFails = true;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    expect(service.starts, 0);
    expect(repo.activations, 0);
    expect(find.text('Your setup changed. Review your plan.'), findsOneWidget);
  });
  testWidgets(
      'Unlock is visibly busy and rejects repeated taps while validating',
      (tester) async {
    final gate = Completer<void>();
    final repo = StarterRepo()..validationGate = gate;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    final button = find.text('Unlock my plan');
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Checking your plan…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repo.validations, 1);
    expect(find.byType(SubscriptionView), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(service.starts, 0);
  });
  testWidgets(
      'Stale preview refreshes before checkout and unlocks the new plan',
      (tester) async {
    final repo = StarterRepo()
      ..staleValidations = 1
      ..refreshValue = refreshedPlan();
    final service = TrialService();
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    expect(repo.starts, 2);
    expect(repo.validations, 2);
    expect(service.starts, 0);
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(find.textContaining('Your history or preferences changed'),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('membership-primary-action')));
    await tester.pumpAndSettle();
    expect(opened, 'refreshed-plan');
    expect(repo.activatedIds, ['refreshed-plan']);
    expect(service.starts, 1);
  });
  testWidgets('Queued refresh resumes unlock only in the foreground',
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
    await tester.tap(find.text('Unlock my plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Updating your plan…'), findsNWidgets(2));
    expect(find.byType(SubscriptionView), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    repo.value = refreshedPlan();
    await tester.pump(const Duration(seconds: 6));
    expect(repo.polls, 0);
    expect(find.byType(SubscriptionView), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionView), findsOneWidget);
    expect(service.starts, 0);
    expect(repo.starts, 2);
  });
  testWidgets(
      'A second stale response stops automatic refresh and offers retry',
      (tester) async {
    final repo = StarterRepo()..alwaysStale = true;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    expect(repo.starts, 2);
    expect(
        find.text('Your setup changed again. Refresh your plan to continue.'),
        findsOneWidget);
    expect(find.text('Refresh my plan'), findsOneWidget);
    expect(find.byType(SubscriptionView), findsNothing);
    expect(service.starts, 0);
  });
  testWidgets(
      'Failed automatic refresh keeps answers and offers a working retry',
      (tester) async {
    final repo = StarterRepo()
      ..staleValidations = 1
      ..refreshFails = true;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    expect(find.text('Could not update your plan. Try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(service.starts, 0);
    repo.refreshFails = false;
    repo.refreshValue = refreshedPlan();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock my plan'), findsOneWidget);
    expect(repo.starts, 3);
  });
  testWidgets('Staleness after checkout refreshes without another purchase',
      (tester) async {
    final repo = StarterRepo()
      ..staleActivations = 1
      ..refreshValue = refreshedPlan();
    final service = TrialService();
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('membership-primary-action')));
    await tester.pumpAndSettle();
    expect(repo.starts, 2);
    expect(repo.activatedIds, ['starter-plan', 'refreshed-plan']);
    expect(service.starts, 1);
    expect(opened, 'refreshed-plan');
    expect(find.byType(SubscriptionView), findsNothing);
  });
  testWidgets('Changing account before unlock never starts trial or activates',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    service.onRefresh = () => FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'other', 'fitai_user_id': 'other-user'});
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    expect(service.starts, 0);
    expect(repo.activations, 0);
  });
  testWidgets('Membership never leaves the preview without verified access',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    var left = false;
    await tester.pumpWidget(screen(repo, service, (_) => left = true));
    await tester.pumpAndSettle();
    expect(find.text('Not now'), findsNothing);
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    expect(left, false);
    expect(service.starts, 0);
    expect(repo.activations, 0);
  });
  testWidgets('Capture the muscle preview at standard phone size',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const capture = ValueKey('normal-starter');
    final repo = StarterRepo();
    final groups =
        (repo.value['plan'] as Map)['preview']['muscleGroups'] as List;
    groups[0]['exercises'][0]['name'] = 'Clock push-up';
    groups[1]['exercises'][0]['name'] = 'Bodyweight standing row (with towel)';
    await tester
        .pumpWidget(screen(repo, TrialService(), (_) {}, capture: capture));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    Future<void> save(String name) async {
      await tester.runAsync(() async {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('build/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await save('starter-muscle-preview');
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await save('starter-trial-preview');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Activation retry never restarts a confirmed trial',
      (tester) async {
    final repo = StarterRepo()..activationFails = true;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock my plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('membership-primary-action')));
    await tester.pumpAndSettle();
    repo.activationFails = false;
    await tester.tap(find.text('Open my full plan'));
    await tester.pumpAndSettle();
    expect(service.starts, 1);
    expect(repo.activations, 2);
  });
  testWidgets(
      'Loading uses confirmed stages, pauses in background, then shows saved result',
      (tester) async {
    final repo = StarterRepo()
      ..value = {
        'id': 'starter-run',
        'status': 'RUNNING',
        'stage': 'specialists'
      };
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choosing exercises for your equipment'), findsOneWidget);
    expect(service.starts, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final calls = repo.polls;
    await tester.pump(const Duration(seconds: 6));
    expect(repo.polls, calls);
    repo.value = complete();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('starter-ready-title')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  for (final locale in [
    const Locale('en', 'GB'),
    const Locale('de', 'DE'),
    const Locale('de', 'CH')
  ]) {
    testWidgets(
        'Starter screen fits narrow large-text ${locale.toLanguageTag()}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const capture = ValueKey('starter-capture');
      await tester.pumpWidget(screen(StarterRepo(), TrialService(), (_) {},
          scale: 1.4, locale: locale, capture: capture));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('build/starter-plan-${locale.toLanguageTag()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('build/starter-trial-${locale.toLanguageTag()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
