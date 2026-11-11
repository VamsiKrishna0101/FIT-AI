import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/profile/repositories/support_repository.dart';
import 'package:setcraft/features/profile/views/support_views.dart';
import 'package:setcraft/features/profile/views/privacy_settings_view.dart';
import 'package:setcraft/features/profile/legal/legal_content.dart';
import 'package:setcraft/features/profile/views/legal_document_view.dart';
import 'package:setcraft/features/profile/views/ai_sharing_consent.dart';
import 'helpers/fake_privacy_repository.dart';

class FakeSupport extends SupportRepository {
  final submissions = <Map<String, dynamic>>[],
      replies = <Map<String, dynamic>>[];
  bool failCreate = false, accountChanged = false;
  final thread = <String, dynamic>{
    'id': 'ticket',
    'number': 42,
    'category': 'NUTRITION',
    'subject': 'Morning meal is missing',
    'status': 'WAITING_FOR_USER',
    'messages': <Map<String, dynamic>>[
      {
        'id': 'm1',
        'authorRole': 'USER',
        'body': 'My breakfast is missing from the Today totals.',
        'createdAt': '2026-11-03T06:00:00Z',
        'attachments': []
      },
      {
        'id': 'm2',
        'authorRole': 'ADMIN',
        'body':
            'Thanks for reporting this. Can you check the selected date in Food diary?',
        'createdAt': '2026-11-03T06:30:00Z',
        'attachments': []
      },
    ]
  };
  @override
  Future<Map<String, dynamic>> configuration() async => {
        'supportEmail': 'help@example.invalid',
        'privacyPolicyUrl': 'https://example.invalid/privacy'
      };
  @override
  Future<Map<String, dynamic>> tickets({String? cursor}) async => {
        'tickets': [thread],
        'nextCursor': null
      };
  @override
  Future<Map<String, dynamic>> ticket(String id) async {
    if (accountChanged) {
      throw StateError('Your account changed. Reopen Settings.');
    }
    return Map.from(thread);
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> input) async {
    submissions.add(Map.from(input));
    if (failCreate) throw StateError('Could not connect. Try again.');
    return {'id': 'ticket', 'number': 42};
  }

  @override
  Future<void> reply(String id, Map<String, dynamic> input) async {
    replies.add(Map.from(input));
    thread['status'] = 'OPEN';
    (thread['messages'] as List).add({
      'id': 'm3',
      'authorRole': 'USER',
      'body': input['body'],
      'createdAt': '2026-11-03T07:00:00Z',
      'attachments': []
    });
  }
}

