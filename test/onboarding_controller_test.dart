import 'dart:async';
import 'package:setcraft/core/components/liquid_chrome_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/features/onboarding/components/onboarding_scaffold.dart';
import 'package:setcraft/features/onboarding/models/working_toward_goal.dart';
import 'package:setcraft/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:setcraft/features/onboarding/viewmodels/goal_viewmodel.dart';
import 'package:setcraft/features/onboarding/viewmodels/about_you_viewmodel.dart';
import 'package:setcraft/features/onboarding/viewmodels/schedule_location_viewmodel.dart';
import 'package:setcraft/features/onboarding/views/goal_selection_view.dart';
import 'package:setcraft/features/onboarding/views/about_you_experience_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'One restored draft is shared across steps; navigation never waits for a checkpoint',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var loads = 0;
    final write = Completer<void>();
    final controller = OnboardingController(
      load: () async {
        loads++;
        return OnboardingDraft(name: 'Elena', weightKg: 65, countryCode: 'DK');
      },
      save: (_) => write.future,
    );
    await controller.initialize();
    final goal = GoalViewModel(controller: controller);
    final about = AboutYouViewModel(controller: controller);
    final schedule = ScheduleLocationViewModel(controller: controller);
    expect(loads, 1);
    expect(identical(goal.draft, about.draft), isTrue);
    expect(identical(about.draft, schedule.draft), isTrue);
    await goal.selectGoal(WorkingTowardGoal.buildMuscle);
    await goal.continueToNextStep();
    about.setName('Elena Smith');
    about.setImperial(false);
    about.setWeight(66.5);
    await about.continueToNextStep();
    expect(controller.draft.name, 'Elena Smith');
    expect(controller.draft.weightKg, 66.5);
    expect(controller.draft.countryCode, 'DK');

    await tester.pumpWidget(
        MaterialApp(home: GoalSelectionView(controller: controller)));
    await tester.pumpAndSettle();
    final action =
        tester.widget<LiquidChromeButton>(find.byType(LiquidChromeButton));
    await tester.tap(find.text('Continue'));
    // A second queued tap cannot open another route.
    action.onPressed!();
    await tester.pump();
    // The shared action paints its busy state before starting navigation.
    await tester.pump();
    var goalScaffold = tester.widget<OnboardingScaffold>(find.descendant(
        of: find.byType(GoalSelectionView, skipOffstage: false),
        matching: find.byType(OnboardingScaffold, skipOffstage: false),
        skipOffstage: false));
    expect(goalScaffold.loading, isTrue);
    final button = tester.widget<LiquidChromeButton>(find.descendant(
        of: find.byType(GoalSelectionView, skipOffstage: false),
        matching: find.byType(LiquidChromeButton, skipOffstage: false),
        skipOffstage: false));
    expect(button.isLoading, isTrue);
    expect(button.title, 'Continue');
    expect(find.byType(CircularProgressIndicator, skipOffstage: false),
        findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    goalScaffold = tester.widget<OnboardingScaffold>(find.descendant(
        of: find.byType(GoalSelectionView, skipOffstage: false),
        matching: find.byType(OnboardingScaffold, skipOffstage: false),
        skipOffstage: false));
    expect(goalScaffold.loading, isFalse);
    expect(find.byType(AboutYouExperienceView), findsOneWidget);
    expect(write.isCompleted, isFalse);
    Navigator.of(tester.element(find.byType(AboutYouExperienceView))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(GoalSelectionView), findsOneWidget);
    expect(
        tester
            .widget<LiquidChromeButton>(find.byType(LiquidChromeButton))
            .isLoading,
        isFalse);
    write.complete();
    await controller.flush();
    await tester.pumpWidget(const SizedBox());
    goal.dispose();
    about.dispose();
    schedule.dispose();
    controller.dispose();
  });

  testWidgets(
      'Rapid edits coalesce; queued snapshots cannot lose newer answers',
      (tester) async {
    final pending = Completer<void>();
    final saved = <OnboardingDraft>[];
    final controller = OnboardingController(
        load: () async => OnboardingDraft(),
        save: (draft) async {
          saved.add(draft);
          if (saved.length == 1) await pending.future;
        });
    await controller.initialize();
    controller.draft.name = 'First';
    controller.checkpoint();
    controller.draft.name = 'Latest';
    controller.draft.focusMuscles = ['chest'];
    controller.checkpoint();
    await tester.pump(const Duration(milliseconds: 410));
    expect(saved.length, 1);
    expect(saved.first.name, 'Latest');
    controller.draft.name = 'Newest';
    controller.draft.focusMuscles = ['chest', 'biceps'];
    controller.checkpoint();
    await tester.pump(const Duration(milliseconds: 410));
    controller.draft.foodAllergies = ['Peanuts'];
    controller.checkpoint();
    await tester.pump(const Duration(milliseconds: 410));
    expect(saved.length, 1,
        reason: 'Slow storage must not build a queue of obsolete snapshots');
    final flushed = controller.flush();
    pending.complete();
    await flushed;
    expect(saved.length, 2);
    expect(saved.first.focusMuscles, ['chest']);
    expect(saved.last.focusMuscles, ['chest', 'biceps']);
    expect(saved.last.name, 'Newest');
    expect(saved.last.foodAllergies, ['Peanuts']);
    controller.dispose();
  });

  testWidgets(
      'Failed persistence keeps answers and retries before final submission',
      (tester) async {
    var fail = true;
    OnboardingDraft? stored;
    final controller = OnboardingController(
        load: () async => OnboardingDraft(),
        save: (draft) async {
          if (fail) throw StateError('Storage unavailable');
          stored = draft;
        });
    await controller.initialize();
    controller.draft.foodAllergies = ['Peanuts'];
    controller.checkpoint();
    await expectLater(controller.flush(), throwsStateError);
    expect(controller.draft.foodAllergies, ['Peanuts']);
    expect(controller.saveError, isNotNull);
    fail = false;
    await controller.flush();
    expect(stored!.foodAllergies, ['Peanuts']);
    expect(controller.saveError, isNull);
    controller.finish();
    controller.draft.name = 'Must not restore a completed draft';
    controller.checkpoint();
    await controller.flush();
    expect(stored!.name, isNull);
    controller.dispose();
  });

  testWidgets('A new flow restores the latest complete checkpoint',
      (tester) async {
    OnboardingDraft? stored;
    final first = OnboardingController(
        load: () async => OnboardingDraft(),
        save: (draft) async => stored = draft);
    await first.initialize();
    first.draft.name = 'Resume me';
    first.draft.customTrainingSplit = {
      'MONDAY': ['chest', 'legs']
    };
    first.draft.equipmentIds = ['dumbbells'];
    first.draft.completedStep = 7;
    first.checkpoint();
    await first.flush();
    first.dispose();
    final second = OnboardingController(
        load: () async => OnboardingDraft.fromJson(stored!.toJson()));
    await second.initialize();
    expect(second.draft.name, 'Resume me');
    expect(second.draft.customTrainingSplit['MONDAY'], ['chest', 'legs']);
    expect(second.draft.equipmentIds, ['dumbbells']);
    expect(second.draft.completedStep, 7);
    second.dispose();
  });

  testWidgets('Typing and ruler gestures rebuild only their own controls',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = OnboardingController(
        load: () async => OnboardingDraft(name: 'Elena'), save: (_) async {});
    await controller.initialize();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: AboutYouExperienceView(
            controller: controller, collectMeasurements: true)));
    await tester.pumpAndSettle();
    final scaffold =
        tester.widget<OnboardingScaffold>(find.byType(OnboardingScaffold));
    await tester.enterText(find.byType(TextField).first, 'Elena Smith');
    await tester.pump();
    expect(
        identical(
            tester.widget<OnboardingScaffold>(find.byType(OnboardingScaffold)),
            scaffold),
        isTrue);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('biometric-ruler-track')));
    final before =
        tester.widget<OnboardingScaffold>(find.byType(OnboardingScaffold));
    final weight = controller.draft.weightKg;
    await tester.drag(find.byKey(const ValueKey('biometric-ruler-track')),
        const Offset(-80, 0));
    await tester.pumpAndSettle();
    expect(controller.draft.weightKg, isNot(weight));
    expect(
        identical(
            tester.widget<OnboardingScaffold>(find.byType(OnboardingScaffold)),
            before),
        isTrue);
    expect(tester.takeException(), isNull);
    await controller.flush();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
