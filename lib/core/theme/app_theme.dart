import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

// Midnight Luxe dark theme - poori app isi me chalegi.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryViolet,
        secondary: AppColors.primaryPink,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.heading,
        titleMedium: AppTextStyles.subHeading,
        bodyMedium: AppTextStyles.body,
        labelSmall: AppTextStyles.caption,
      ),
    );
  }
}
