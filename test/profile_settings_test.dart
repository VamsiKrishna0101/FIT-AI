import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/core/components/profile_avatar.dart';
import 'package:setcraft/features/profile/repositories/settings_repository.dart';
import 'package:setcraft/features/profile/views/profile_view.dart';
import 'package:setcraft/features/profile/views/profile_details_view.dart';
import 'package:setcraft/features/profile/views/training_settings_view.dart';
import 'package:setcraft/features/profile/views/equipment_settings_view.dart';
import 'package:setcraft/features/profile/views/settings_components.dart';
import 'package:setcraft/features/profile/views/mcp_connections_view.dart';
import 'package:setcraft/features/profile/views/privacy_settings_view.dart';
import 'package:setcraft/features/profile/views/settings_preferences_view.dart';
import 'package:setcraft/features/body_scan/models/body_assessment_models.dart';
import 'package:setcraft/features/body_scan/repositories/body_assessment_repository.dart';
import 'package:setcraft/core/watch/views/apple_watch_settings_view.dart';
import 'helpers/fake_mcp_repository.dart';

class _SettingsRepository extends SettingsRepository {
  Map<String, dynamic>? saved;
  final saves = <Map<String, dynamic>>[];
  Map<String, dynamic> overrides = {};
  bool failLoad = false;
  bool failSave = false;
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
      'trainingDays': ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
      'daysPerWeek': 'DAYS_3',
      'trainingSplit': 'FULL_BODY',
      'customTrainingSplit': <String, dynamic>{},
      'workoutDuration': 'MIN_45',
      'trainingLocation': 'GYM',
      'preferredTime': 'MORNING',
      'equipmentIds': ['adjustable_bench', 'dumbbells'],
      'focusMuscles': [],
      'limitations': ['KNEE'],
      'customLimitations': 'Avoid deep knee flexion',
      'foodBudgetAmount': 75,
      'foodBudgetCurrency': 'GBP',
      ...overrides,
    };
  }

  @override
  Future<void> saveProfile(Map<String, dynamic> changes) async {
    if (failSave) throw const FormatException('Could not save profile.');
    saved = changes;
    saves.add(Map<String, dynamic>.from(changes));
    overrides.addAll(changes);
  }

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

Widget _app(Widget child, {double scale = 1}) => RepaintBoundary(
    key: _preview,
    child: MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Builder(
          builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child,
              )),
    ));

