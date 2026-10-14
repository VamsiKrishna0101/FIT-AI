# FitAI motion

The motion pass uses short, purposeful feedback with the existing black/charcoal style.
Shared decisions live in `core/theme/ds_motion.dart`; reusable behaviour lives in
`core/components/motion.dart`. No new animation dependency is needed.

Research before implementation:
- Google: https://m3.material.io/styles/motion/overview/how-it-works
  Spatial motion can use springs; opacity/colour should not overshoot. Google does
  not currently provide this complete native M3 physics scheme for Flutter.
- Apple: https://developer.apple.com/videos/play/wwdc2023/10157/
  Interactive motion should be interruptible and follow the user's interaction.
- Reduce Motion: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/
  Stop decorative motion and preserve meaningful feedback through static states.
- Flutter: https://docs.flutter.dev/perf/best-practices
  Rebuild only animated regions, reuse children, avoid unnecessary opacity/layer work.
- Flutter spring implementation: https://docs.flutter.dev/cookbook/animation/physics-simulation

Our timings are product choices, not requirements copied from those sources:
120 ms press fallback, 220 ms selection, 260 ms feedback, 340 ms content entry,
560 ms graph reveal. Presses use a damped spring. Chart drawing and text changes
never overshoot. Labels report exact saved values throughout an animation.

Apply entry motion to short sections, not every row of a large lazy list. Keep keys
stable on cache refresh; replay graph motion only when dates/values actually change.
No asynchronous save waits for an animation. Success feedback follows acknowledgement.
Do not animate text fields or replace their controllers while users type.
Respect Reduce Motion, TickerMode and application lifecycle. Avoid infinite decoration.

Verification includes chart endpoints/gaps, rapid retargeting, reduced motion, form
focus/typing, one save per tap, navigation state retention and existing screen tests.
Physical Android/iOS frame pacing still requires a profile build on a device; widget
tests and analyzer results do not establish a device frame-rate guarantee.
