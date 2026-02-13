import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/notes/data/repositories/note_repository.dart';
import 'features/notes/domain/note_service.dart';
import 'features/notes/presentation/screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';

/// Entry point cho ứng dụng NoteVui.
///
/// Khởi tạo theo thứ tự:
/// 1. Hive database (local storage)
/// 2. Vietnamese locale (date formatting)
/// 3. NoteService (CRUD ghi chú)
/// 4. AuthService (Dio + Interceptor + ngrok header)
/// 5. Provider: AuthProvider cho toàn bộ widget tree
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final noteService = await _initializeApp();

  runApp(NoteVuiApp(noteService: noteService));
}

/// Khởi tạo tất cả dependencies.
Future<NoteService> _initializeApp() async {
  // 0. Environment variables
  await dotenv.load(fileName: ".env");

  // 1. Hive database
  await NoteRepository.initialize();

  // 2. Vietnamese locale
  await initializeDateFormatting('vi_VN', null);

  // 3. NoteService
  final noteService = NoteService();
  await noteService.initialize();

  // 4. AuthService (singleton) — khởi tạo Dio + Interceptor
  AuthService().initialize(
    onLoginSuccess: () async {
      // Sync guest notes lên server sau khi login
      await noteService.repository.syncPendingNotes();
    },
  );

  return noteService;
}

/// Root widget — cung cấp AuthProvider cho toàn bộ app.
class NoteVuiApp extends StatelessWidget {
  final NoteService noteService;

  const NoteVuiApp({super.key, required this.noteService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Tạo AuthProvider → kiểm tra token ngay khi app khởi động
      create: (_) => AuthProvider()..checkAuthStatus(),
      child: MaterialApp(
        title: 'NoteVui',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: SplashScreen(noteService: noteService),
      ),
    );
  }
}