Future<void> _capture(WidgetTester tester, String name) async {
  if (find.byType(EquipmentSettingsView).evaluate().isNotEmpty) {
    final context = tester.element(find.byType(EquipmentSettingsView));
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    await tester.runAsync(() async {
      for (final image in images) {
        await precacheImage(image.image, context);
      }
    });
    await tester.pumpAndSettle();
  }
  await tester.pump(const Duration(milliseconds: 300));
  if (find.byType(TrainingSettingsView).evaluate().isNotEmpty) {
    expect(find.byKey(const ValueKey('training-save')).hitTestable(),
        findsOneWidget);
  }
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

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 160, scrollable: scrollable);
    }
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String key, String option) async {
  await _tapVisible(tester, find.byKey(ValueKey(key)));
  final menu = find.byType(Scrollable).last;
  final item = find.descendant(of: menu, matching: find.text(option));
  if (item.evaluate().isEmpty) {
    tester.state<ScrollableState>(menu).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(item, 120, scrollable: menu);
  }
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
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

  testWidgets('Settings opens MCP directly without a provider menu',
      (tester) async {
    await tester.pumpWidget(_app(ProfileView(
        repository: _SettingsRepository(),
        mcpRepository: FakeMcpRepository())));
    await tester.pumpAndSettle();
    expect(find.text('Sleep preferences'), findsNothing);
    expect(find.text('AI connections'), findsNothing);
    await tester.scrollUntilVisible(find.text('MCP'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MCP'));
    await tester.pumpAndSettle();
    expect(find.text('Claude'), findsOneWidget);
    expect(find.byType(ClaudeConnectionView), findsOneWidget);
    expect(find.text('Create access token'), findsOneWidget);
    expect(find.text('No access tokens. Create one to set up Claude.'),
        findsOneWidget);
    expect(find.text('ChatGPT'), findsNothing);
    expect(find.text('Connect'), findsNothing);
    expect(find.text('Connected'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Personal settings open directly without the duplicate profile row',
      (tester) async {
    await tester
        .pumpWidget(_app(ProfileView(repository: _SettingsRepository())));
    await tester.pumpAndSettle();
    expect(find.text('Personal details'), findsNothing);
    expect(find.text('Edit profile'), findsOneWidget);
    for (final title in ['Training', 'Nutrition']) {
      final row = find.ancestor(
          of: find.text(title), matching: find.byType(SettingsRow));
      expect(tester.widget<SettingsRow>(row).icon, isNull);
    }
    await _tapVisible(tester, find.text('Training'));
    expect(find.byType(TrainingSettingsView), findsOneWidget);
    expect(find.text('Experience & goal'), findsNothing);
    expect(find.text('Training preferences'), findsNothing);
    await _tapVisible(tester, find.text('Equipment'));
    expect(find.byType(EquipmentSettingsView), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byKey(const ValueKey('equipment-dumbbells')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSettingsView), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await _tapVisible(tester, find.text('Nutrition'));
    expect(find.byType(ProfileDetailsView), findsOneWidget);
    expect(find.text('Food preferences'), findsOneWidget);
    expect(find.text('Personal details'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Equipment saves separately and preserves unsaved training changes',
      (tester) async {
    final repository = _SettingsRepository();
    await tester.pumpWidget(_app(TrainingSettingsView(repository: repository)));
    await tester.pumpAndSettle();
    for (final day in ['WEDNESDAY', 'SATURDAY']) {
      await _tapVisible(tester, find.byKey(ValueKey('training-day-$day')));
    }
    await _choose(tester, 'training-choice-Training split', 'Upper / lower');
    await _choose(tester, 'training-choice-Session length', '30 min');
    await _choose(tester, 'training-choice-Preferred time', 'Evening');
    await _tapVisible(tester, find.text('Equipment'));
    await _choose(tester, 'equipment-location', 'Home');
    await _tapVisible(tester, find.byKey(const ValueKey('equipment-barbell')));
    await tester.tap(find.byKey(const ValueKey('equipment-save')));
    await tester.pumpAndSettle();
    expect(repository.saves.single, {
      'equipmentIds': ['adjustable_bench', 'barbell', 'dumbbells'],
      'equipment': ['BARBELLS', 'BENCH', 'DUMBBELLS'],
      'trainingLocation': 'HOME',
    });
    expect(find.byType(TrainingSettingsView), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);
    await _tapVisible(tester, find.text('Muscle focus'));
    await _tapVisible(
        tester, find.byKey(const ValueKey('training-focus-core')));
    await tester.tap(find.byKey(const ValueKey('training-save')));
    await tester.pumpAndSettle();
    expect(repository.saved, {
      'trainingDays': ['MONDAY', 'FRIDAY', 'SATURDAY'],
      'daysPerWeek': 'DAYS_3',
      'trainingSplit': 'UPPER_LOWER',
      'preferredTime': 'EVENING',
      'customTrainingSplit': <String, dynamic>{},
      'focusMuscles': ['core'],
      'customLimitations': 'Avoid deep knee flexion',
      'workoutDuration': 'MIN_30',
    });
    expect(repository.saves.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Training validates days, rest and incomplete custom splits',
      (tester) async {
    final cases = [
      (
        {
          'trainingDays': ['MONDAY']
        },
        'Choose at least two training days.'
      ),
      (
        {
          'trainingDays': [
            'MONDAY',
            'TUESDAY',
            'WEDNESDAY',
            'THURSDAY',
            'FRIDAY',
            'SATURDAY',
            'SUNDAY'
          ]
        },
        'Keep at least one rest day in your week.'
      ),
      (
        {
          'trainingDays': ['MONDAY', 'FRIDAY'],
          'trainingSplit': 'PUSH_PULL_LEGS'
        },
        'Choose at least three days for push / pull / legs.'
      ),
      (
        {
          'trainingDays': ['MONDAY', 'FRIDAY'],
          'trainingSplit': 'CUSTOM',
          'customTrainingSplit': {
            'MONDAY': ['chest']
          }
        },
        'Choose at least one muscle group for each training day.'
      ),
    ];
    for (final (data, error) in cases) {
      await tester.pumpWidget(const SizedBox.shrink());
      final repository = _SettingsRepository()..overrides = data;
      await tester
          .pumpWidget(_app(TrainingSettingsView(repository: repository)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('training-save')));
      await tester.pumpAndSettle();
      expect(repository.saved, isNull);
      expect(find.text(error), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Equipment uses photos and white selection across categories',
      (tester) async {
    final repository = _SettingsRepository();
    await tester
        .pumpWidget(_app(EquipmentSettingsView(repository: repository)));
    await tester.pumpAndSettle();
    final barbell = find.byKey(const ValueKey('equipment-barbell'));
    final photo = tester.widget<Image>(
        find.descendant(of: barbell, matching: find.byType(Image)));
    expect((photo.image as ResizeImage).imageProvider, isA<AssetImage>());
    expect(((photo.image as ResizeImage).imageProvider as AssetImage).assetName,
        'assets/onboarding_images/barbell.webp');
    await _tapVisible(tester, barbell);
    expect(tester.widget<EquipmentSettingsTile>(barbell).selected, isTrue);
    expect(
        tester
            .widget<Material>(find
                .descendant(of: barbell, matching: find.byType(Material))
                .first)
            .color,
        Colors.white);
    await _tapVisible(
        tester, find.byKey(const ValueKey('equipment-group-machines')));
    await _tapVisible(
        tester, find.byKey(const ValueKey('equipment-cable_station')));
    await tester.tap(find.byKey(const ValueKey('equipment-save')));
    await tester.pumpAndSettle();
    expect(repository.saved?['equipmentIds'],
        ['adjustable_bench', 'barbell', 'cable_station', 'dumbbells']);
    expect(repository.saved?['equipment'],
        ['BARBELLS', 'BENCH', 'CABLE', 'DUMBBELLS']);
    expect(repository.saved?.containsKey('trainingDays'), isFalse);
    expect(repository.saved?.containsKey('foodAllergies'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'No equipment stays exclusive and can be replaced by a photo choice',
      (tester) async {
    for (final onlyBodyweight in [false, true]) {
      await tester.pumpWidget(const SizedBox.shrink());
      final repository = _SettingsRepository();
      if (onlyBodyweight) {
        repository.overrides = {
          'equipmentIds': ['bodyweight_only']
        };
      }
      await tester
          .pumpWidget(_app(EquipmentSettingsView(repository: repository)));
      await tester.pumpAndSettle();
      final id = onlyBodyweight ? 'dumbbells' : 'bodyweight_only';
      await _tapVisible(tester, find.byKey(ValueKey('equipment-$id')));
      await tester.tap(find.byKey(const ValueKey('equipment-save')));
      await tester.pumpAndSettle();
      expect(repository.saved?['equipmentIds'], [id]);
      expect(repository.saved?['equipment'],
          [onlyBodyweight ? 'DUMBBELLS' : 'OTHER']);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'Custom training keeps saved muscles and saves only selected days',
      (tester) async {
    final repository = _SettingsRepository()
      ..overrides = {
        'trainingDays': ['MONDAY', 'WEDNESDAY'],
        'trainingSplit': 'CUSTOM',
        'customTrainingSplit': {
          'MONDAY': ['chest'],
          'TUESDAY': ['legs']
        },
      };
    await tester.pumpWidget(_app(TrainingSettingsView(repository: repository)));
    await tester.pumpAndSettle();
    await _tapVisible(
        tester, find.byKey(const ValueKey('training-custom-WEDNESDAY')));
    await _tapVisible(
        tester, find.byKey(const ValueKey('training-custom-WEDNESDAY-back')));
    await tester.tap(find.byKey(const ValueKey('training-save')));
    await tester.pumpAndSettle();
    expect(repository.saved?['customTrainingSplit'], {
      'MONDAY': ['chest'],
      'WEDNESDAY': ['back'],
    });
    expect(repository.saved?['daysPerWeek'], 'DAYS_2');
    expect(repository.saved?.containsKey('equipmentIds'), isFalse);
    expect(repository.saved?.containsKey('limitations'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Training retry preserves edits and refuses a changed account',
      (tester) async {
    final repository = _SettingsRepository()..failLoad = true;
    await tester.pumpWidget(_app(TrainingSettingsView(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsNothing);
    repository.failLoad = false;
    await _tapVisible(tester, find.text('Try again'));
    await _tapVisible(tester, find.text('Movement needs'));
    await tester.enterText(
        find.byKey(const ValueKey('training-notes')), 'Avoid jumping');
    repository.failSave = true;
    await tester.tap(find.byKey(const ValueKey('training-save')));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(find.text('Avoid jumping').first, findsOneWidget);
    repository.failSave = false;
    FlutterSecureStorage.setMockInitialValues({
      'fitai_access_token': 'opaque',
      'fitai_user_id': 'different-user',
    });
    await tester.tap(find.byKey(const ValueKey('training-save')));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(find.byType(TrainingSettingsView), findsOneWidget);
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
    await tester.enterText(find.byType(TextFormField).at(3), '70,5');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(repository.saved?['name'], 'Vamsi');
    expect(repository.saved?['age'], 28);
    expect(repository.saved?['weight'], 70.5);
    expect(repository.saved?.containsKey('countryCode'), false);
    expect(find.text('Country'), findsNothing);
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

  testWidgets('Nutrition budget edits validate and can clear a saved budget',
      (tester) async {
    final repository = _SettingsRepository();
    await tester.pumpWidget(
        _app(ProfileDetailsView(nutrition: true, repository: repository)));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Weekly budget'));
    final amount = find.byKey(const ValueKey('profile-field-Amount'));
    await tester.enterText(amount, '-5');
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(find.text('Enter a valid weekly budget, or leave it blank.'),
        findsOneWidget);
    await tester.enterText(amount, '75,50');
    await _choose(tester, 'profile-choice-Currency', 'INR');
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(repository.saved?['foodBudgetAmount'], 75.5);
    expect(repository.saved?['foodBudgetCurrency'], 'INR');
    expect(repository.saved?['weeklyFoodBudget'], isNull);
    expect(repository.saved?.containsKey('trainingDays'), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    repository.saved = null;
    await tester.pumpWidget(
        _app(ProfileDetailsView(nutrition: true, repository: repository)));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Weekly budget'));
    await tester.enterText(
        find.byKey(const ValueKey('profile-field-Amount')), '');
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(repository.saved?.containsKey('foodBudgetAmount'), isTrue);
    expect(repository.saved?['foodBudgetAmount'], isNull);
    expect(repository.saved?['foodBudgetCurrency'], isNull);
    expect(repository.saved?.containsKey('weeklyFoodBudget'), isTrue);
    expect(tester.takeException(), isNull);
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

  testWidgets('Profile dropdowns save their actual selections', (tester) async {
    final repository = _SettingsRepository();
    await tester.pumpWidget(_app(ProfileDetailsView(repository: repository)));
    await tester.pumpAndSettle();
    Future<void> choose(String field, String option) async {
      final dropdown = find.byKey(ValueKey('profile-choice-$field'));
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    await choose('Gender', 'Female');
    await choose('Fitness goal', 'Get stronger');
    await choose('Experience', 'Intermediate');
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(repository.saved?['gender'], 'FEMALE');
    expect(repository.saved?['workingToward'], 'GET_STRONGER');
    expect(repository.saved?['experience'], 'INTERMEDIATE');
    expect(repository.saved?['height'], 175);
    expect(repository.saved?.containsKey('eatingStyle'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Save stays above the keyboard while editing measurements',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _SettingsRepository();
    await tester.pumpWidget(_app(ProfileDetailsView(repository: repository)));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    final weight =
        find.byKey(const ValueKey('profile-field-Current weight (kg)'));
    await tester.ensureVisible(weight);
    await tester.pumpAndSettle();
    await tester.enterText(weight, '72,5');
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('profile-save'));
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(852 - 280));
    await _capture(tester, 'profile-editor-keyboard');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.saved?['weight'], 72.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A failed save keeps the entered profile available for retry',
      (tester) async {
    final repository = _SettingsRepository()..failSave = true;
    await tester.pumpWidget(_app(ProfileDetailsView(repository: repository)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('profile-field-Name')), 'Updated member');
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(find.byType(ProfileDetailsView), findsOneWidget);
    repository.failSave = false;
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(repository.saved?['name'], 'Updated member');
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
      ClaudeConnectionView(repository: FakeMcpRepository()),
      const SettingsPreferencesView(),
      const SettingsLanguageView(),
      ProfileDetailsView(repository: _SettingsRepository()),
      ProfileDetailsView(nutrition: true, repository: _SettingsRepository()),
      TrainingSettingsView(repository: _SettingsRepository()),
      EquipmentSettingsView(repository: _SettingsRepository()),
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
    Future<void> show(Widget page) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app(page));
      await tester.pumpAndSettle();
    }

    await show(ProfileView(repository: _SettingsRepository()));
    await _capture(tester, 'settings-overview');
    await show(ProfileDetailsView(repository: _SettingsRepository()));
    await _capture(tester, 'profile-editor-phone');
    await tester.drag(find.byType(ListView).first, const Offset(0, -450));
    await tester.pumpAndSettle();
    await _capture(tester, 'profile-editor-training');
    await show(TrainingSettingsView(repository: _SettingsRepository()));
    await _capture(tester, 'settings-training-compact');
    await show(EquipmentSettingsView(repository: _SettingsRepository()));
    await _capture(tester, 'settings-equipment-photos');
    await show(
        ProfileDetailsView(nutrition: true, repository: _SettingsRepository()));
    await _capture(tester, 'settings-nutrition-compact');
    await _tapVisible(tester, find.text('Weekly budget'));
    await _capture(tester, 'settings-nutrition-budget');
    await show(ClaudeConnectionView(repository: FakeMcpRepository()));
    await _capture(tester, 'settings-claude');
    await show(const AppleWatchSettingsView());
    await _capture(tester, 'settings-watch');
    expect(tester.takeException(), isNull);
  });

  for (final nutrition in [false, true]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets(
          'Editor stays visible above a compact Save button: nutrition=$nutrition scale=$scale',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(
            ProfileDetailsView(
                nutrition: nutrition, repository: _SettingsRepository()),
            scale: scale));
        await tester.pumpAndSettle();
        expect(find.text('Country'), findsNothing);
        expect(
            find.text('Choose where you live. Your language stays the same.'),
            findsNothing);
        final button = find.byKey(const ValueKey('profile-save'));
        expect(tester.getSize(button).height, lessThan(120));
        expect(find.byType(TextFormField).first.hitTestable(), findsOneWidget);
        expect(find.text('Save changes').hitTestable(), findsOneWidget);
        expect(
            tester.getRect(button).top,
            greaterThan(
                tester.getRect(find.byType(TextFormField).first).bottom));
        if (scale == 1) {
          await _capture(tester,
              nutrition ? 'nutrition-editor-fixed' : 'personal-details-fixed');
        }
        await tester.drag(find.byType(ListView).first, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(find.text('Save changes').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
