import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Application theme configuration.
/// Uses Material 3 design with custom Soft UI styling.
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  /// Creates the main application theme with Nunito font and pastel colors.
  ///
  /// This theme is designed for the "Ghi Chú Việt" app with:
  /// - Nunito font family for friendly, rounded typography
  /// - Cream/off-white background for a warm feel
  /// - Soft shadows and rounded corners throughout
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.background,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
    );
  }

  /// Builds the text theme using Google Fonts Nunito.
  /// Nunito is chosen for its rounded, friendly appearance.
  static TextTheme _buildTextTheme() {
    return GoogleFonts.nunitoTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }

  /// Builds the AppBar theme with transparent background and no elevation.
  /// This creates a seamless, modern look.
  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}
