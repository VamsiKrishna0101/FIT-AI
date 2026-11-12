import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/notifications/services/notification_service.dart';

void main() {
  Future<void> pump(WidgetTester tester, String? type) =>
      tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: NotificationBannerContent(
                  title: 'Time to train',
                  body: 'Push day is ready',
                  type: type))));

  testWidgets('Mochi delivers coaching alerts in the app', (tester) async {
    await pump(tester, 'WORKOUT');
    expect(find.byKey(const ValueKey('notification-mochi')), findsOneWidget);
    expect(find.text('Time to train'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Billing notices stay plain', (tester) async {
    await pump(tester, 'TRIAL_ENDING');
    expect(find.byKey(const ValueKey('notification-mochi')), findsNothing);
    expect(find.text('Push day is ready'), findsOneWidget);
  });
}
