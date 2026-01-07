import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'features/notes/data/repositories/note_repository.dart';
import 'features/notes/domain/note_service.dart';
import 'features/notes/presentation/screens/splash_screen.dart';

/// Entry point for the "Ghi Chú Việt" (Viet Note) application.
///
/// This app provides a beautiful, soft UI note-taking experience
/// tailored for Vietnamese users with:
/// - Pastel color palette
/// - Nunito typography
/// - AI-powered features
/// - Staggered grid layout
/// - Hive database for unlimited storage
/// - Professional Splash Screen and Mint Green branding
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all required services in order
  await _initializeApp();

  // Create and initialize the note service
  final noteService = NoteService();
  await noteService.initialize();

  runApp(GhiChuVietApp(noteService: noteService));
}

/// Initializes all app dependencies in the correct order.
///
/// Order matters:
/// 1. Hive database (must be first for storage)
/// 2. Date formatting (for Vietnamese locale)
Future<void> _initializeApp() async {
  // Initialize Hive database and register adapters
  await NoteRepository.initialize();

  // Initialize Vietnamese locale for date formatting
  await initializeDateFormatting('vi_VN', null);
}

/// Root widget for the Ghi Chú Việt application.
///
/// Sets up the MaterialApp with:
/// - Custom Soft UI theme
/// - Vietnamese-friendly fonts
/// - Green/Mint color scheme
class GhiChuVietApp extends StatelessWidget {
  final NoteService noteService;

  const GhiChuVietApp({super.key, required this.noteService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghi Chú Việt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(noteService: noteService),
    );
  }
}
