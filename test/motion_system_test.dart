import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/components/motion.dart';
import 'package:fitai_mobile/core/theme/ds_motion.dart';
import 'package:fitai_mobile/features/progress/components/progress_chart.dart';
import 'package:fitai_mobile/features/progress/models/progress_models.dart';

Widget app(Widget child, {bool reduced = false}) => MaterialApp(
      home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
              body: Center(child: SizedBox(width: 300, child: child)))),
    );

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
  });
  test('staggered bars stay in range and end at their real height', () {
    for (var index = 0; index < 12; index++) {
      expect(DSMotion.barProgress(0, index, 12), 0);
      expect(DSMotion.barProgress(1, index, 12), 1);
      for (var frame = 0; frame <= 60; frame++) {
        expect(DSMotion.barProgress(frame / 60, index, 12),
            inInclusiveRange(0, 1));
      }
    }
  });

  testWidgets('spring press gives feedback without delaying or repeating a tap',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(app(MotionPress(
        child:
            FilledButton(onPressed: () => taps++, child: const Text('Save')))));
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final transform = tester.widget<Transform>(find
        .descendant(
            of: find.byType(MotionPress), matching: find.byType(Transform))
        .first);
    expect(transform.transform.entry(0, 0), lessThan(1));
    expect(taps, 0);
    await gesture.up();
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reduced motion draws the final graph immediately and disables press movement',
      (tester) async {
    double? value;
    await tester.pumpWidget(app(
        MotionProgress(
            dataKey: 'first',
            builder: (context, progress) {
              value = progress;
              return const Text('Actual data');
            }),
        reduced: true));
    expect(value, 1);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, false);
  });

  testWidgets(
      'identical data refresh does not replay; changed data retargets and settles',
      (tester) async {
    double? value;
    Widget chart(String key) => app(MotionProgress(
        dataKey: key,
        builder: (context, progress) {
          value = progress;
          return const Text('Actual data');
        }));
    await tester.pumpWidget(chart('same'));
    await tester.pumpAndSettle();
    expect(value, 1);
    await tester.pumpWidget(chart('same'));
    expect(value, 1);
    await tester.pumpWidget(chart('new'));
    expect(value, 0);
    await tester.pump(const Duration(milliseconds: 90));
    expect(value, greaterThan(0));
    await tester.pumpWidget(chart('newer'));
    await tester.pumpAndSettle();
    expect(value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entry stops moving when a user starts interacting with a form',
      (tester) async {
    final field = TextEditingController();
    addTearDown(field.dispose);
    await tester
        .pumpWidget(app(MotionEntrance(child: TextField(controller: field))));
    await tester.pump(const Duration(milliseconds: 70));
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '72.5');
    await tester.pumpAndSettle();
    expect(field.text, '72.5');
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden charts schedule no motion frames', (tester) async {
    double? value;
    await tester.pumpWidget(app(TickerMode(
        enabled: false,
        child: MotionProgress(
            dataKey: 'hidden',
            builder: (context, progress) {
              value = progress;
              return const Text('Hidden chart');
            }))));
    await tester.pumpAndSettle();
    expect(value, 1);
    expect(tester.binding.hasScheduledFrame, false);
  });

  testWidgets('chart selection survives an equal-value cache refresh',
      (tester) async {
    List<ProgressPoint> points() => [
          ProgressPoint(DateTime(2026, 10, 10), 12),
          ProgressPoint(DateTime(2026, 10, 11), 20),
          ProgressPoint(DateTime(2026, 10, 13), 8),
        ];
    Widget chart() =>
        app(ProgressChart(points: points(), bars: true, daily: true));
    await tester.pumpWidget(chart());
    await tester.pumpAndSettle();
    final plot = find
        .descendant(
            of: find.byType(ProgressChart), matching: find.byType(CustomPaint))
        .first;
    final box = tester.getRect(plot);
    await tester.tapAt(Offset(box.left + 12, box.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Selected reading'), findsOneWidget);
    await tester.pumpWidget(chart());
    await tester.pumpAndSettle();
    expect(find.text('Selected reading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'bar and line frames settle without changing the reported readings',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boundaryKey = GlobalKey();
    final points = [
      ProgressPoint(DateTime(2026, 10, 9), 12),
      ProgressPoint(DateTime(2026, 10, 10), 18),
      ProgressPoint(DateTime(2026, 10, 11), 10),
      ProgressPoint(DateTime(2026, 10, 13), 22),
      ProgressPoint(DateTime(2026, 10, 14), 16),
    ];
    await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter')),
          home: Scaffold(
              body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Motion preview',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      const Text('Sample readings · exact labels, soft motion',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 24),
                      for (final bars in [true, false]) ...[
                        Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                                color: const Color(0xFF202020),
                                borderRadius: BorderRadius.circular(22)),
                            child: ProgressChart(
                                points: points,
                                bars: bars,
                                daily: true,
                                unit: bars ? 'sets' : 'kg',
                                color: bars
                                    ? Colors.white
                                    : const Color(0xFF6AA9FF),
                                height: 140)),
                        const SizedBox(height: 18),
                      ],
                    ])),
          )),
        )));
    final capture = Platform.environment['FITAI_MOTION_PREVIEW'] == '1';
    for (var frame = 0; frame <= 16; frame++) {
      if (frame > 0) await tester.pump(const Duration(milliseconds: 35));
      if (capture) {
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
                  'build/motion-frame-${frame.toString().padLeft(2, '0')}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await tester.pumpAndSettle();
    expect(find.text('Latest reading'), findsNWidgets(2));
    expect(find.textContaining('null'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
