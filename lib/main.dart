import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'features/notes/presentation/screens/home_screen.dart';

/// Entry point for the "Ghi Chú Việt" (Viet Note) application.
///
/// This app provides a beautiful, soft UI note-taking experience
/// tailored for Vietnamese users with:
/// - Pastel color palette
/// - Nunito typography
/// - AI-powered features
/// - Staggered grid layout
void main() {
  // Initialize Vietnamese locale for date formatting
  initializeDateFormatting('vi_VN', null).then((_) {
    runApp(const GhiChuVietApp());
  });
}

/// Root widget for the Ghi Chú Việt application.
///
/// Sets up the MaterialApp with:
/// - Custom Soft UI theme
/// - Vietnamese-friendly fonts
/// - Pastel color scheme
class GhiChuVietApp extends StatelessWidget {
  const GhiChuVietApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghi Chú Việt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
