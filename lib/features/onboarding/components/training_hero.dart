import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';

/// One bundled, original image. No network request or repeating animation.
class TrainingHero extends StatelessWidget {
  final double height;
  final String? caption;
  final double radius;
  const TrainingHero(
      {super.key, this.height = 200, this.caption, this.radius = 0});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
              height: height,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset('assets/branding/setcraft-training-hero-v1.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -.35),
                    cacheWidth: (MediaQuery.sizeOf(context).width *
                            MediaQuery.devicePixelRatioOf(context))
                        .ceil()
                        .clamp(400, 1500)),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                      Color(0x22000000),
                      Color(0x08000000),
                      Colors.black
                    ],
                            stops: [
                      0,
                      .55,
                      1
                    ]))),
                if (caption != null)
                  Positioned(
                      left: 24,
                      right: 24,
                      bottom: 18,
                      child: FitnessText(caption!,
                          style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFCECECE)))),
              ]))));
}

class OnboardingContextNote extends StatelessWidget {
  final String title, detail;
  const OnboardingContextNote(
      {super.key, required this.title, required this.detail});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF303030))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        FitnessText(detail,
            style: const TextStyle(
                fontSize: 12, height: 1.5, color: Color(0xFFA8A8A8))),
      ]));
}
