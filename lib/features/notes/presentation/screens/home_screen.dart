import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../../../services/auth_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../data/models/note_model.dart';
import '../../domain/note_service.dart';
import '../widgets/ai_bottom_sheet.dart';
import '../widgets/note_card.dart';
import '../widgets/note_skeleton.dart';
import '../widgets/soft_fab.dart';
import '../widgets/soft_search_bar.dart';
import 'editor_screen.dart';

/// Home screen displaying the notes grid with search functionality.
///
/// Features:
/// - Dynamic greeting based on time of day
/// - Floating search bar with filtering
/// - Staggered/Masonry grid layout for notes
/// - FAB for creating new notes
/// - **Sync button** (gated for guests)
/// - **AI button** (gated for guests)
class HomeScreen extends StatefulWidget {
  final NoteService noteService;

  const HomeScreen({super.key, required this.noteService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Listen for changes in NoteService
    widget.noteService.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    widget.noteService.removeListener(_onNotesChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    // Rebuild when notes change
    setState(() {});
  }

  /// Gets filtered notes based on search query
  List<NoteModel> get _filteredNotes {
    final notes = widget.noteService.notes;
    if (_searchQuery.isEmpty) {
      return notes;
    }
    return notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              note.content.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  /// Filters notes based on search query (searches in title and content)
  void _filterNotes(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// Returns a greeting message based on the current time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng! ☀️';
    } else if (hour < 18) {
      return 'Chào buổi chiều! 🌤️';
    } else {
      return 'Chào buổi tối! 🌙';
    }
  }

  /// Navigates to the editor screen
  void _navigateToEditor([NoteModel? note]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditorScreen(note: note, noteService: widget.noteService),
      ),
    );
  }

  /// Navigates to login screen
  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginScreen(noteService: widget.noteService),
      ),
      (route) => false,
    );
  }

  /// Handles logout action
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Hủy',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthProvider>().logout();
      _navigateToLogin();
    }
  }

  /// Handles sync button press
  Future<void> _handleSync() async {
    // Check if user is logged in
    final isLoggedIn = await AuthService().isLoggedIn();

    if (!mounted) return;

    if (!isLoggedIn) {
      // Show guest dialog
      _showGuestDialog(
        title: 'Đồng bộ dữ liệu',
        content: 'Bạn cần đăng nhập để đồng bộ ghi chú lên đám mây.',
      );
      return;
    }

    // User is logged in - perform sync
    setState(() => _isSyncing = true);

    try {
      await widget.noteService.repository.syncPendingNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'Đồng bộ thành công!',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đồng bộ thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  /// Handles AI button press
  void _handleAI() {
    AIBottomSheet.show(context, onNavigateToLogin: _navigateToLogin);
  }

  /// Shows a dialog prompting guests to login
  void _showGuestDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.cloud_upload,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Hủy',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _navigateToLogin();
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Đăng nhập ngay',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with greeting and action buttons
            _buildHeader(),

            // Search Bar
            _buildSearchBar(),

            // Notes Grid
            _buildNotesGrid(),

            // Bottom spacing for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: SoftFab(onPressed: () => _navigateToEditor()),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hôm nay bạn muốn ghi chú gì nào?',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons (Sync & AI)
            Row(
              children: [
                // Sync button
                _buildActionButton(
                  icon: _isSyncing
                      ? CupertinoIcons.arrow_2_circlepath
                      : CupertinoIcons.cloud_upload,
                  color: AppColors.aiSummarize,
                  backgroundColor: AppColors.aiSummarizeBg,
                  onTap: _isSyncing ? null : _handleSync,
                  isLoading: _isSyncing,
                  tooltip: 'Sao lưu',
                ),
                const SizedBox(width: 8),

                // AI button
                _buildActionButton(
                  icon: CupertinoIcons.sparkles,
                  color: Colors.purple,
                  backgroundColor: Colors.purple.shade50,
                  onTap: _handleAI,
                  tooltip: 'AI Hỗ trợ',
                ),
                const SizedBox(width: 8),

                // Logout button (Only show when logged in)
                if (context.watch<AuthProvider>().isLoggedIn) ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: CupertinoIcons.power,
                    color: Colors.red,
                    backgroundColor: Colors.red.shade50,
                    onTap: _handleLogout,
                    tooltip: 'Đăng xuất',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback? onTap,
    bool isLoading = false,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SoftSearchBar(
          controller: _searchController,
          onChanged: _filterNotes,
        ),
      ),
    );
  }

  Widget _buildNotesGrid() {
    final notes = _filteredNotes;
    final isLoading = widget.noteService.isLoading;

    if (isLoading && notes.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childCount: 6, // Show 6 skeleton items
          itemBuilder: (context, index) => const NoteSkeleton(),
        ),
      );
    }

    if (notes.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(
                  Icons.note_add_outlined,
                  size: 64,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'Chưa có ghi chú nào.\nHãy tạo ghi chú đầu tiên!'
                      : 'Không tìm thấy ghi chú phù hợp.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(note: note, onTap: () => _navigateToEditor(note));
        },
      ),
    );
  }
}
