Training setup and preparation
==============================

The user chooses a goal and training style independently of experience. AUTO
recommends a starting split from available days, session time, environment,
experience and goal. Explicit/custom choices are preserved and validated for
equipment and session time. The onboarding muscle preview is illustrative;
the server finalises exercises, accessory coverage and working sets.

Focus areas have no three-muscle limit. Any unique valid muscle IDs can be
selected. Full body clears extra priorities (an empty focus list) and displays
balanced attention across all muscles. This does not change the training split.

Beginners with at least three sessions of 30 minutes and suitable equipment
are recommended muscle-focused days. With fewer available days, supporting
muscles are shown explicitly instead of leaving major areas out. Dedicated
focus days select complementary exercises when time, catalogue and recorded
volume permit; they are not treated as full-body days just because assisting
muscles are present. Small set budgets are shared across complementary moves.

GET_STRONGER is a real stored goal. LOSE_WEIGHT remains readable for existing
accounts but new onboarding presents one fat-loss option. Existing accounts,
exercise IDs, logged sets and completed plans are not rewritten.

Preparation is generated deterministically from the first working exercise,
with five minutes reserved inside the session budget. It is saved separately
on the workout, copied to the session snapshot and shown before working sets.
It is not a UserWorkoutItem or WorkoutSetLog and cannot affect training volume
or strength ranks. Existing saved plans without preparation remain readable.

The beginner eligibility correction is a narrow allowlist for stable exercises
with imported INTERMEDIATE labels. It is not a complete professional audit of
the catalogue. Advanced/high-skill and equipment gates remain in effect.

Nutrition uses a shared starting estimate across Home and weekly planning.
Fat loss uses 15% of estimated maintenance capped at 450 kcal, with product
floors of 1400/1600 kcal for female/male estimates. These are conservative
product rules, not personalised clinical thresholds. Meal planning can decline
unsupported profiles. Device active calories alone do not replace total daily
expenditure or silently change the target. Review instructions require weight,
intake, performance and recovery trends; calories are not automatically changed
from a single weigh-in or missing logs.

Validation:
- backend/scripts/test_planner_coaching.ts: fictional-profile matrix, JSON
  round-trip validation, custom beginner schedules, strength reps, preparation
  tampering, nutrition goals and model-outage fallback.
- backend/scripts/test_training_preparation.ts: isolated temporary account;
  workout/session persistence, zero working-set logs and edited-load handling.
- mobile/test/onboarding_training_style_test.dart: plain-language choices,
  accessibility, direct final-step navigation and informational preparation.
