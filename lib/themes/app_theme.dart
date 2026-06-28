import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.wine900,
        brightness: Brightness.light,
        primary: AppColors.wine900,
        secondary: AppColors.wine700,
        surface: AppColors.lightSurface,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.wine700,
        brightness: Brightness.dark,
        primary: AppColors.beige100,
        secondary: AppColors.beige300,
        surface: AppColors.darkSurface,
      ),
    );
  }
}
