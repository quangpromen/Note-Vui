import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/note_model.dart';
import '../../domain/note_service.dart';
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
class HomeScreen extends StatefulWidget {
  final NoteService noteService;

  const HomeScreen({super.key, required this.noteService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with greeting
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