const preview = ValueKey('support-preview');
Widget app(Widget page, {double scale = 1}) => RepaintBoundary(
    key: preview,
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: page));
Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(preview));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(
        {'fitai_access_token': 'opaque', 'fitai_user_id': 'support-test'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('setcraft/settings'),
            (call) async => call.method == 'appInfo'
                ? {
                    'appVersion': '1.0.0',
                    'buildNumber': '2',
                    'platform': 'android',
                    'osVersion': '15'
                  }
                : null);
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('setcraft/settings'), null));
  testWidgets(
      'Ticket form validates locally and reuses a request ID after a failed send',
      (tester) async {
    final repo = FakeSupport()..failCreate = true;
    await tester.pumpWidget(app(SupportTicketForm(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send ticket'));
    await tester.pumpAndSettle();
    expect(repo.submissions, isEmpty);
    await tester.enterText(
        find.byType(TextFormField).first, 'Morning meal missing');
    await tester.enterText(find.byType(TextFormField).last,
        'The breakfast I logged is missing from Today.');
    await tester.tap(find.text('Send ticket'));
    await tester.pumpAndSettle();
    expect(repo.submissions.length, 1);
    expect(repo.submissions.first.containsKey('diagnostics'), false);
    await tester.tap(find.text('Send ticket'));
    await tester.pumpAndSettle();
    expect(repo.submissions.length, 2);
    expect(repo.submissions[0]['requestId'], repo.submissions[1]['requestId']);
  });
  testWidgets(
      'Ticket replies reopen the actual conversation and clear only after success',
      (tester) async {
    final repo = FakeSupport()..thread['status'] = 'RESOLVED';
    await tester
        .pumpWidget(app(SupportTicketView(id: 'ticket', repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Setcraft support'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('support-reply')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byKey(const ValueKey('support-reply')),
        'I still need help with breakfast.');
    await tester.ensureVisible(find.text('Send reply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send reply'));
    await tester.pumpAndSettle();
    expect(repo.replies.single['body'], 'I still need help with breakfast.');
    expect(repo.thread['status'], 'OPEN');
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('support-reply')))
            .controller!
            .text,
        isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('AI sharing asks first and records consent only on Agree',
      (tester) async {
    final repo = FakePrivacyRepository();
    bool? result;
    await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              result = await ensureAiSharingConsent(context, repository: repo);
            },
            child: const Text('Review sharing')))));
    await tester.tap(find.text('Review sharing'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-sharing-notice')), findsOneWidget);
    expect(find.textContaining('OpenAI, a third-party AI service'),
        findsOneWidget);
    expect(repo.changes, isEmpty);
    await tester.tap(find.byKey(const ValueKey('ai-sharing-agree')));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(repo.changes, [true]);

    // Already granted for this version: no second prompt.
    result = null;
    await tester.tap(find.text('Review sharing'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-sharing-notice')), findsNothing);
    expect(result, true);
  });
  testWidgets('Declining the AI sharing notice records nothing',
      (tester) async {
    final repo = FakePrivacyRepository();
    bool? result;
    await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
            onPressed: () async {
              result = await ensureAiSharingConsent(context, repository: repo);
            },
            child: const Text('Review sharing')))));
    await tester.tap(find.text('Review sharing'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-sharing-decline')));
    await tester.pumpAndSettle();
    expect(result, false);
    expect(repo.changes, isEmpty);
  });
  testWidgets(
      'Privacy revocation persists and keeps the current value when saving fails',
      (tester) async {
    final repo = FakePrivacyRepository()
      ..values.addAll(
          {'aiPlanningConsent': true, 'aiPlanningPolicyVersion': 'test-v1'});
    await tester.pumpWidget(app(PrivacySettingsView(privacyRepository: repo)));
    await tester.pumpAndSettle();
    repo.fail = true;
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
        true);
    expect(repo.changes, isEmpty);
    repo.fail = false;
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(repo.changes, [false]);
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
        false);
  });
  testWidgets('Privacy Policy opens in the app as a list of sections',
      (tester) async {
    await tester.pumpWidget(
        app(PrivacySettingsView(privacyRepository: FakePrivacyRepository())));
    await tester.pumpAndSettle();
    expect(find.text('MCP'), findsNothing);
    expect(find.text('Data use'), findsNothing);
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalDocumentView), findsOneWidget);
    for (final section in privacyPolicy.sections.take(4)) {
      expect(find.text(section.title), findsOneWidget);
    }
    await tester.tap(find.text('AI Plan Generation'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalSectionView), findsOneWidget);
    expect(find.textContaining('OpenAI, a third-party AI service'),
        findsOneWidget);
  });
  testWidgets('Legal screens fit small screens with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final doc in [privacyPolicy, termsOfUse]) {
      for (final page in <Widget>[
        LegalDocumentView(document: doc),
        for (final s in doc.sections)
          LegalSectionView(document: doc, section: s),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(app(page, scale: 1.8));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Support and privacy fit small screens with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final page in [
      HelpSupportView(repository: FakeSupport()),
      SupportTicketForm(repository: FakeSupport()),
      SupportTicketView(id: 'ticket', repository: FakeSupport()),
      PrivacySettingsView(privacyRepository: FakePrivacyRepository())
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app(page, scale: 1.8));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: page.runtimeType.toString());
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Capture support and privacy previews', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in <String, Widget>{
      'settings-support': HelpSupportView(repository: FakeSupport()),
      'settings-ticket-form': SupportTicketForm(repository: FakeSupport()),
      'settings-ticket-thread':
          SupportTicketView(id: 'ticket', repository: FakeSupport()),
      'settings-privacy-data':
          PrivacySettingsView(privacyRepository: FakePrivacyRepository()),
      'settings-privacy-policy':
          const LegalDocumentView(document: privacyPolicy),
      'settings-privacy-policy-section': LegalSectionView(
          document: privacyPolicy, section: privacyPolicy.sections[3]),
    }.entries) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app(entry.value));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, entry.key);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
