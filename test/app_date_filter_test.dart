import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/components/app_date_filter.dart';
import 'helpers/calendar_controls.dart';

final today = DateTime(2026, 11, 4);

Widget host(ValueChanged<AppCalendarSelection> onApply,
        {AppCalendarSelection? selection,
        bool future = false,
        Set<AppCalendarMode>? modes}) =>
    MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: Builder(builder: (context) {
          return Center(child: AppDateFilterButton(onPressed: () {
            showAppCalendarSheet<void>(
                context,
                (_) => AppCalendar(
                    today: today,
                    allowFuture: future,
                    selection: selection ??
                        AppCalendarSelection(
                            mode: AppCalendarMode.day, end: today),
                    modes: modes ??
                        const {
                          AppCalendarMode.day,
                          AppCalendarMode.week,
                          AppCalendarMode.days,
                          AppCalendarMode.range,
                          AppCalendarMode.all,
                        },
                    onApply: (value) {
                      onApply(value);
                      Navigator.pop(context);
                    }));
          }));
        })));

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.tap(find.byType(AppDateFilterButton));
  await tester.pumpAndSettle();
}

void main() {
  test('Selection normalizes, deduplicates, and sorts local calendar days', () {
    final selection = AppCalendarSelection(
        mode: AppCalendarMode.days,
        end: DateTime(2026, 11, 4, 12),
        dates: [today, DateTime(2026, 11, 2, 5), DateTime(2026, 11, 4, 18)]);
    expect(selection.end, today);
    expect(selection.dates, [DateTime(2026, 11, 2), today]);
    expect(() => selection.dates.add(today), throwsUnsupportedError);
  });

  testWidgets('Trigger is one calendar symbol with a 44-point tap target',
      (tester) async {
    await tester.pumpWidget(host((_) {}));
    final button = find.byType(AppDateFilterButton);
    final icons = find.descendant(of: button, matching: find.byType(Icon));
    expect(icons, findsOneWidget);
    expect(tester.widget<Icon>(icons).icon, CupertinoIcons.calendar);
    expect(
        find.descendant(of: button, matching: find.byType(Text)), findsNothing);
    expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(44));
    expect(find.byTooltip('Calendar'), findsOneWidget);
  });

  testWidgets(
      'Exact day stays a draft until Apply and all date shapes are round',
      (tester) async {
    AppCalendarSelection? result;
    await open(tester, host((value) => result = value));
    final filter = find.byKey(const ValueKey('app-calendar-filter'));
    final selectedLabel =
        find.descendant(of: filter, matching: find.text('Single day'));
    final fieldRect = tester.getRect(filter);
    final labelRect = tester.getRect(selectedLabel);
    expect(labelRect.top, greaterThanOrEqualTo(fieldRect.top));
    expect(labelRect.bottom, lessThanOrEqualTo(fieldRect.bottom + 1));
    await tap(tester, 'app-calendar-day-2026-11-02');
    expect(result, isNull);
    for (final mode in ['Week', 'Date range', 'Multiple days', 'Single day']) {
      await selectCalendarOption(tester, 'app-calendar-filter', mode);
      await tap(tester, 'app-calendar-day-2026-11-02');
      final button = tester.widget<TextButton>(
          find.byKey(const ValueKey('app-calendar-day-2026-11-02')));
      expect(button.style!.shape!.resolve({}), isA<CircleBorder>());
    }
    await tap(tester, 'app-calendar-apply');
    expect(result!.mode, AppCalendarMode.day);
    expect(result!.end, DateTime(2026, 11, 2));
    expect(result!.dates, [DateTime(2026, 11, 2)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Closing discards edits and browsing never applies a date',
      (tester) async {
    AppCalendarSelection? result;
    await open(tester, host((value) => result = value));
    await tap(tester, 'app-calendar-day-2026-11-02');
    await selectCalendarOption(tester, 'app-calendar-month-picker', 'October');
    await tap(tester, 'app-calendar-close');
    expect(result, isNull);
    await tester.tap(find.byType(AppDateFilterButton));
    await tester.pumpAndSettle();
    await tap(tester, 'app-calendar-apply');
    expect(result!.end, today);
  });

  testWidgets(
      'Every calendar menu opens below its field with a working scroll cue',
      (tester) async {
    await open(tester, host((_) {}));
    for (final suffix in ['month-picker', 'year-picker']) {
      final field = find.byKey(ValueKey('app-calendar-$suffix'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      final fieldRect = tester.getRect(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      final scrollbar = find.byType(RawScrollbar);
      expect(tester.getTopLeft(scrollbar).dy,
          greaterThanOrEqualTo(fieldRect.bottom + 7));
      expect(tester.getSize(scrollbar).width, closeTo(fieldRect.width, 1));
      expect(tester.widget<RawScrollbar>(scrollbar).thumbVisibility, isTrue);
      final more = find.text('More options');
      expect(more.hitTestable(), findsOneWidget);
      final position =
          tester.state<ScrollableState>(find.byType(Scrollable).last).position;
      final before = position.pixels;
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(before));
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.byIcon(CupertinoIcons.chevron_up), findsOneWidget);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('A screen reader can select a dated button and apply it',
      (tester) async {
    final semantics = tester.ensureSemantics();
    AppCalendarSelection? result;
    await open(tester, host((value) => result = value));
    final node =
        tester.getSemantics(find.bySemanticsLabel('Monday, November 2, 2026'));
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    tester.binding.rootPipelineOwner.visitChildren((owner) {
      owner.semanticsOwner?.performAction(node.id, ui.SemanticsAction.tap);
    });
    await tester.pumpAndSettle();
    await tap(tester, 'app-calendar-apply');
    expect(result!.end, DateTime(2026, 11, 2));
    semantics.dispose();
  });

  testWidgets('History blocks future dates and planning enables them',
      (tester) async {
    await open(tester, host((_) {}));
    TextButton tomorrow() => tester.widget<TextButton>(
        find.byKey(const ValueKey('app-calendar-day-2026-11-05')));
    expect(tomorrow().onPressed, isNull);
    var month = calendarDropdown<int>(tester, 'app-calendar-month-picker');
    expect(
        month.items.singleWhere((item) => item.value == 12).enabled, isFalse);
    await tester.pumpWidget(const SizedBox());
    AppCalendarSelection? result;
    await open(tester, host((value) => result = value, future: true));
    expect(tomorrow().onPressed, isNotNull);
    await tap(tester, 'app-calendar-day-2026-11-05');
    await tap(tester, 'app-calendar-apply');
    expect(result!.end, DateTime(2026, 11, 5));
  });

  testWidgets('Current history week ends today; a planning week ends Sunday',
      (tester) async {
    for (final future in [false, true]) {
      AppCalendarSelection? result;
      await open(tester, host((value) => result = value, future: future));
      await selectCalendarOption(tester, 'app-calendar-filter', 'This week');
      await tap(tester, 'app-calendar-apply');
      expect(result!.start, DateTime(2026, 11, 2));
      expect(result!.end, future ? DateTime(2026, 11, 8) : today);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Reversed range works across years and keeps both endpoints',
      (tester) async {
    AppCalendarSelection? result;
    await open(tester, host((value) => result = value));
    await selectCalendarOption(tester, 'app-calendar-filter', 'Date range');
    await selectCalendarOption(tester, 'app-calendar-month-picker', 'January');
    await tap(tester, 'app-calendar-day-2026-01-04');
    await selectCalendarOption(tester, 'app-calendar-year-picker', '2025');
    await selectCalendarOption(tester, 'app-calendar-month-picker', 'December');
    await tap(tester, 'app-calendar-day-2025-12-29');
    await tap(tester, 'app-calendar-apply');
    expect(result!.start, DateTime(2025, 12, 29));
    expect(result!.end, DateTime(2026, 1, 4));
  });

  testWidgets('Multi-day toggles persist across month and year dropdowns',
      (tester) async {
    AppCalendarSelection? result;
    await open(tester, host((value) => result = value));
    await selectCalendarOption(tester, 'app-calendar-filter', 'Multiple days');
    await tap(tester, 'app-calendar-day-2026-11-02');
    await tap(tester, 'app-calendar-day-2026-11-03');
    await tap(tester, 'app-calendar-day-2026-11-03');
    await selectCalendarOption(tester, 'app-calendar-year-picker', '2025');
    await selectCalendarOption(tester, 'app-calendar-month-picker', 'December');
    await tap(tester, 'app-calendar-day-2025-12-29');
    await selectCalendarOption(tester, 'app-calendar-year-picker', '2026');
    final month = calendarDropdown<int>(tester, 'app-calendar-month-picker');
    expect(month.value, 11);
    await tap(tester, 'app-calendar-apply');
    expect(result!.dates, [DateTime(2025, 12, 29), DateTime(2026, 11, 2)]);
  });

  testWidgets('Shortcuts replace stale filters with their exact date bounds',
      (tester) async {
    for (final label in ['Today', 'Last week', 'This month', 'All time']) {
      AppCalendarSelection? result;
      await open(
          tester,
          host((value) => result = value,
              selection: AppCalendarSelection(
                  mode: AppCalendarMode.days,
                  end: today,
                  dates: [DateTime(2026, 10, 12), today])));
      await selectCalendarOption(tester, 'app-calendar-filter', label);
      await tap(tester, 'app-calendar-apply');
      switch (label) {
        case 'Today':
          expect(result!.dates, [today]);
          expect(result!.mode, AppCalendarMode.day);
        case 'Last week':
          expect(result!.start, DateTime(2026, 10, 26));
          expect(result!.end, DateTime(2026, 11, 1));
        case 'This month':
          expect(result!.start, DateTime(2026, 11, 1));
          expect(result!.end, today);
        case 'All time':
          expect(result!.mode, AppCalendarMode.all);
          expect(result!.start, isNull);
          expect(result!.dates, isEmpty);
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
      'Option A quick preset pills allow 1-tap filtering and visual feedback',
      (tester) async {
    AppCalendarSelection? result;
    await open(tester, host((value) => result = value));

    expect(find.byKey(const ValueKey('app-calendar-pill-preset-today')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('app-calendar-pill-preset-this-week')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('app-calendar-pill-preset-last-week')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('app-calendar-pill-preset-this-month')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('app-calendar-pill-preset-all')),
        findsOneWidget);

    final todayPill = tester.widget<Semantics>(find
        .ancestor(
            of: find.byKey(const ValueKey('app-calendar-pill-preset-today')),
            matching: find.byType(Semantics))
        .first);
    expect(todayPill.properties.selected, isTrue);

    final lastWeekFinder =
        find.byKey(const ValueKey('app-calendar-pill-preset-last-week'));
    await tester.ensureVisible(lastWeekFinder);
    await tester.pumpAndSettle();
    await tester.tap(lastWeekFinder);
    await tester.pumpAndSettle();

    final lastWeekPill = tester.widget<Semantics>(find
        .ancestor(
            of: find.byKey(const ValueKey('app-calendar-pill-preset-last-week')),
            matching: find.byType(Semantics))
        .first);
    expect(lastWeekPill.properties.selected, isTrue);

    await tap(tester, 'app-calendar-apply');
    expect(result!.start, DateTime(2026, 10, 26));
    expect(result!.end, DateTime(2026, 11, 1));

    await tester.tap(find.byType(AppDateFilterButton));
    await tester.pumpAndSettle();

    final thisMonthFinder =
        find.byKey(const ValueKey('app-calendar-pill-preset-this-month'));
    await tester.ensureVisible(thisMonthFinder);
    await tester.pumpAndSettle();
    await tester.tap(thisMonthFinder);
    await tester.pumpAndSettle();

    final thisMonthPill = tester.widget<Semantics>(find
        .ancestor(
            of: find
                .byKey(const ValueKey('app-calendar-pill-preset-this-month')),
            matching: find.byType(Semantics))
        .first);
    expect(thisMonthPill.properties.selected, isTrue);

    await tap(tester, 'app-calendar-day-2026-11-02');
    final thisMonthAfterDayTap = tester.widget<Semantics>(find
        .ancestor(
            of: find
                .byKey(const ValueKey('app-calendar-pill-preset-this-month')),
            matching: find.byType(Semantics))
        .first);
    expect(thisMonthAfterDayTap.properties.selected, isFalse);
  });
}
