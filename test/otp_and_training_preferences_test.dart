import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';
import 'package:fitai_mobile/features/auth/views/auth_view.dart';
import 'package:fitai_mobile/features/onboarding/views/training_preferences_view.dart';

Widget app(Widget child, {double scale = 1}) => MaterialApp(
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter'),
        inputDecorationTheme:
            const InputDecorationTheme(filled: true, fillColor: Colors.red),
      ),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
      'OTP boxes stay visible during typing, paste and deletion with a filled input theme',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    final capture = GlobalKey();
    String? submitted;

    tester.view.physicalSize = const Size(393, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(Scaffold(
      body: Center(
          child: RepaintBoundary(
        key: capture,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: OtpCodeField(
              controller: controller,
              focusNode: focus,
              onSubmitted: (code) => submitted = code),
        ),
      )),
    )));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    for (final digit in '123456'.split('')) {
      expect(find.text(digit), findsOneWidget);
    }

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.decoration!.filled, false);
    expect(input.decoration!.fillColor, Colors.transparent);
    expect(input.autofillHints, contains(AutofillHints.oneTimeCode));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, '123456');

    await tester.enterText(find.byType(TextField), '12a34567');
    await tester.pumpAndSettle();
    expect(controller.text, '123456');
    await tester.enterText(find.byType(TextField), '12');
    await tester.pumpAndSettle();
    expect(find.text('3'), findsNothing);
    expect(find.byType(AnimatedContainer), findsNWidgets(6));

    await tester.enterText(find.byType(TextField), '481926');
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(find.byKey(capture))
          .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/previews').createSync(recursive: true);
      File('build/previews/otp-code.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    focus.dispose();
  });

  test('Training split survives local persistence and registration payload',
      () async {
    final draft = OnboardingDraft(
      trainingDays: ['MONDAY', 'WEDNESDAY'],
      trainingSplit: 'CUSTOM',
      customTrainingSplit: {
        'MONDAY': ['biceps', 'triceps'],
        'WEDNESDAY': ['chest', 'legs']
      },
    );
    await draft.save();
    final loaded = await OnboardingDraft.load();
    expect(loaded.trainingSplit, 'CUSTOM');
    expect(loaded.customTrainingSplit['MONDAY'], ['biceps', 'triceps']);
    expect(loaded.personalizationPayload()['customTrainingSplit'],
        draft.customTrainingSplit);
    expect(OnboardingDraft.fromJson({}).trainingSplit, 'AUTO');
  });

  testWidgets(
      'Custom split displays day-specific muscle choices and saves them',
      (tester) async {
    await OnboardingDraft(
      trainingDays: ['MONDAY', 'WEDNESDAY'],
      trainingSplit: 'CUSTOM',
      customTrainingSplit: {
        'MONDAY': ['biceps', 'triceps'],
        'WEDNESDAY': ['chest', 'legs']
      },
    ).save();
    bool continued = false;
    await tester.pumpWidget(
        app(TrainingPreferencesView(onContinue: () => continued = true)));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(find.text('Choose each day'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Choose each day'), findsOneWidget);
    // Custom days appear once, in their editable muscle list.
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Wednesday'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Build my plan'));
    await tester.tap(find.text('Build my plan'));
    await tester.pumpAndSettle();
    expect(continued, true);
    expect((await OnboardingDraft.load()).customTrainingSplit['MONDAY'],
        ['biceps', 'triceps']);
    expect(tester.takeException(), isNull);
  });
}
