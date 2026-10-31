import 'dart:async';
import 'package:setcraft/features/nutrition/components/liquid_water_visual.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Layout/data tests settle finite transitions. The ambient-wave test opts in
  // and advances frames explicitly to verify the production loop and pauses.
  LiquidMotion.ambientEnabled = false;
  await testMain();
}
