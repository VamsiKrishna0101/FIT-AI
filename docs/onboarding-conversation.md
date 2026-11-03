# Setcraft onboarding

The question, equipment, training preferences, and account layouts use the original Setcraft presentation saved in mobile commit 79ee1eb, before the Fitbod conversation redesign. Centered headings, full-width selection cards, a visible progress bar, and explicit Continue actions are restored. No typing animation or chat-style answer bubbles are used in this journey.

The route sequence is goal; profile (name, gender, age, experience); schedule (frequency, duration, location); equipment; lifestyle (activity, sleep, nutrition, limitations); training preferences (muscle focus, weekdays, split, optional notes); authentication. All routes share the existing draft controller and retain back navigation and save/retry behavior.

Body measurements remain optional during initial onboarding. The original biometric ruler editor is available explicitly through AboutYouExperienceView(collectMeasurements: true); the default setup asks only for a valid age from 13 to 100 and does not save default height, weight, or target weight.

The current video welcome screen is retained, including its short headline, Get started, Log in, and local muted background video with no poster-image layer. The clip remains a temporary reference asset until original footage is ready.

The current generated-plan preview and separate subscription screen are retained, including exercise images/details, Unlock full plan, the blue Day 1 / Day 12 / Day 14 timeline, store-provided prices, purchase verification, and Restore purchases. Backend plan generation and payment logic are not rolled back.

Regression coverage includes the complete restored journey through account creation, answer retention, age validation without measurements, original equipment categories and profile save retry, custom splits, narrow translated layouts, welcome video, and the existing plan/payment suites.
