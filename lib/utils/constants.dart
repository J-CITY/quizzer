import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Quizzer';
  static const String dbName = 'quizzer.db';
  static const String developerName = 'Daniil Glushchenko';
  static const String developerEmail = 'daniil.glushchenko1995@gmail.com';
  static const Duration audioAdvanceDelay = Duration(milliseconds: 500);
  static const String notificationIcon = '@drawable/ic_launcher_foreground';
}

class IapConstants {
  static const String removeAdsProductId = 'remove_ads_product';
}

class AdConstants {
  // Test AdMob App ID
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  // Test Interstitial Ad Unit IDs
  static const String androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color success;
  final Color chart;
  final Color border;
  final Color textSecondary;
  final Color textPrimary;

  // Custom shades for UI
  final Color successBackground;
  final Color successText;
  final Color errorBackground;
  final Color iconBlue;
  final Color buttonDisabled;

  const AppColorsExtension({
    required this.success,
    required this.chart,
    required this.border,
    required this.textSecondary,
    required this.textPrimary,
    required this.successBackground,
    required this.successText,
    required this.errorBackground,
    required this.iconBlue,
    required this.buttonDisabled,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? success,
    Color? chart,
    Color? border,
    Color? textSecondary,
    Color? textPrimary,
    Color? successBackground,
    Color? successText,
    Color? errorBackground,
    Color? iconBlue,
    Color? buttonDisabled,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      chart: chart ?? this.chart,
      border: border ?? this.border,
      textSecondary: textSecondary ?? this.textSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      successBackground: successBackground ?? this.successBackground,
      successText: successText ?? this.successText,
      errorBackground: errorBackground ?? this.errorBackground,
      iconBlue: iconBlue ?? this.iconBlue,
      buttonDisabled: buttonDisabled ?? this.buttonDisabled,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      chart: Color.lerp(chart, other.chart, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      successBackground: Color.lerp(
        successBackground,
        other.successBackground,
        t,
      )!,
      successText: Color.lerp(successText, other.successText, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      iconBlue: Color.lerp(iconBlue, other.iconBlue, t)!,
      buttonDisabled: Color.lerp(buttonDisabled, other.buttonDisabled, t)!,
    );
  }
}

class AppTheme {
  static final lightExtension = AppColorsExtension(
    success: const Color(0xFF16A34A),
    chart: const Color(0xFFEAB308),
    border: const Color(0xFFE5E7EB),
    textSecondary: const Color(0xFF6B7280),
    textPrimary: const Color(0xFF111827),
    successBackground: const Color(0xFF16A34A).withValues(alpha: 0.1),
    successText: const Color(0xFF14532D), // dark green
    errorBackground: const Color(0xFFDC2626).withValues(alpha: 0.1),
    iconBlue: const Color(0xFF3B82F6),
    buttonDisabled: Colors.grey.shade400,
  );

  static final darkExtension = AppColorsExtension(
    success: const Color(0xFF22C55E),
    chart: const Color(0xFFFACC15),
    border: const Color(0xFF334155),
    textSecondary: const Color(0xFF94A3B8),
    textPrimary: const Color(0xFFF8FAFC),
    successBackground: const Color(0xFF22C55E).withValues(alpha: 0.15),
    successText: const Color(0xFF86EFAC), // light green
    errorBackground: const Color(0xFFF87171).withValues(alpha: 0.15),
    iconBlue: const Color(0xFF60A5FA),
    buttonDisabled: Colors.grey.shade700,
  );

  static const TextTheme _appTextTheme = TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontWeight: FontWeight.w600),
    labelLarge: TextStyle(fontWeight: FontWeight.w600),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF5B4FE9),
      secondary: Color(0xFF3B82F6),
      error: Color(0xFFDC2626),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF111827),
      onError: Colors.white,
    ),
    extensions: [lightExtension],
    fontFamilyFallback: const ['Yu Gothic', 'Meiryo', 'Noto Sans JP'],
    textTheme: _appTextTheme.apply(
      bodyColor: const Color(0xFF111827),
      displayColor: const Color(0xFF111827),
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D0D15),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7C6CFF),
      secondary: Color(0xFF60A5FA),
      error: Color(0xFFF87171),
      surface: Color(0xFF161622),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF8FAFC),
      onError: Colors.white,
    ),
    extensions: [darkExtension],
    fontFamilyFallback: const ['Yu Gothic', 'Meiryo', 'Noto Sans JP'],
    textTheme: _appTextTheme.apply(
      bodyColor: const Color(0xFFF8FAFC),
      displayColor: const Color(0xFFF8FAFC),
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF8FAFC),
      ),
    ),
  );
}

class ColorConstants {
  // Keep streak colors as they are
  static const streakColorDefault = Color.fromARGB(255, 59, 59, 59);
  static const streakColor3Days = Color(0xFFFF8A65);
  static const streakColor10Days = Color(0xFFFF9800);
  static const streakColor20Days = Color(0xFFFF3D00);
  static const streakColor30Days = Color(0xFFFF1744);
  static const streakColor60Days = Color(0xFF2BFF0A);
  static const streakColor100Days = Color(0xFFD500F9);
  static const streakColor200Days = Color(0xFF651FFF);
  static const streakColor365Days = Color(0xFF0509FF);
  static const streakColor500Days = Color(0xFF0AFFEB);
}
