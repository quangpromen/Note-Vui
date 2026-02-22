import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/note_model.dart';
import '../../domain/note_service.dart';
import '../widgets/note_card.dart';

class TrashScreen extends StatefulWidget {
  final NoteService noteService;

  const TrashScreen({super.key, required this.noteService});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    widget.noteService.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    widget.noteService.removeListener(_onNotesChanged);
    super.dispose();
  }

  void _onNotesChanged() {
    setState(() {});
  }

  Future<void> _handleEmptyTrash() async {
    final shouldEmpty = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Dọn dẹp thùng rác',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Tất cả các ghi chú trong thùng rác sẽ bị xóa vĩnh viễn và không thể khôi phục. Bạn chắc chắn chứ?',
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
              'Xóa tất cả',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldEmpty == true && mounted) {
      final success = await widget.noteService.emptyTrash();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã dọn dẹp thùng rác.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showNoteOptions(NoteModel note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final daysLeft = note.deletedAt != null
            ? 30 - DateTime.now().difference(note.deletedAt!).inDays
            : 30;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Còn $daysLeft ngày trước khi xóa vĩnh viễn',
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.arrow_counterclockwise,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Khôi phục ghi chú',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final success = await widget.noteService.restoreNote(
                      note.id,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã khôi phục ghi chú.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.delete, color: Colors.red),
                  title: Text(
                    'Xóa vĩnh viễn',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final success = await widget.noteService
                        .permanentlyDeleteNote(note.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã xóa vĩnh viễn.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trashNotes = widget.noteService.trashNotes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thùng rác',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (trashNotes.isNotEmpty)
            TextButton.icon(
              onPressed: _handleEmptyTrash,
              icon: const Icon(
                CupertinoIcons.trash,
                color: Colors.red,
                size: 20,
              ),
              label: Text(
                'Dọn dẹp',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
      body: trashNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.trash,
                    size: 64,
                    color: AppColors.textHint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thùng rác trống',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childCount: trashNotes.length,
                    itemBuilder: (context, index) {
                      final note = trashNotes[index];
                      // We'll wrap the Normal NoteCard in a GestureDetector,
                      // or just pass a callback if NoteCard supports onTap.
                      return NoteCard(
                        note: note,
                        onTap: () => _showNoteOptions(note),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
