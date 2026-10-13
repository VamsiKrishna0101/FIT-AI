import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/components/profile_avatar.dart';
import 'package:fitai_mobile/features/profile/repositories/settings_repository.dart';
import 'package:fitai_mobile/features/profile/views/profile_view.dart';
import 'package:fitai_mobile/features/profile/views/profile_details_view.dart';
import 'package:fitai_mobile/features/profile/views/mcp_connections_view.dart';
import 'package:fitai_mobile/features/profile/views/privacy_settings_view.dart';
import 'package:fitai_mobile/features/profile/views/settings_preferences_view.dart';
import 'package:fitai_mobile/features/body_scan/models/body_assessment_models.dart';
import 'package:fitai_mobile/features/body_scan/repositories/body_assessment_repository.dart';

class _SettingsRepository extends SettingsRepository {
  Map<String, dynamic>? saved;
  bool failLoad = false;
  int deletions = 0, exports = 0, signOuts = 0;

  @override
  Future<Map<String, dynamic>> profile() async {
    if (failLoad) throw StateError('Profile unavailable');
    return {
      'name': 'Vamsi Krishna',
      'age': 27,
      'gender': 'MALE',
      'height': 175,
      'weight': 70,
      'targetWeight': 72,
      'workingToward': 'BUILD_MUSCLE',
      'experience': 'BEGINNER',
      'eatingStyle': 'VEGETARIAN',
      'foodAllergies': ['Peanuts'],
      'dislikedFoods': [],
    };
  }

  @override
  Future<void> saveProfile(Map<String, dynamic> changes) async =>
      saved = changes;

  @override
  Future<Map<String, dynamic>> exportData() async {
    exports++;
    return {
      'user': {'email': 'test@example.com'}
    };
  }

  @override
  Future<void> deleteAccount({required String expectedOwner}) async =>
      deletions++;

  @override
  Future<void> signOut() async => signOuts++;
}

class _BodyRepository extends BodyAssessmentRepository {
  int deletions = 0;
  bool deleted = false;

  BodyOverview get overview => BodyOverview.fromJson({
        'records': [
          {
            'id': 'saved-scan',
            'recordedDate': '2026-10-12',
            'status': 'SAVED',
            'method': 'photo_review',
            'metrics': {},
            'updatedAt': '2026-10-12T09:00:00Z',
            'photos': deleted
                ? []
                : [
                    {'id': 'photo', 'view': 'front', 'url': '/private-photo'}
                  ],
          }
        ]
      });

  @override
  Future<BodyOverview> load() async => overview;

  @override
  Future<BodyAssessment> deletePhotos(String id) async {
    expect(id, 'saved-scan');
    deletions++;
    deleted = true;
    return overview.records.single;
  }
}

const _preview = ValueKey('settings-preview');

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Builder(
          builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(key: _preview, child: child),
              )),
    );

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_preview));
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in {
      'Inter': 'assets/fonts/Inter.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'fitai_access_token': 'opaque',
        'fitai_user_id': 'settings-user',
      }));

  testWidgets('Circular avatar opens settings with initials and no extra icon',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: ProfileAvatar(
                      name: 'Vamsi Krishna',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => ProfileView(
                                  repository: _SettingsRepository())))),
                ))));
    expect(tester.getSize(find.byType(ProfileAvatar)), const Size(44, 44));
    expect(tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).size, 34);
    expect(find.text('VK'), findsOneWidget);
    // The small visible circle still has an accessible 44 px tap target.
    await tester.tapAt(
        tester.getTopLeft(find.byType(ProfileAvatar)) + const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Vamsi Krishna'), findsOneWidget);
  });

  testWidgets('Settings opens MCP then a detailed unconnected Claude screen',
      (tester) async {
    await tester
        .pumpWidget(_app(ProfileView(repository: _SettingsRepository())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('MCP & integrations'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MCP & integrations'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'No AI apps are connected. This feature is not available yet.'),
        findsOneWidget);
    await tester.tap(find.text('Claude'));
    await tester.pumpAndSettle();
    expect(find.text('FitAI × Claude'), findsOneWidget);
    expect(find.text('Weekly plans'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.text('Connect'), findsNothing);
    expect(find.text('Connected'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Personal edits save profile fields without overwriting nutrition',
      (tester) async {
    final repository = _SettingsRepository();
    await tester.pumpWidget(_app(ProfileView(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Vamsi');
    await tester.enterText(find.byType(TextFormField).at(1), '28.0');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(repository.saved?['name'], 'Vamsi');
    expect(repository.saved?['age'], 28);
    expect(repository.saved?['weight'], 70);
    expect(repository.saved?.containsKey('foodAllergies'), false);
  });

  testWidgets(
      'Nutrition saves deduplicated food choices without profile changes',
      (tester) async {
    final repository = _SettingsRepository();
    await tester.pumpWidget(
        _app(ProfileDetailsView(nutrition: true, repository: repository)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, ' Peanuts, milk, Peanuts ');
    await tester.enterText(find.byType(TextFormField).at(1), 'Mushrooms');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(repository.saved, {
      'eatingStyle': 'VEGETARIAN',
      'customEatingStyle': null,
      'foodAllergies': ['Peanuts', 'milk'],
      'dislikedFoods': ['Mushrooms']
    });
  });

  testWidgets('Failed profile loading offers retry and prevents an empty save',
      (tester) async {
    final repository = _SettingsRepository()..failLoad = true;
    await tester.pumpWidget(_app(ProfileDetailsView(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    repository.failLoad = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Privacy preserves scans and account unless deletion is confirmed',
      (tester) async {
    final repository = _SettingsRepository();
    final body = _BodyRepository();
    await tester.pumpWidget(_app(
        PrivacySettingsView(repository: repository, bodyRepository: body)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete saved photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(body.deletions, 0);
    await tester.tap(find.text('Delete saved photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete photos'));
    await tester.pumpAndSettle();
    expect(body.deletions, 1);
    expect(body.overview.records.length, 1);
    expect(find.text('0'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delete account'), 120);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deletions, 0);
  });

  testWidgets('Export loads real repository data into a readable JSON page',
      (tester) async {
    final repository = _SettingsRepository();
    await tester.pumpWidget(_app(PrivacySettingsView(
        repository: repository, bodyRepository: _BodyRepository())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Export my data'), 120);
    await tester.tap(find.text('Export my data'));
    await tester.pumpAndSettle();
    expect(repository.exports, 1);
    expect(find.text('Copy JSON'), findsOneWidget);
    expect(find.textContaining('test@example.com'), findsOneWidget);
    expect(repository.deletions, 0);
  });

  testWidgets('Settings detail pages fit a small phone with enlarged text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final page in [
      ProfileView(repository: _SettingsRepository()),
      const McpConnectionsView(),
      const ClaudeConnectionView(),
      const SettingsPreferencesView(),
      const SettingsLanguageView(),
      ProfileDetailsView(repository: _SettingsRepository()),
      PrivacySettingsView(
          repository: _SettingsRepository(), bodyRepository: _BodyRepository()),
    ]) {
      await tester.pumpWidget(_app(page, scale: 1.8));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: page.runtimeType.toString());
    }
  });

  testWidgets('Capture Settings and Claude previews', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(_app(ProfileView(repository: _SettingsRepository())));
    await tester.pumpAndSettle();
    await _capture(tester, 'settings-overview');
    await tester.pumpWidget(_app(const ClaudeConnectionView()));
    await tester.pumpAndSettle();
    await _capture(tester, 'settings-claude');
    expect(tester.takeException(), isNull);
  });
}
