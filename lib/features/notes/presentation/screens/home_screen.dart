import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dummy_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/note_model.dart';
import '../widgets/note_card.dart';
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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<NoteModel> _filteredNotes = DummyData.notes;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filters notes based on search query (searches in title and content)
  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = DummyData.notes;
      } else {
        _filteredNotes = DummyData.notes
            .where(
              (note) =>
                  note.title.toLowerCase().contains(query.toLowerCase()) ||
                  note.content.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
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
  void _navigateToEditor([NoteModel? note]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorScreen(note: note)),
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childCount: _filteredNotes.length,
        itemBuilder: (context, index) {
          final note = _filteredNotes[index];
          return NoteCard(note: note, onTap: () => _navigateToEditor(note));
        },
      ),
    );
  }
}
