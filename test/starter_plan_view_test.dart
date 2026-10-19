import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/features/onboarding/data/starter_plan_repository.dart';
import 'package:fitai_mobile/features/onboarding/views/starter_plan_view.dart';
import 'package:fitai_mobile/features/subscription/subscription_service.dart';

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

class StarterRepo extends StarterPlanRepository {
  Map<String, dynamic> value = complete();
  int starts = 0, polls = 0, activations = 0;
  bool activationFails = false;
  bool validationFails = false;
  @override
  Future<void> prepareUnlock(String id) async {
    if (validationFails) {
      throw StateError('Your setup changed. Review your plan.');
    }
  }

  @override
  Future<Map<String, dynamic>> start() async {
    starts++;
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
    if (activationFails) {
      throw StateError('Could not activate. Please try again.');
    }
  }
}

class TrialService extends SubscriptionService {
  int starts = 0;
  bool fail = false;
  VoidCallback? onRefresh;
  TrialService() {
    available();
  }
  void available() => access = SubscriptionAccess(
      {'state': 'available', 'serverTime': '2026-10-19T12:00:00Z'});
  @override
  Future<void> refresh() async {
    onRefresh?.call();
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
              repository: repo, subscription: service, onComplete: done)),
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
  testWidgets(
      'Preview reveals real details without starting access; explicit trial tap activates',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    String? opened;
    await tester.pumpWidget(screen(repo, service, (id) => opened = id));
    await tester.pumpAndSettle();
    expect(find.text('Rules-based starter plan'), findsOneWidget);
    expect(find.text('Dumbbell floor press'), findsOneWidget);
    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Legs'), findsOneWidget);
    expect(service.starts, 0);
    expect(repo.activations, 0);
    await tester.tap(find.text('Start my 14-day trial'));
    await tester.pumpAndSettle();
    expect(service.starts, 1);
    expect(repo.activations, 1);
    expect(opened, 'starter-plan');
  });
  testWidgets('Trial failure never activates a plan', (tester) async {
    final repo = StarterRepo(), service = TrialService()..fail = true;
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start my 14-day trial'));
    await tester.pumpAndSettle();
    expect(repo.activations, 0);
    expect(service.access!.trialAvailable, true);
  });
  testWidgets('An outdated preview never starts a trial', (tester) async {
    final repo = StarterRepo()..validationFails = true;
    final service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start my 14-day trial'));
    await tester.pumpAndSettle();
    expect(service.starts, 0);
    expect(repo.activations, 0);
    expect(find.text('Your setup changed. Review your plan.'), findsOneWidget);
  });
  testWidgets('Changing account before unlock never starts trial or activates',
      (tester) async {
    final repo = StarterRepo(), service = TrialService();
    await tester.pumpWidget(screen(repo, service, (_) {}));
    await tester.pumpAndSettle();
    service.onRefresh = () => FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'other', 'fitai_user_id': 'other-user'});
    await tester.tap(find.text('Start my 14-day trial'));
    await tester.pumpAndSettle();
    expect(service.starts, 0);
    expect(repo.activations, 0);
  });
  testWidgets('Not now leaves without starting trial', (tester) async {
    final repo = StarterRepo(), service = TrialService();
    var left = false;
    await tester.pumpWidget(screen(repo, service, (_) => left = true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(left, true);
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
    await tester.tap(find.text('Start my 14-day trial'));
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
    expect(find.text('Your plan, built around you.'), findsOneWidget);
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
