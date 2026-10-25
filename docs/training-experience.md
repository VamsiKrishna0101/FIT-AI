# Training experience update — 24 October 2026

Discovery is an optional onboarding screen after the authenticated profile gate and before StarterPlanView is mounted. It is never attached to Today. Answer selection requires Continue; Skip works offline. Server completion and the existing per-account local completion key prevent repetition. The existing idempotent acquisition endpoint records the first answer or skip. Survey errors continue to the membership flow, never around SubscriptionGate. Completed/returning members who are not in the starter flow do not see this question.

Today and readiness details now say **Training readiness**. The basis remains **Daily check-in estimate**. The calculation is unchanged: sleep 40%, restedness 20%, energy 20%, inverse soreness 20%, with the existing short-sleep limits. Missing check-ins have no score. No muscle-recovery percentage or physiological measurement is inferred. The Body map's logged training data and strength colours are unchanged.

Exercise details use original graphite anatomy artwork, matching the saved profile's body style. The image is resolved locally and the shared profile cache is account-scoped. Target tags remain canonical; translated labels never determine highlights. Front/back defaults to the view of the primary target. Primary regions are deep red; supporting regions are softer red. Labels list the actual catalogue metadata even when a region has no mapped shape. Unknown regions are not guessed.

The paywall now lists twelve concrete included benefits in the existing charcoal ✓/× table: personalized workouts with sets/reps/load guidance, warm-ups, videos/instructions, routines/custom exercises, logging/history, muscle maps/strength trends, personal records/exercise progress, goal-based nutrition, calories/macros/water logging, readiness/sleep check-ins, measurements, and progress photos/comparisons. The same verified trial/renewal pricing and fixed purchase action remain in place. New copy is translated into all eight supported non-English base languages. No unlimited-use, medical-outcome or guaranteed-results claims were added.

## Artwork and registration

- Generated with the built-in imagegen tool, not a CLI fallback.
- Original retained at `C:/Users/vklvl/.codex/generated_images/01a14fcf-3aff-7982-b422-15a87621c2d8/exec-6311f591-fd96-4fc9-a596-aef23d46493b.png`.
- App asset: `assets/exercise_anatomy/graphite-atlas-v1.png` (1024 × 1536).
- Exact generation prompt: `docs/exercise-anatomy-v1-prompt.txt`.
- Four figures share one atlas. Hand-traced masks in `graphite_anatomy.dart` use the original atlas's coordinates, not the unrelated Body SVG geometry. In-place tinting preserves the render's muscle fibres and shading. Chest/glute clothing is tinted to indicate the underlying anatomical location.
- Highlights describe approximate exercise muscle involvement; they do not measure activation or recovery. Do not replace this atlas without registering and visually verifying every mask again.
- Existing onboarding body assets are preserved.

## Verification

`training_experience_test.dart` captures the real production widgets for male/female front/back anatomy, optional discovery, and readiness. It also checks explicit submission, offline Skip, profile body selection, missing scores, unknown targets, and small-screen large text. Existing onboarding, startup, exercise, Today/date and starter-plan membership tests run alongside it.

Final checks: 78 tests across the training/onboarding/Today/startup/starter suites, plus 15 subscription tests (93 total), all passed. Focused Flutter analysis of the changed code and tests found no issues. The paywall checks cover twelve ✓/× rows, real offer selection, canceled/unverified checkout, expiry, translated narrow/large-text layouts and the fixed purchase action. Preview membership prices are explicit test fixtures, not live offers.
