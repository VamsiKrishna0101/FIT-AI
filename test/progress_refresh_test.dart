import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/progress/models/progress_models.dart';
import 'package:setcraft/features/progress/repositories/progress_repository.dart';
import 'package:setcraft/features/progress/views/progress_detail_view.dart';
import 'package:setcraft/features/progress/views/progress_overview_view.dart';

import 'progress_overview_redesign_test.dart' as fixture;

class _Repository extends ProgressRepository {
  final refreshes = <bool>[];
  @override
  Future<List<String>> pins() async => [];
  @override
  Future<ProgressJson?> cached(String path, String period,
          {Map<String, dynamic> query = const {}}) async =>
      fixture.overview.json;
  @override
  Future<ProgressJson> load(String path, String period,
      {bool refresh = false, Map<String, dynamic> query = const {}}) async {
    refreshes.add(refresh);
    return fixture.overview.json;
  }
}

void main() {
  testWidgets('Reopening Progress uses the repository freshness policy',
      (tester) async {
    final repository = _Repository();
    Widget page(bool active) => fixture.page(ProgressOverviewView(
        key: const ValueKey('progress'),
        repository: repository,
        isActive: active,
        clock: () => DateTime(2026, 10, 30)));
    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    expect(repository.refreshes, [false]);
    await tester.pumpWidget(page(false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    expect(repository.refreshes, [false, false]);

    repository.updates.add('invalidated');
    await tester.pumpAndSettle();
    expect(repository.refreshes.last, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await repository.updates.close();
  });

  testWidgets('Returning from a read-only detail does not bypass fresh cache',
      (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(fixture.page(ProgressOverviewView(
        repository: repository, clock: () => DateTime(2026, 10, 30))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training details'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressDetailView), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(repository.refreshes, everyElement(isFalse));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await repository.updates.close();
  });
}
