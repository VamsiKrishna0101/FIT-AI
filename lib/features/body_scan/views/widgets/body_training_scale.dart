import 'package:flutter/material.dart';

class BodyTrainingBand {
  final int first;
  final int? last;
  final Color color;
  const BodyTrainingBand(this.first, this.last, this.color);
}

const bodyTrainingLow = Color(0xFF8DAEC6);
const bodyTrainingMedium = Color(0xFFB3A2CE);
const bodyTrainingHigh = Color(0xFFD3B18B);

/// Stable count ranges across every date filter. Zero remains uncolored.
List<BodyTrainingBand> bodyTrainingBands() => const [
      BodyTrainingBand(1, 7, bodyTrainingLow),
      BodyTrainingBand(8, 14, bodyTrainingMedium),
      BodyTrainingBand(15, null, bodyTrainingHigh),
    ];

Color bodyTrainingColor(
        int count, List<BodyTrainingBand> bands, Color neutral) =>
    count <= 0 || bands.isEmpty
        ? neutral
        : bands
            .firstWhere((band) => band.last == null || count <= band.last!)
            .color;
