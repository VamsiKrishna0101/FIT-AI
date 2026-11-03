# Setcraft onboarding conversation

The entry uses a local, muted, looping reference video: assets/branding/setcraft-welcome-reference.mp4. It has no poster-image layer. Startup prepares the first frame before opening the unauthenticated entry; failed initialization leaves a black canvas with usable controls. Playback pauses off-route and in the background. Reduced motion does not autoplay the video.

The entry has a lower wordmark, a short two-line headline, Get started and Log in. Question and account headers use the SETCRAFT text wordmark without the circular mark. The equipment catalogue has its own title and close/back control.

The shared question shell uses monochrome, content-sized reply pills without outlined borders or a previous-answer badge. Its question and essential supporting text reveal at 32 ms per character, bounded to 1–2 seconds, in a fixed layout; answer controls appear together afterward. Reduced motion shows everything immediately. Screen readers receive complete sentences. Repeated introductory lines were removed; only the first goal question keeps an introductory line. Presentation copy omits sentence-ending periods.

OnboardingJourney reuses the existing controllers and specialist controls in this order: goal; experience; location; equipment; frequency/duration; weekdays/training style; profile; muscle focus; activity/sleep/nutrition/limitations; optional final details; authentication. Single choices advance once after selection feedback. Multi-select, profile, equipment and custom-plan screens use the protected Continue action. Existing profile-edit routes remain available.

Equipment uses full-width image rows with square checkbox selection, grouped sections, a pinned search field and Done action. Search covers translated names, English names and equipment IDs. Precise selections and the exclusive bodyweight default use the existing model; weight increment editing is not offered because it is not supported by that model.

Coached measurements use four aligned, tap-to-edit rows and a compact metric/imperial switch. Each value opens a single unboxed ruler in a bottom sheet. Editing uses the existing measurement bounds and storage units; changing display units does not rewrite saved measurements.

The coached training split screen uses the shared reply bubbles for three initial choices, with other styles and the weekly schedule available on demand. Custom split editing remains available.

No backend field names or authentication requests were changed. New copy uses the existing localization layer, including eight non-English language families. Custom training splits, budget validation, shared drafts, back navigation and authentication retry behavior are retained.

Validation: All 67 checks passed across the onboarding conversation, equipment, training-style, redesign, continue, finishing-polish, controller, authentication and plan-reveal regression suites. The conversation suite renders the full path through registration without creating a live account. Equipment checks cover search, hidden selections, profile-save retry and narrow translated layouts with the keyboard open.

The bundled Fitbod clip is a temporary reference requested for this iteration; replace this asset when original background footage is ready.

Android delivery: ARM64 debug APK built successfully. Its Dart kernel was checked for the final body-stats screen, measurement rows and equipment search. The final measurements/conversation/profile recheck passed all 19 checks, and Flutter analysis reported no issues. Installation on device 3b7098b5829d was canceled with INSTALL_FAILED_USER_RESTRICTED, so the new APK was not installed.
