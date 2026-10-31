import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/features/onboarding/models/lifestyle_nutrition_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingDraft Lifestyle & Nutrition Serialization', () {
    test('serializes and deserializes standard options correctly', () {
      final draft = OnboardingDraft(
        activityLevel: 'MODERATE',
        sleepDuration: 'HOURS_7_TO_8',
        eatingStyle: 'VEGAN',
        weeklyFoodBudget: 'BUDGET_100',
        limitations: ['KNEE', 'BACK'],
        completedStep: 5,
      );

      final json = draft.toJson();
      expect(json['activityLevel'], 'MODERATE');
      expect(json['sleepDuration'], 'HOURS_7_TO_8');
      expect(json['eatingStyle'], 'VEGAN');
      expect(json['weeklyFoodBudget'], 'BUDGET_100');
      expect(json['limitations'], ['KNEE', 'BACK']);
      expect(json['completedStep'], 5);

      final restored = OnboardingDraft.fromJson(json);
      expect(restored.activityLevel, 'MODERATE');
      expect(restored.sleepDuration, 'HOURS_7_TO_8');
      expect(restored.eatingStyle, 'VEGAN');
      expect(restored.weeklyFoodBudget, 'BUDGET_100');
      expect(restored.limitations, ['KNEE', 'BACK']);
      expect(restored.completedStep, 5);
    });

    test('serializes and deserializes custom inputs correctly', () {
      final draft = OnboardingDraft(
        activityLevel: 'HIGH',
        sleepDuration: 'LESS_THAN_6_HOURS',
        eatingStyle: 'OTHER',
        customEatingStyle: 'Pescatarian / Mediterranean',
        weeklyFoodBudget: 'BUDGET_150',
        customWeeklyFoodBudget: 175.0,
        limitations: ['SHOULDER', 'OTHER'],
        customLimitations: 'Right rotator cuff impingement; avoid behind-neck presses',
        completedStep: 5,
      );

      final json = draft.toJson();
      expect(json['eatingStyle'], 'OTHER');
      expect(json['customEatingStyle'], 'Pescatarian / Mediterranean');
      expect(json['weeklyFoodBudget'], 'BUDGET_150');
      expect(json['customWeeklyFoodBudget'], 175.0);
      expect(json['limitations'], ['SHOULDER', 'OTHER']);
      expect(json['customLimitations'], 'Right rotator cuff impingement; avoid behind-neck presses');

      final restored = OnboardingDraft.fromJson(json);
      expect(restored.customEatingStyle, 'Pescatarian / Mediterranean');
      expect(restored.customWeeklyFoodBudget, 175.0);
      expect(restored.limitations, ['SHOULDER', 'OTHER']);
      expect(restored.customLimitations, 'Right rotator cuff impingement; avoid behind-neck presses');
    });

    test('handles fallback defaults gracefully when fields are missing', () {
      final minimalJson = <String, dynamic>{
        'languageCode': 'de',
        'countryCode': 'DE',
      };

      final restored = OnboardingDraft.fromJson(minimalJson);
      expect(restored.languageCode, 'de');
      expect(restored.activityLevel, isNull);
      expect(restored.sleepDuration, isNull);
      expect(restored.eatingStyle, isNull);
      expect(restored.customEatingStyle, isNull);
      expect(restored.weeklyFoodBudget, isNull);
      expect(restored.customWeeklyFoodBudget, isNull);
      expect(restored.limitations, ['NONE']);
      expect(restored.customLimitations, isNull);
    });
  });

  group('Lifestyle & Nutrition Domain Models Mapping', () {
    test('ActivityLevelOption maps correctly', () {
      expect(ActivityLevelOption.fromBackend('LOW'), ActivityLevelOption.low);
      expect(ActivityLevelOption.fromBackend('MODERATE'), ActivityLevelOption.moderate);
      expect(ActivityLevelOption.fromBackend('HIGH'), ActivityLevelOption.high);
      expect(ActivityLevelOption.fromBackend(null), ActivityLevelOption.moderate);
    });

    test('SleepDurationOption maps correctly', () {
      expect(SleepDurationOption.fromBackend('LESS_THAN_6_HOURS'), SleepDurationOption.lessThan6);
      expect(SleepDurationOption.fromBackend('HOURS_6_TO_7'), SleepDurationOption.hours6To7);
      expect(SleepDurationOption.fromBackend('HOURS_7_TO_8'), SleepDurationOption.hours7To8);
      expect(SleepDurationOption.fromBackend('HOURS_8_PLUS'), SleepDurationOption.hours8Plus);
      expect(SleepDurationOption.fromBackend(null), SleepDurationOption.hours7To8);
    });

    test('EatingStyleOption maps correctly', () {
      expect(EatingStyleOption.fromBackend('NO_PREFERENCE'), EatingStyleOption.noPreference);
      expect(EatingStyleOption.fromBackend('VEGETARIAN'), EatingStyleOption.vegetarian);
      expect(EatingStyleOption.fromBackend('VEGAN'), EatingStyleOption.vegan);
      expect(EatingStyleOption.fromBackend('OTHER'), EatingStyleOption.other);
      expect(EatingStyleOption.fromBackend(null), EatingStyleOption.noPreference);
    });

    test('WeeklyFoodBudgetOption maps and finds closest bracket', () {
      expect(WeeklyFoodBudgetOption.fromBackend('BUDGET_50'), WeeklyFoodBudgetOption.budget50);
      expect(WeeklyFoodBudgetOption.fromBackend('BUDGET_75'), WeeklyFoodBudgetOption.budget75);
      expect(WeeklyFoodBudgetOption.fromBackend('BUDGET_100'), WeeklyFoodBudgetOption.budget100);
      expect(WeeklyFoodBudgetOption.fromBackend('BUDGET_150'), WeeklyFoodBudgetOption.budget150);
      expect(WeeklyFoodBudgetOption.fromBackend('BUDGET_200_PLUS'), WeeklyFoodBudgetOption.budget200Plus);

      // Closest matching
      expect(WeeklyFoodBudgetOption.closestFromAmount(40), WeeklyFoodBudgetOption.budget50);
      expect(WeeklyFoodBudgetOption.closestFromAmount(65), WeeklyFoodBudgetOption.budget75);
      expect(WeeklyFoodBudgetOption.closestFromAmount(88), WeeklyFoodBudgetOption.budget100);
      expect(WeeklyFoodBudgetOption.closestFromAmount(130), WeeklyFoodBudgetOption.budget150);
      expect(WeeklyFoodBudgetOption.closestFromAmount(280), WeeklyFoodBudgetOption.budget200Plus);
    });

    test('BodyLimitationOption maps correctly and handles exclusivity', () {
      expect(BodyLimitationOption.fromBackend('NONE'), BodyLimitationOption.none);
      expect(BodyLimitationOption.fromBackend('SHOULDER'), BodyLimitationOption.shoulder);
      expect(BodyLimitationOption.fromBackend('KNEE'), BodyLimitationOption.knee);
      expect(BodyLimitationOption.fromBackend('BACK'), BodyLimitationOption.back);
      expect(BodyLimitationOption.fromBackend('WRIST'), BodyLimitationOption.wrist);
      expect(BodyLimitationOption.fromBackend('HIP'), BodyLimitationOption.hip);
      expect(BodyLimitationOption.fromBackend('OTHER'), BodyLimitationOption.other);
      expect(BodyLimitationOption.fromBackend(null), BodyLimitationOption.none);

      expect(BodyLimitationOption.none.isExclusive, isTrue);
      expect(BodyLimitationOption.shoulder.isExclusive, isFalse);
      expect(BodyLimitationOption.other.isCustom, isTrue);
    });
  });

  group('Multilingual AI Summary & Localization', () {
    test('renders English dynamic summary correctly with limitations', () {
      final summary = AppLanguage.uk.lifestyleAiSummary(
        'Moderate',
        '7–8 hrs',
        'Vegan',
        ['Knee', 'Back'],
      );
      expect(summary, contains('Moderate Activity'));
      expect(summary, contains('7–8 hrs Sleep'));
      expect(summary, contains('Vegan Plan'));
      expect(summary, contains('Knee, Back Protection Shield'));
    });

    test('renders empty limitations as Full Joint Mobility in summary', () {
      final summary = AppLanguage.uk.lifestyleAiSummary(
        'High',
        '8+ hrs',
        'No preference',
        ['None'],
      );
      expect(summary, contains('High Activity'));
      expect(summary, contains('Full Joint Mobility'));
    });

    test('verifies custom diet placeholders exist across languages', () {
      expect(AppLanguage.uk.customDietPlaceholder, contains('Keto'));
      expect(AppLanguage.germany.customDietPlaceholder, contains('Keto'));
      expect(AppLanguage.france.customDietPlaceholder, contains('Céto'));
      expect(AppLanguage.spain.customDietPlaceholder, contains('Keto'));
      expect(AppLanguage.italy.customDietPlaceholder, contains('Cheto'));
    });
  });
}
