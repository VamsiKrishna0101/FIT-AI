import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/ds_motion.dart';
import '../models/workout_exercise_models.dart';

/// Posters share the demo's white canvas, keeping wide and square source
/// frames complete without dark letterboxing or cropping the demonstrator.
class ExerciseThumbnail extends StatelessWidget {
  final WorkoutExerciseModel exercise;
  final double size;
  const ExerciseThumbnail({super.key, required this.exercise, this.size = 62});

  @override
  Widget build(BuildContext context) {
    final url = exercise.thumbnailUrl?.trim() ?? '';
    const fallback = ColoredBox(
        color: Color(0xFF2A2A2A),
        child: Center(
            child: Icon(CupertinoIcons.person,
                color: Color(0xFF969696), size: 26)));
    return RepaintBoundary(
        child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
                width: size,
                height: size,
                child: url.isEmpty
                    ? fallback
                    : ColoredBox(
                        color: Colors.white,
                        child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            memCacheWidth:
                                (size * MediaQuery.devicePixelRatioOf(context))
                                    .ceil(),
                            fadeInDuration:
                                DSMotion.duration(context, DSMotion.regular),
                            fadeOutDuration:
                                DSMotion.duration(context, DSMotion.regular),
                            fadeInCurve: DSMotion.effects,
                            fadeOutCurve: DSMotion.effects,
                            placeholder: (_, __) => fallback,
                            errorWidget: (_, __, ___) => fallback)))));
  }
}
