import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/note_model.dart';
import '../widgets/ai_bottom_sheet.dart';

/// Note editor screen for creating and editing notes.
///
/// Features:
/// - Large title input field
/// - Content area with comfortable line height
/// - AI support button with bottom sheet
/// - Save button with confirmation feedback
class EditorScreen extends StatefulWidget {
  /// Optional note to edit. If null, creates a new note.
  final NoteModel? note;

  const EditorScreen({super.key, this.note});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Shows the AI support bottom sheet
  void _showAIBottomSheet() {
    AIBottomSheet.show(context);
  }

  /// Shows a save confirmation snackbar
  void _showSaveConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              'Đã lưu ghi chú thành công!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: _buildBackButton(),
      actions: [
        _buildAIButton(),
        const SizedBox(width: 12),
        _buildSaveButton(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.back,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildAIButton() {
    return GestureDetector(
      onTap: _showAIBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.blue.shade100],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.sparkles, size: 18, color: Colors.purple),
            const SizedBox(width: 6),
            Text(
              'AI Hỗ trợ',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.purple.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _showSaveConfirmation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.checkmark_alt,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'Lưu',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleInput(),
          const SizedBox(height: 8),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildContentInput(),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      style: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Tiêu đề ghi chú...',
        hintStyle: GoogleFonts.nunito(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textHint.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
      ),
      maxLines: null,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 3,
      width: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.fabStart, AppColors.fabEnd],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContentInput() {
    return TextField(
      controller: _contentController,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.8,
      ),
      decoration: InputDecoration(
        hintText: 'Viết gì đó đi...',
        hintStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
      ),
      maxLines: null,
      minLines: 20,
    );
  }
}
