import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/theme/ds_colors.dart';
import 'package:setcraft/features/wellness/models/check_in_state.dart';
import 'package:setcraft/features/wellness/views/daily_check_in_sheet.dart';
import 'today_check_in_test.dart' show CheckInRepo;

const captureKey = ValueKey('check-in-neutral-preview');
Future<void> neutralPixels(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
    final picture = await boundary.toImage();
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rect = tester.getRect(finder).deflate(3);
    for (var y = rect.top.ceil(); y < rect.bottom.floor(); y += 3) {
      for (var x = rect.left.ceil(); x < rect.right.floor(); x += 3) {
        final offset = (y * picture.width + x) * 4;
        final r = bytes!.getUint8(offset),
            g = bytes.getUint8(offset + 1),
            b = bytes.getUint8(offset + 2);
        expect((r - g).abs(), lessThanOrEqualTo(2));
        expect((r - b).abs(), lessThanOrEqualTo(2));
      }
    }
    picture.dispose();
  });
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  test('Save labels distinguish sleep, partial progress, and completed answers',
      () {
    expect(checkInSaveAction({}), 'Save sleep');
    expect(savedCheckInLabel({'sleepMinutes': 420}), 'Sleep saved');
    expect(checkInSaveAction({'energy': 3}), 'Save progress');
    expect(savedCheckInLabel({'sleepMinutes': 420, 'energy': 3}),
        'Progress saved');
    const complete = {'rested': 3, 'energy': 5, 'soreness': 1};
    expect(checkInSaveAction(complete), 'Save check-in');
    expect(savedCheckInLabel(complete), 'Check-in saved');
    expect(
        hasCheckInAnswers({'rested': 3, 'energy': 5, 'soreness': 0}), isFalse);
  });
  testWidgets('Rest, energy, and soreness stay neutral throughout selection',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              primaryContainer: Colors.blue,
              secondaryContainer: Colors.blue)),
      builder: (_, child) => RepaintBoundary(key: captureKey, child: child!),
      home: Scaffold(
          backgroundColor: DSColors.bg,
          body: DailyCheckInSheet(
              date: DateTime(2026, 10, 28),
              clock: () => DateTime(2026, 10, 28, 10),
              syncedSleepMinutes: 480,
              repository: CheckInRepo())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Save sleep'), findsOneWidget);
    for (final (field, value) in [
      ('rest', 3),
      ('energy', 5),
      ('soreness', 1)
    ]) {
      final option = find.byKey(ValueKey('check-in-$field-$value'));
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(option));
      await tester.pump(const Duration(milliseconds: 30));
      await neutralPixels(tester, option);
      await gesture.up();
      for (final delay in [0, 30, 100, 200]) {
        await tester.pump(Duration(milliseconds: delay));
        await neutralPixels(tester, option);
      }
      expect(tester.widget<Semantics>(option).properties.selected, isTrue);
      if (field == 'rest') expect(find.text('Save progress'), findsOneWidget);
    }
    expect(find.text('Save check-in'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.ensureVisible(find.text('How are you feeling today?'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(captureKey))
          .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/check-in-neutral.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
