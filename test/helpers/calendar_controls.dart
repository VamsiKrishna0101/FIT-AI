import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> selectCalendarOption(
    WidgetTester tester, String key, String label) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  final menu = find.byType(Scrollable).last;
  final option = find.descendant(of: menu, matching: find.text(label));
  if (option.evaluate().isEmpty) {
    tester.state<ScrollableState>(menu).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(option, 120,
        scrollable: menu, maxScrolls: 60);
  }
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}
