// Renders Mochi to PNG for push notifications.
// Run: flutter test tool/render_mochi_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:setcraft/features/onboarding/components/coach_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render Mochi notification artwork', (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(512, 512);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 512,
              height: 512,
              child: ColoredBox(
                color: Color(0xFF111114),
                child: Center(
                    child: CoachMascot(size: 360, mood: CoachMood.cheer)),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final png = bytes!.buffer.asUint8List();
      // iPhone: bundled in the notification service extension.
      File('ios/SetcraftNotificationService/mochi-coach.png')
          .writeAsBytesSync(png);
      // Android: served by the backend as the notification picture.
      File('../backend/assets/branding/mochi-coach.json')
          .writeAsStringSync(jsonEncode({'base64': base64Encode(png)}));
    });
    await tester.pumpWidget(const SizedBox());
  });
}
