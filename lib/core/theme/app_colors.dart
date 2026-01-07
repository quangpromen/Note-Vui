import 'package:flutter/material.dart';

/// Application color palette following Soft UI / Pastel design principles.
/// All colors are carefully selected to create a "Chữa lành" (Healing) aesthetic.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  /// Main background color - Off-white/Cream for a warm, soft feel
  static const Color background = Color(0xFFFFFDF5);

  /// Card background - Pure white for contrast against cream background
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text color - Dark grey instead of pure black for softer appearance
  static const Color textPrimary = Color(0xFF333333);

  /// Secondary text color - Medium grey for subtitles and descriptions
  static const Color textSecondary = Color(0xFF666666);

  /// Hint text color - Light grey for placeholders and disabled text
  static const Color textHint = Color(0xFF999999);

  // ============================================================================
  // PASTEL ACCENT COLORS (For Note Cards)
  // ============================================================================

  /// Collection of pastel colors used for note card backgrounds
  /// Each color creates a unique, calming visual identity for notes
  static const List<Color> pastelColors = [
    Color(0xFFE8F4FD), // Soft Blue - Calm, trustworthy
    Color(0xFFE8FDF5), // Mint Green - Fresh, natural
    Color(0xFFFDE8F4), // Pastel Pink - Warm, friendly
    Color(0xFFFDF5E8), // Warm Yellow - Happy, energetic
    Color(0xFFF0E8FD), // Soft Lavender - Creative, peaceful
    Color(0xFFFDE8E8), // Soft Coral - Gentle, welcoming
    Color(0xFFE8FDFD), // Soft Cyan - Clear, refreshing
    Color(0xFFFDFDE8), // Soft Lemon - Bright, optimistic
  ];

  // ============================================================================
  // PRIMARY ACCENT COLORS
  // ============================================================================

  /// Primary accent color - Soft mint green from logo
  static const Color primary = Color(0xFF96E6A1);

  /// Primary light variant - For hover states and backgrounds
  static const Color primaryLight = Color(0xFFD4F5DA);

  // ============================================================================
  // FAB (Floating Action Button) GRADIENT COLORS
  // ============================================================================

  /// FAB gradient start color - Mint Green
  static const Color fabStart = Color(0xFFA8E6CF);

  /// FAB gradient end color - Soft Green
  static const Color fabEnd = Color(0xFF96E6A1);

  // ============================================================================
  // AI FEATURE COLORS
  // ============================================================================

  /// AI option: Summarize - Soft blue theme
  static const Color aiSummarize = Color(0xFF4A90D9);
  static const Color aiSummarizeBg = Color(0xFFE8F4FD);

  /// AI option: Spell check - Mint green theme
  static const Color aiSpellCheck = Color(0xFF4AD990);
  static const Color aiSpellCheckBg = Color(0xFFE8FDF5);

  /// AI option: Translate - Pastel pink theme
  static const Color aiTranslate = Color(0xFFD94A90);
  static const Color aiTranslateBg = Color(0xFFFDE8F4);

  /// AI option: Ideas - Warm yellow theme
  static const Color aiIdeas = Color(0xFFD9A04A);
  static const Color aiIdeasBg = Color(0xFFFDF5E8);
}
