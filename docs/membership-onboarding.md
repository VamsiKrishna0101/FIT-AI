# Onboarding and membership redesign — 2026-10-24

The welcome page introduces the product with original gym photography and three short animated lines: Build muscle, Get stronger, Stay consistent. The native Flutter entrance takes 1.2 seconds, runs once and shows its final state immediately with reduced motion. Get started remains available during it. There is no trial pitch or plan generation on entry. Sign-in and account creation use the same black, charcoal and silver theme. Name and country share one profile page; usual activity and sleep share one lifestyle page. Age, height, current/target weight, experience, training frequency/duration/location, equipment, muscle priorities, actual training weekdays, limitations and nutrition inputs are preserved. Selected muscles still turn red, and the body selector uses the existing original male/female anatomical artwork.

There are no visible numeric step counts. The progress line reflects substeps. All question pages scroll above a reachable primary action. Sign-in validation errors appear above that action, including when the keyboard is open. Existing email/password and verified-email OTP behavior is retained. Apple/Google sign-in availability remains explicitly labelled coming soon; no fake provider login action is exposed.

The real starter plan is previewed before the membership decision. Its activation waits for verified access; closing checkout returns to the preview. The paywall combines store pricing, annual/monthly choices, an honest 14-day trial timeline and a fixed purchase action. The feature comparison uses muted × marks and silver ✓ marks with a charcoal Setcraft column. Its labels explain that the same features are included in the trial and paid subscription; it does not advertise a free tier. Account/privacy/sign-out and restore links remain available.

## Plan reveal

The final question action remains Build my plan. The reveal leads with the saved goal and account name, compact experience/equipment metadata, graphite front/back anatomy and selected muscle highlights. It uses a short week strip with the server's actual dates and read-only day selection. The first-workout card uses only its actual public samples and prescriptions. Other public samples belong under From your week. There are no generic explanatory paragraphs or duplicated profile chips. Rules-based generation retains its collapsed disclosure.

The public preview contract still limits exposed exercises; no private plan payload is fetched to decorate the reveal. Saved profile responses are owner-checked before display. The fixed Unlock my plan action opens membership, where all billing terms remain visible. Verified activation opens the full saved plan. Its first-workout action starts a session only for today (or resumes a started session), and future dates offer View my first workout. Viewing or purchasing never starts a workout automatically.

## Body focus selection

The focus page reuses the exact `male-front.png` / `female-front.png` artwork from gender selection. A shared asset resolver keeps the two screens aligned. The original PNGs stay untouched: the focus painter desaturates the base and restores the original red muscle texture only within registered selected masks. Covered chest/glute regions get a restrained tint over opaque clothing. The hand-registered masks and inverse hit transform share the same source coordinates, so tapping the body selects the canonical muscle ID shown by the chips.

One figure is shown at a time, with Front/Back controls above it. Rear views reuse the app's existing `graphite-atlas-v1.png` and its registered masks. Posterior-only selections open Back automatically; there are no hamstring or calf highlights painted over the front thighs or shins. Multiple priorities, the existing empty-list Full body representation, persisted preferences and reduced-motion behavior are preserved. The Body tab's training/strength maps are unaffected.

`onboarding_focus_body_test.dart` checks both body styles, asset identity, immediate reduced-motion selection, animation, chip/body synchronization, posterior switching, Full body, larger text and a fixed reachable Continue action. It also captures every front/back mask for visual registration review under `build/previews/focus-masks-*.png`. These are exercise focus illustrations, not activation measurements.

The following Training style step uses short display labels, compact day/muscle rows and a collapsed alternatives selector. Flexible schedules use Day 1/2/3 labels instead of implying chosen weekdays. Custom schedules show each editable day once. The recommendation algorithm and canonical split IDs are unchanged.

Final details shows two collapsed sections, Movement notes and Food preferences, even when values already exist. Add/Edit actions expose the existing inputs; no profile fields were removed. Food validation automatically reopens the relevant section while preserving its text. Required billing and membership disclosures are unaffected. `onboarding_finishing_polish_test.dart` captures both steps, exercises edits/invalid-budget recovery and confirms narrow large-text layouts.

The old client dismissal and new cardless trial grant were removed. A valid unexpired server snapshot is required for access, with expiry/API checks covering already-open detail routes. Legacy trials keep their actual expiry. New billing uses Google Play or App Store verification. See `../../backend/modules/subscription/README.md` for required store configuration and release testing. Neither native store nor subscription legal URLs are configured locally as of this change, so real checkout remains unavailable until setup is complete.

## Preview artifacts

Generated by tests using production widgets, under `build/previews/` and `build/onboarding-redesign/`:

- `membership-example-offer.png`: example offer, real layout.
- `membership-trial-timeline.png`: trial explanation and the start of the feature comparison.
- `membership-feature-comparison.png`: feature comparison.
- `signin-redesigned.png` and `signup-redesigned.png`.
- `welcome-get-started.png`, `personal-plan-reveal.png`, and `personal-plan-workout-preview.png`.
- `../onboarding-redesign/welcome.png`, `body-selection.png`, `measurements.png`, `focus.png`.

