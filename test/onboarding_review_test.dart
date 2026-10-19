import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';
import 'package:fitai_mobile/features/onboarding/components/onboarding_scaffold.dart';
import 'package:fitai_mobile/features/onboarding/viewmodels/onboarding_controller.dart';
import 'package:fitai_mobile/features/onboarding/views/onboarding_review_view.dart';
import 'package:fitai_mobile/features/onboarding/models/working_toward_goal.dart';

void main() {
  testWidgets('Review requires confirmation again after changing a goal',
      (tester) async {
    final controller = OnboardingController(
      load: () async => OnboardingDraft(
          name: 'Elena',
          gender: 'FEMALE',
          age: 28,
          heightCm: 165,
          weightKg: 65,
          equipmentIds: ['dumbbells']),
      save: (_) async {},
    );
    await controller.initialize();
    await tester.pumpWidget(
        MaterialApp(home: OnboardingReviewView(controller: controller)));
    await tester.pumpAndSettle();
    OnboardingScaffold scaffold() =>
        tester.widget(find.byType(OnboardingScaffold));
    expect(scaffold().onContinue, isNull);
    await tester.scrollUntilVisible(find.byType(CheckboxListTile), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(scaffold().onContinue, isNotNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).at(1));
    await tester.pumpAndSettle();
    expect(controller.draft.workingToward,
        WorkingTowardGoal.values[1].backendValue);
    expect(controller.draft.name, 'Elena');
    expect(controller.draft.equipmentIds, ['dumbbells']);
    expect(scaffold().onContinue, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
