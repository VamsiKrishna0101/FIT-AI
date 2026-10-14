import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/navigation/onboarding_page_route.dart';
import 'core/navigation/authenticated_home.dart';
import 'core/storage/secure_session_store.dart';
import 'core/theme/ds_colors.dart';
import 'core/theme/ds_typography.dart';
import 'core/localization/language_manager.dart';
import 'core/localization/app_language.dart';
import 'features/onboarding/views/onboarding_view.dart';
import 'features/notifications/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['react-native-body-highlighter'],
        await rootBundle.loadString('assets/anatomy/LICENSE'));
  });
  await initializeDateFormatting();

  // Set system UI to immersive dark mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: DSColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize localization engine from cache
  await LanguageManager.shared.init();
  await NotificationService.shared.initialize();

  // Check persisted auth session token from secure hardware storage
  final token = await SecureSessionStore.shared.accessToken;
  if (token != null && token.isNotEmpty) {
    await LanguageManager.shared
        .syncAccountLanguage()
        .timeout(const Duration(seconds: 4), onTimeout: () {});
  }
  final Widget initialHome = (token != null && token.isNotEmpty)
      ? authenticatedHome()
      : const OnboardingView();

  runApp(FitAIApp(initialHome: initialHome));
}

// MARK: - Root FitAI Mobile Application
class FitAIApp extends StatelessWidget {
  final Widget initialHome;

  const FitAIApp({super.key, required this.initialHome});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageManager.shared,
      builder: (context, _) => MaterialApp(
        title: 'FitAI',
        scaffoldMessengerKey: NotificationService.messengerKey,
        locale: LanguageManager.shared.currentLanguage.locale,
        supportedLocales: AppLanguage.values.map((language) => language.locale),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: DSColors.bg,
          canvasColor: DSColors.bg,
          fontFamily: defaultTargetPlatform == TargetPlatform.iOS
              ? 'CupertinoSystemText'
              : DSTypography.family,
          textTheme: const TextTheme(
            displayLarge: DSTypography.onboardingTitle,
            displayMedium: DSTypography.pageTitle,
            displaySmall: DSTypography.onboardingTitle,
            headlineLarge: DSTypography.pageTitle,
            headlineMedium: DSTypography.pageTitle,
            headlineSmall: DSTypography.sectionTitle,
            titleLarge: DSTypography.cardTitle,
            titleMedium: DSTypography.sectionTitle,
            titleSmall: DSTypography.controlLabel,
            bodyLarge: DSTypography.body,
            bodyMedium: DSTypography.body,
            bodySmall: DSTypography.onboardingSubtitle,
            labelLarge: DSTypography.controlLabel,
            labelMedium: DSTypography.eyebrow,
          ).apply(
              fontFamily: defaultTargetPlatform == TargetPlatform.iOS
                  ? 'CupertinoSystemText'
                  : DSTypography.family),
          colorScheme: const ColorScheme.dark(
            primary: DSColors.accent,
            surface: DSColors.bgCard,
            surfaceContainerLowest: DSColors.bg,
            surfaceContainerLow: DSColors.bgCard,
            surfaceContainer: DSColors.bgCard,
            surfaceContainerHigh: DSColors.bgRaised,
            surfaceContainerHighest: DSColors.bgRaised,
            surfaceTint: Colors.transparent,
            onPrimary: DSColors.onAccent,
            onSurface: DSColors.textPrimary,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: DSColors.bg,
            foregroundColor: DSColors.textPrimary,
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: DSTypography.cardTitle,
          ),
          dividerTheme: const DividerThemeData(
            color: DSColors.border,
            thickness: 0.7,
            space: 1,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: DSColors.accent,
              foregroundColor: DSColors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: DSColors.textPrimary,
              side: const BorderSide(color: DSColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: DSColors.bgInset,
            hintStyle: const TextStyle(color: DSColors.textTertiary),
            labelStyle: const TextStyle(color: DSColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DSColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DSColors.borderHi),
            ),
          ),
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: DSColors.accent,
            scaffoldBackgroundColor: DSColors.bg,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: DSColors.bgCard,
            surfaceTintColor: Colors.transparent,
            modalBackgroundColor: DSColors.bgCard,
            showDragHandle: false,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: DSColors.bgCard,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: DSColors.border),
            ),
          ),
          // Keep route motion consistent across iOS and Android.
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: OnboardingPageTransitionsBuilder(),
              TargetPlatform.iOS: OnboardingPageTransitionsBuilder(),
            },
          ),
        ),
        home: initialHome,
      ),
    );
  }
}
