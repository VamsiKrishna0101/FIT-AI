import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setcraft/core/storage/onboarding_draft.dart';
import 'package:setcraft/core/localization/app_language.dart';
import 'package:setcraft/core/localization/language_manager.dart';
import 'package:setcraft/features/onboarding/models/equipment_models.dart';
import 'package:setcraft/features/onboarding/models/equipment_copy.dart';
import 'package:setcraft/features/onboarding/data/equipment_repository.dart';
import 'package:setcraft/features/onboarding/views/equipment_selection_view.dart';

class _Repository extends EquipmentRepository {
  EquipmentProfile profile;
  List<String>? saved;
  bool failSave = false;
  _Repository(this.profile);
  @override
  Future<EquipmentProfile> load() async => profile;
  @override
  Future<void> save(Iterable<String> ids) async {
    if (failSave) throw StateError('Fixture failure');
    saved = ids.toList()..sort();
  }
}

const _preview = ValueKey('equipment-preview');
Widget _app(Widget child,
        {double scale = 1, Locale locale = const Locale('en', 'GB')}) =>
    MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en', 'GB'), Locale('de', 'DE')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(key: _preview, child: child))));
Future<void> _size(WidgetTester tester,
    {double width = 393, double height = 852}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _capture(WidgetTester tester, String name) async {
  final context = tester.element(find.byType(EquipmentSelectionView));
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  await tester.runAsync(() async {
    for (final image in images) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_preview));
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build').createSync(recursive: true);
    File('build/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LanguageManager.shared.selectLanguage(AppLanguage.uk);
    await OnboardingDraft.clear();
  });
  test('all 19 supplied assets are bundled, with independent paired choices',
      () async {
    final paths = EquipmentCatalog.byId.values
        .map((item) => item.assetPath)
        .whereType<String>()
        .toSet();
    expect(paths.length, 19);
    for (final path in paths) {
      expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
    }
    expect(
        EquipmentCatalog.normalizeIds(
            ['barbell_rack', 'leg_extension_curl', 'lat_pulldown_row']),
        [
          'barbell',
          'lat_pulldown',
          'leg_curl',
          'leg_extension',
          'seated_row',
          'squat_rack'
        ]);
    expect(EquipmentCatalog.backendCategories(['leg_curl']), ['MACHINES']);
    for (final language in AppLanguage.values) {
      for (final id in EquipmentCatalog.byId.keys) {
        expect(EquipmentCopy.item(language, id), isNot(id));
      }
    }
  });

  testWidgets(
      'selecting equipment retains image layout and decoded provider through the transition',
      (tester) async {
    await _size(tester);
    await tester.pumpWidget(_app(const EquipmentSelectionView()));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('equipment-dumbbells'));
    final image = find.descendant(of: card, matching: find.byType(Image));
    final beforeElement = tester.element(image);
    final beforeProvider = tester.widget<Image>(image).image;
    final beforeSize = tester.getSize(image);
    await tester.tap(card);
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 30));
      expect(tester.element(image), same(beforeElement));
      expect(tester.widget<Image>(image).image, beforeProvider);
      expect(tester.getSize(image), beforeSize);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'conservative default is exclusive and exact choices preserve onboarding health data',
      (tester) async {
    await _size(tester);
    await OnboardingDraft(heightCm: 178, weightKg: 80, name: 'Nova').save();
    bool continued = false;
    await tester.pumpWidget(
        _app(EquipmentSelectionView(onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    expect(find.text('5 / 8'), findsNothing);
    expect(
        find.byKey(const ValueKey('onboarding-progress-fill')), findsNothing);
    expect(find.text('0 selected'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('equipment-dumbbells')));
    await tester.pumpAndSettle();
    // Selection is immediate; persistence follows a coalesced checkpoint.
    await tester.pump(const Duration(milliseconds: 410));
    expect((await OnboardingDraft.load()).equipmentIds, ['dumbbells']);
    await tester.ensureVisible(
        find.byKey(const ValueKey('equipment-adjustable_bench')));
    await tester.tap(find.byKey(const ValueKey('equipment-adjustable_bench')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final saved = await OnboardingDraft.load();
    expect(saved.equipmentIds, ['adjustable_bench', 'dumbbells']);
    expect(saved.heightCm, 178);
    expect(saved.weightKg, 80);
    expect(saved.name, 'Nova');
    expect(saved.completedStep, 5);
    expect(continued, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('returning draft retains legacy combined selections',
      (tester) async {
    await _size(tester);
    await OnboardingDraft(
            equipmentIds: ['barbell_rack', 'pec_deck_rear_delt'], weightKg: 77)
        .save();
    await tester.pumpWidget(_app(EquipmentSelectionView(onContinue: () {})));
    await tester.pumpAndSettle();
    expect(find.text('4 selected'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect((await OnboardingDraft.load()).equipmentIds,
        ['barbell', 'pec_deck', 'rear_delt', 'squat_rack']);
  });
  testWidgets(
      'profile editor saves precise choices without touching an onboarding draft',
      (tester) async {
    await _size(tester);
    await OnboardingDraft(equipmentIds: ['resistance_bands'], completedStep: 2)
        .save();
    final repository = _Repository(const EquipmentProfile(['seated_row']));
    bool saved = false;
    await tester.pumpWidget(_app(EquipmentSelectionView(
        editProfile: true,
        repository: repository,
        onContinue: () => saved = true)));
    await tester.pumpAndSettle();
    expect(find.text('5 / 8'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('equipment-dumbbells')));
    await tester.pumpAndSettle();
    repository.failSave = true;
    await tester.tap(find.text('Save equipment'));
    await tester.pumpAndSettle();
    expect(
        find.text('Could not save equipment. Please try again.'), findsWidgets);
    expect(repository.saved, isNull);
    expect(saved, isFalse);
    repository.failSave = false;
    await tester.tap(find.text('Save equipment'));
    await tester.pumpAndSettle();
    expect(repository.saved, ['dumbbells', 'seated_row']);
    expect(saved, isTrue);
    final draft = await OnboardingDraft.load();
    expect(draft.equipmentIds, ['resistance_bands']);
    expect(draft.completedStep, 2);
  });
  testWidgets(
      'legacy profiles require explicit equipment selection, not guessed gym access',
      (tester) async {
    await _size(tester);
    final repository =
        _Repository(const EquipmentProfile([], needsExactSelection: true));
    await tester.pumpWidget(_app(EquipmentSelectionView(
        editProfile: true, repository: repository, onContinue: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save equipment'));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    await tester.tap(find.text('No equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save equipment'));
    await tester.pumpAndSettle();
    expect(repository.saved, ['bodyweight_only']);
  });
  testWidgets('catalogue uses image rows, sections and square selections',
      (tester) async {
    await _size(tester);
    await OnboardingDraft(
        equipmentIds: ['dumbbells', 'adjustable_bench', 'seated_row']).save();
    await tester.pumpWidget(_app(const EquipmentSelectionView(coaching: true)));
    await tester.pumpAndSettle();
    expect(find.text('Review your equipment'), findsOneWidget);
    expect(find.text('Free weights'), findsOneWidget);
    expect(find.text('Machines & cables'), findsOneWidget);
    expect(find.text('Let’s check your equipment.'), findsNothing);
    expect(find.byType(Checkbox), findsNWidgets(EquipmentCatalog.byId.length));
    await _capture(tester, 'onboarding-equipment-preview');
    await tester
        .ensureVisible(find.byKey(const ValueKey('equipment-cable_station')));
    await _capture(tester, 'onboarding-equipment-machines-preview');
    await tester
        .ensureVisible(find.byKey(const ValueKey('equipment-leg_curl')));
    await _capture(tester, 'onboarding-equipment-extra-preview');
    await tester.ensureVisible(
        find.byKey(const ValueKey('equipment-resistance_bands')));
    await _capture(tester, 'onboarding-equipment-home-preview');
    expect(tester.takeException(), isNull);
  });
  testWidgets('search includes every machine and preserves hidden selections',
      (tester) async {
    await _size(tester);
    await tester.pumpWidget(_app(const EquipmentSelectionView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('equipment-dumbbells')));
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('equipment-search'));
    await tester.enterText(search, 'leg curl');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('equipment-dumbbells')), findsNothing);
    final curl = find.byKey(const ValueKey('equipment-leg_curl'));
    await tester.ensureVisible(curl);
    await tester.tap(curl);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('equipment-clear-search')));
    await tester.pumpAndSettle();
    final dumbbells = find.byKey(const ValueKey('equipment-dumbbells'));
    expect(
        tester
            .widget<Checkbox>(
                find.descendant(of: dumbbells, matching: find.byType(Checkbox)))
            .value,
        isTrue);
    expect(find.text('2 selected'), findsOneWidget);
    await tester.enterText(search, 'no such item');
    await tester.pumpAndSettle();
    expect(find.text('No equipment found'), findsOneWidget);
    await tester.enterText(search, 'leg_extension');
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('equipment-leg_extension')), findsOneWidget);
    // Human-readable ID queries are supported with spaces too.
    await tester.enterText(search, 'leg extension');
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('equipment-leg_extension')), findsOneWidget);
    expect(find.text('2 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'translated catalogue and search fit a narrow phone with keyboard',
      (tester) async {
    await _size(tester, width: 320, height: 640);
    await LanguageManager.shared.selectLanguage(AppLanguage.germany);
    await OnboardingDraft(languageCode: 'de').save();
    await tester.pumpWidget(_app(const EquipmentSelectionView(),
        scale: 1.4, locale: const Locale('de', 'DE')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, 'onboarding-equipment-german-preview');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('equipment-search'));
    await tester.enterText(search, 'dumbbells');
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('equipment-dumbbells'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('equipment-dumbbells')), findsOneWidget);
    expect(find.text('Fertig').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'onboarding-equipment-german-keyboard-preview');
  });
}