**The €99.99/year and €12.99/month values in preview tests are explicit fixtures, not live purchase prices.** Production prices and eligibility come from native stores. Primary membership disclosures and welcome copy have translations for de/fr/sv/no/da/nl/es/it; en is the source and de-CH uses the German language-family copy. Store-provided currency strings stay untouched. The new phrase-table test checks locale completeness and preservation of billing placeholders.

## Original hero asset

- File: `assets/branding/setcraft-training-hero-v1.png`, 1536 × 1024.
- Method: built-in imagegen tool; no external generator CLI or API key used.
- Source result retained at `C:/Users/vklvl/.codex/generated_images/01a14fcf-3aff-7982-b422-15a87621c2d8/exec-21a47fea-5169-402a-a738-60e15257fe25.png`.
- Generation direction: original premium editorial fitness photograph, adult woman on the left performing a dumbbell curl and adult man on the right at a cable station; dark contemporary gym, charcoal and black athletic clothing, restrained chrome light, realistic anatomy, cinematic contrast, no text, logos or watermarks. Compose both athletes for a wide mobile onboarding/paywall hero with room for a black fade at the bottom. This records the creative brief, rather than claiming a verbatim generation log.
- Display: bundled local asset with a code-native black gradient. No network media dependency or repeating decorative animation.

## Checks

Relevant suites cover server-time expiry, no dashboard bypass, canceled/pending/unverified checkout, correct renewal-phase price, exact trial duration, purchase ownership, preview-to-activation, onboarding input preservation, muscle selection, name validation, OTP input, rulers, optional health ordering, sign-in errors/keyboard, narrow phones and enlarged text. Screenshot fixtures are separate from production offer handling. Store end-to-end purchase testing remains a release prerequisite.

## Final sign-in and cleanup

After authentication, sign-in now remains visible with Signing in on the button
while profile, starter-plan, survey and membership routing is prepared. The plan
and membership requests run concurrently after profile verification. Prepared
results are passed into the destination gates so they do not repeat their entry
requests or paint the launch logo. Missing profiles still open setup; expired
memberships still open the blocking paywall. The signed-in onboarding completion
path uses the same handoff. Cold app launch retains its existing launch screen.

Membership preparations are tied to both the account and secure-session revision;
sign-out, replacement credentials or a changed access snapshot invalidate them.
Expiry and the subscription gate's timer/API/lifecycle protections remain active.
Failures stay on sign-in with a retryable error. Transition tests inspect frames
for the absence of the launch screen, and cover missing profiles, optional survey,
membership expiry, failure/retry and account switches.

Retries reuse the successfully authenticated session while the inputs and account
are unchanged. This also applies after OTP registration, so an entry-check error
does not send another OTP or create the account twice. Edited credentials require
authentication again; a rejected session also forces fresh authentication while
retaining the new-account handoff. Form inputs stay read-only during submission.

Sign-in now has a pure black canvas, a vector brand mark, a short heading,
charcoal Apple/Google controls and a silver email action. It has no background
photograph, video, blur or repeating decoration. Get started no longer displays
Membership required. Provider cancellation and keyboard/large-text layout have
regression coverage. See `social-sign-in.md` for the prepared default-off native
provider integration, server verification, rate limit and configuration steps.

Cleanup removed 449 files (43,913,892 bytes) from obsolete generated logs,
screenshots, UI dumps, thumbnail/planner/Python caches and three unused bundled
photos. The generic `widget_test.dart` template smoke test was also removed;
the real startup, auth, onboarding and other feature regression tests remain.
The checked-path cleanup script is `../../scripts/cleanup_generated_artifacts.ps1`;
its applied manifest is `build/auth-refresh-cleanup.csv`. Signing files, models,
runtime dependencies, source data, media fixtures and migration backups were
preserved. No cloud storage or database records were deleted.


## Compact paywall and catalogue availability

The paywall uses the bundled gym hero, an overlaid close control when opened from
the plan preview, one headline, a compact trial timeline and a fixed purchase
action. The logo/account header and long feature descriptions were removed.
Four feature comparisons expand under This is included; billing choices remain
available. Privacy/data controls and sign-out are under More options in the footer.
The charge, renewal period, cancellation and restore links remain visible.
Free-trial copy and the localized zero-price action require a verified eligible
store offer. The timeline does not promise an unconfigured reminder.

Membership catalogue requests now share an in-flight load within the same secure
session. Store setup pending, unsupported platform, unavailable store, missing
products and connection errors have distinct states. A temporary store failure
retains the last confirmed displayed price while checkout stays unavailable until
refresh succeeds. A delayed verified purchase resumes the requested plan once.

The local backend checked on 2026-10-26 has no Google Play verification credentials,
Apple server verification configuration or subscription Terms/Privacy URLs. These
operator settings and live store products are still required for real checkout;
the app does not substitute draft country prices or grant access without verification.

The onboarding preview now uses compact week rows, two exercise samples and a
short unlock prompt. Equipment lists, duplicate session metadata and technical
planner explanations were removed. The star loader has continuous orbits and
shimmer at an unchanged confirmed percentage, with a gentle reduced-motion mode.
