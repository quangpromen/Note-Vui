import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/auth/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/notes/data/repositories/note_repository.dart';
import 'features/notes/domain/note_service.dart';
import 'features/notes/presentation/screens/splash_screen.dart';
import 'providers/ai_provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';

/// Entry point cho ứng dụng NoteVui.
///
/// Khởi tạo theo thứ tự:
/// 1. Hive database (local storage)
/// 2. Vietnamese locale (date formatting)
/// 3. NoteService (CRUD ghi chú)
/// 4. AuthService (Dio + Interceptor + ngrok header)
/// 5. SessionManager (auto-logout khi token hết hạn)
/// 6. Provider: AuthProvider cho toàn bộ widget tree
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
///
/// Sử dụng [navigatorKey] global để [SessionManager] có thể
/// navigate đến LoginScreen từ bất kỳ service layer nào khi token hết hạn.
class NoteVuiApp extends StatefulWidget {
  final NoteService noteService;

  const NoteVuiApp({super.key, required this.noteService});

  @override
  State<NoteVuiApp> createState() => _NoteVuiAppState();
}

class _NoteVuiAppState extends State<NoteVuiApp> {
  /// Global navigator key — cho phép navigate từ service layer
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupSessionManager();
  }

  /// Setup SessionManager để auto-logout khi token hết hạn.
  ///
  /// Khi [AuthInterceptor] phát hiện refresh token thất bại:
  /// 1. SessionManager xóa token
  /// 2. Callback ở đây navigate về LoginScreen
  /// 3. Hiển thị SnackBar thông báo
  void _setupSessionManager() {
    final sessionManager = SessionManager();
    sessionManager.setNavigatorKey(_navigatorKey);

    sessionManager.onSessionExpired = () {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;

      // 1. Navigate về LoginScreen, xóa toàn bộ stack
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(noteService: widget.noteService),
        ),
        (route) => false,
      );

      // 2. Hiển thị thông báo phiên hết hạn
      // Dùng WidgetsBinding để chờ frame hoàn tất rồi mới show SnackBar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scaffoldMessenger =
            _navigatorKey.currentState?.overlay?.context != null
            ? ScaffoldMessenger.maybeOf(
                _navigatorKey.currentState!.overlay!.context,
              )
            : null;

        scaffoldMessenger?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Tạo AuthProvider → kiểm tra token ngay khi app khởi động
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        // Provider quản lý AI Summarize
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'NoteVui',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: SplashScreen(noteService: widget.noteService),
      ),
    );
  }
}
