import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'features/notes/domain/note_service.dart';
import 'features/notes/presentation/screens/home_screen.dart';

/// Entry point for the "Ghi Chú Việt" (Viet Note) application.
///
/// This app provides a beautiful, soft UI note-taking experience
/// tailored for Vietnamese users with:
/// - Pastel color palette
/// - Nunito typography
/// - AI-powered features
/// - Staggered grid layout
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Vietnamese locale for date formatting
  await initializeDateFormatting('vi_VN', null);

  // Initialize the note service and load existing notes
  final noteService = NoteService();
  await noteService.initialize();

  runApp(GhiChuVietApp(noteService: noteService));
}

/// Root widget for the Ghi Chú Việt application.
///
/// Sets up the MaterialApp with:
/// - Custom Soft UI theme
/// - Vietnamese-friendly fonts
/// - Pastel color scheme
class GhiChuVietApp extends StatelessWidget {
  final NoteService noteService;

  const GhiChuVietApp({super.key, required this.noteService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghi Chú Việt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomeScreen(noteService: noteService),
    );
  }
}
