import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';
import 'package:setcraft/features/train/views/exercise_detail_view.dart';
import 'package:setcraft/core/media/fit_video_surface.dart';

WorkoutExerciseModel exercise({bool male = true, bool female = true}) =>
    WorkoutExerciseModel.fromJson({
      'id': 'curl',
      'name': 'Dumbbell curl',
      'bodyPart': 'Arms',
      'equipment': 'Dumbbell',
      'instructions': ['Keep your elbows still.'],
      'url': 'https://media.example/old-male.mp4',
      'thumbnailUrl': 'https://media.example/old-male.jpg',
      'mediaVariants': {
        if (male)
          'male': {
            'url': 'https://media.example/male.mp4',
            'posterUrl': 'https://media.example/male.jpg',
            'aspectRatio': 1.5
          },
        if (female)
          'female': {
            'url': 'https://media.example/female.mp4',
            'posterUrl': 'https://media.example/female.jpg',
            'aspectRatio': 1.0
          },
      },
    });

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({
        'fitai_access_token': 'test',
        'fitai_user_id': 'demo-selection-test',
      }));
  for (final gender in ['male', 'female']) {
    test('$gender selection uses its own video, poster and aspect ratio', () {
      final selected = exercise().withDemo(gender);
      expect(selected.url, 'https://media.example/$gender.mp4');
      expect(selected.thumbnailUrl, 'https://media.example/$gender.jpg');
      expect(selected.demoAspectRatio, gender == 'female' ? 1 : 1.5);
      expect(selected.id, 'curl');
      expect(selected.instructions, ['Keep your elbows still.']);
    });
    test('Missing $gender demo never retains the opposite video or poster', () {
      final selected =
          exercise(male: gender != 'male', female: gender != 'female')
              .withDemo(gender);
      expect(selected.url, isNull);
      expect(selected.thumbnailUrl, isNull);
      expect(selected.instructions, isNotEmpty);
      expect(WorkoutExerciseModel.fromJson(selected.toJson()).url, isNull);
    });
  }
  test('Switching selection on the same exercise replaces both media fields',
      () {
    final male = exercise().withDemo('male');
    final female = male.withDemo('female');
    expect(female.url, endsWith('/female.mp4'));
    expect(female.thumbnailUrl, endsWith('/female.jpg'));
    expect(female.withDemo('male').url, endsWith('/male.mp4'));
  });

  Widget view(ExerciseDetailView detail) => MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!),
      home: TickerMode(enabled: false, child: detail));

  for (final gender in ['male', 'female']) {
    testWidgets(
        'The saved $gender profile selects the same demo in exercise details',
        (tester) async {
      await tester.pumpWidget(view(ExerciseDetailView(
          exercise: exercise(),
          loadDetail: false,
          profileGenderLoader: () async => gender.toUpperCase())));
      await tester.pumpAndSettle();
      expect(tester.widget<FitVideoSurface>(find.byType(FitVideoSurface)).url,
          'https://media.example/$gender.mp4');
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('Explicit exercise filter wins over the saved profile default',
      (tester) async {
    var profileRequests = 0;
    await tester.pumpWidget(view(ExerciseDetailView(
        exercise: exercise(),
        loadDetail: false,
        mediaGender: 'male',
        profileGenderLoader: () async {
          profileRequests++;
          return 'FEMALE';
        })));
    await tester.pumpAndSettle();
    expect(tester.widget<FitVideoSurface>(find.byType(FitVideoSurface)).url,
        'https://media.example/male.mp4');
    expect(profileRequests, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('A slow profile lookup never flashes a mismatched cached demo',
      (tester) async {
    final profile = Completer<String?>();
    await tester.pumpWidget(view(ExerciseDetailView(
        exercise: exercise(),
        loadDetail: false,
        profileGenderLoader: () => profile.future)));
    await tester.pump();
    expect(tester.widget<FitVideoSurface>(find.byType(FitVideoSurface)).url,
        isNull);
    profile.complete('FEMALE');
    await tester.pumpAndSettle();
    expect(tester.widget<FitVideoSurface>(find.byType(FitVideoSurface)).url,
        'https://media.example/female.mp4');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'Missing female media keeps the instructions without a male animation',
      (tester) async {
    await tester.pumpWidget(view(ExerciseDetailView(
        exercise: exercise(female: false),
        loadDetail: false,
        mediaGender: 'female')));
    await tester.pumpAndSettle();
    expect(tester.widget<FitVideoSurface>(find.byType(FitVideoSurface)).url,
        isNull);
    await tester.scrollUntilVisible(find.text('Keep your elbows still.'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Keep your elbows still.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('An unavailable profile never reveals an unverified cached demo',
      (tester) async {
    await tester.pumpWidget(view(ExerciseDetailView(
        exercise: exercise(),
        loadDetail: false,
        profileGenderLoader: () async => throw StateError('Offline'))));
    await tester.pumpAndSettle();
    expect(tester.widget<FitVideoSurface>(find.byType(FitVideoSurface)).url,
        isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
