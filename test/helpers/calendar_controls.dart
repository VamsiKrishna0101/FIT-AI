import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/components/app_date_filter.dart';

AppFilterDropdown<T> calendarDropdown<T>(WidgetTester tester, String key) =>
    tester.widget<AppFilterDropdown<T>>(find.byWidgetPredicate((widget) =>
        widget is AppFilterDropdown<T> && widget.dropdownKey == ValueKey(key)));

Future<void> selectCalendarOption(
    WidgetTester tester, String key, String label) async {
  final prefix = key.replaceAll('-filter', '');
  final pill = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('$prefix-pill-')),
  );
  if (pill.evaluate().isNotEmpty) {
    await tester.ensureVisible(pill.first);
    await tester.pumpAndSettle();
    await tester.tap(pill.first);
    await tester.pumpAndSettle();
    return;
  }
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
  // Checked popup items own taps through their enclosing menu item.
  final entry = find.ancestor(
      of: option,
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem));
  final target = entry.evaluate().isEmpty ? option : entry.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
