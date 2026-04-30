import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/ai_provider.dart';
import '../../data/models/note_model.dart';
import '../../domain/note_service.dart';
import '../widgets/ai_bottom_sheet.dart';
import '../widgets/ai_grammar_bottom_sheet.dart';
import '../widgets/ai_ideas_bottom_sheet.dart';
import '../widgets/ai_translation_bottom_sheet.dart';
import 'package:provider/provider.dart';

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

  /// The note service for saving notes
  final NoteService noteService;

  const EditorScreen({super.key, this.note, required this.noteService});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  bool _isDeleting = false;

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
  void _showAIBottomSheet() async {
    final action = await AIBottomSheet.show(context);
    if (action != null && mounted) {
      _handleAIAction(action);
    }
  }

  Future<void> _handleAIAction(AIAction action) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'Bạn cần nhập nội dung để sử dụng tính năng AI!',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (action == AIAction.summarize) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final aiProvider = context.read<AiProvider>();
      await aiProvider.summarizeContent(content);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (aiProvider.state == AiProviderState.success &&
            aiProvider.lastResponse != null) {
          _showAIResultDialog(
            'Tóm tắt nội dung',
            aiProvider.lastResponse!.result ?? '',
          );
        } else if (aiProvider.state == AiProviderState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi: ${aiProvider.errorMessage}',
                style: GoogleFonts.nunito(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else if (aiProvider.state == AiProviderState.showPremiumDialog) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vui lòng nâng cấp VIP để dùng tính năng này!',
                style: GoogleFonts.nunito(),
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Nâng cấp',
                onPressed: () {},
                textColor: Colors.white,
              ),
            ),
          );
        }
      }
    } else if (action == AIAction.translate) {
      AiTranslationBottomSheet.show(
        context,
        originalContent: content,
        noteId: widget.note?.id,
        onReplace: (translatedText) {
          setState(() {
            _contentController.text = translatedText;
          });
        },
      );
    } else if (action == AIAction.suggestIdeas) {
      AiIdeasBottomSheet.show(
        context,
        originalContent: content,
        noteId: widget.note?.id,
        onAppend: (ideaText) {
          setState(() {
            final currentContent = _contentController.text;
            if (currentContent.isNotEmpty) {
              _contentController.text =
                  '$currentContent\n\n---\n💡 Ý tưởng AI:\n$ideaText';
            } else {
              _contentController.text = ideaText;
            }
          });
        },
      );
    } else if (action == AIAction.spellCheck) {
      AiGrammarBottomSheet.show(
        context,
        originalContent: content,
        noteId: widget.note?.id,
        onReplace: (correctedText) {
          setState(() {
            _contentController.text = correctedText;
          });
        },
      );
    }
  }

  void _showAIResultDialog(String title, String result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.sparkles, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(result, style: GoogleFonts.nunito(fontSize: 16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _contentController.text = result;
              });
            },
            child: Text(
              'Thay thế',
              style: GoogleFonts.nunito(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Saves the note to storage
  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Validate that at least title or content is not empty
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'Vui lòng nhập tiêu đề hoặc nội dung!',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.note != null) {
        // Update existing note
        await widget.noteService.updateNote(
          id: widget.note!.id,
          title: title.isNotEmpty ? title : 'Không có tiêu đề',
          content: content,
        );
      } else {
        // Create new note
        await widget.noteService.addNote(
          title: title.isNotEmpty ? title : 'Không có tiêu đề',
          content: content,
        );
      }

      if (mounted) {
        _showSaveConfirmation();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.xmark_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Lỗi khi lưu ghi chú!',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Shows delete confirmation dialog and deletes note if confirmed
  Future<void> _showDeleteConfirmation() async {
    if (widget.note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.trash,
                color: Colors.red.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Xóa ghi chú?',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Ghi chú này sẽ được chuyển vào thùng rác. Bạn có thể khôi phục nó trong vòng 30 ngày.',
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await widget.noteService.deleteNote(widget.note!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(CupertinoIcons.trash, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Đã chuyển vào thùng rác!',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(CupertinoIcons.xmark_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Lỗi khi xóa ghi chú!',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
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
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _buildBackButton(),
      actions: [
        // Show delete button only when editing existing note
        if (widget.note != null) ...[
          _buildDeleteButton(),
          const SizedBox(width: 8),
        ],
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
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _isDeleting ? null : _showDeleteConfirmation,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDeleting ? Colors.red.shade100 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isDeleting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.red.shade400,
                  ),
                ),
              )
            : Icon(CupertinoIcons.trash, size: 20, color: Colors.red.shade400),
      ),
    );
  }

  Widget _buildAIButton() {
    return GestureDetector(
      onTap: _showAIBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3AEFF), Color(0xFFFCD6FF)], // secondary-container to secondary-fixed
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF824790).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF753B83)), // on-secondary-container
            const SizedBox(width: 6),
            Text(
              'AI Hỗ trợ',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF753B83),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveNote,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isSaving
              ? const Color(0xFF9AE6B4).withValues(alpha: 0.5)
              : const Color(0xFF9AE6B4), // primary-container
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E6B43).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B6941)),
                    ),
                  )
                : const Icon(
                    Icons.check,
                    size: 18,
                    color: Color(0xFF1B6941), // on-primary-container
                  ),
            const SizedBox(width: 6),
            Text(
              'Lưu',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B6941),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleInput(),
                const SizedBox(height: 8),
                _buildDivider(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyModeToolbarDelegate(
            child: _buildModeToolbar(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: _buildContentInput(),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      style: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      decoration: InputDecoration(
        hintText: 'Tiêu đề ghi chú...',
        hintStyle: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint.withValues(alpha: 0.5),
          letterSpacing: -0.5,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      maxLines: null,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF9AE6B4), // primary-container
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildModeToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5EF), // surface-container-low
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 40 - 32, // screen width - body padding - container padding
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModeIcon(Icons.keyboard_outlined, true),
              _buildModeIcon(Icons.edit_outlined, false),
              _buildModeIcon(Icons.border_color_outlined, false),
              _buildModeIcon(Icons.cleaning_services_outlined, false),
              _buildModeIcon(Icons.gesture, false),
              _buildModeIcon(Icons.undo, false),
              _buildModeIcon(Icons.redo, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isActive 
        ? BoxDecoration(
            color: const Color(0xFF9AE6B4).withValues(alpha: 0.3), // primary-container/30
            shape: BoxShape.circle,
          )
        : null,
      child: Icon(
        icon,
        size: 20,
        color: isActive ? const Color(0xFF1E6B43) : const Color(0xFF404941), // primary : on-surface-variant
      ),
    );
  }

  Widget _buildContentInput() {
    return TextField(
      controller: _contentController,
      style: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: 'Viết gì đó đi...',
        hintStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      minLines: 20,
    );
  }

  Widget _buildBottomToolbar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 16, 
            right: 16, 
            top: 16, 
            bottom: MediaQuery.of(context).padding.bottom + 16
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, -4),
                blurRadius: 20,
              ),
            ],
            border: const Border(
              top: BorderSide(
                color: Color(0x1A000000), // Colors.grey.withValues(alpha: 0.1) replacement for const
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomIcon(Icons.check_box_outlined, true),
              _buildBottomIcon(Icons.palette_outlined, false),
              _buildBottomIcon(Icons.format_size, false),
              _buildBottomIcon(Icons.format_bold, false),
              _buildBottomIcon(Icons.format_align_left, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: isActive
        ? BoxDecoration(
            color: Colors.green.shade50, // bg-green-50
            shape: BoxShape.circle,
          )
        : const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
      child: Icon(
        icon,
        size: 24,
        color: isActive ? Colors.green.shade700 : Colors.grey.shade400, // text-green-700 or text-stone-400
      ),
    );
  }
}

class _StickyModeToolbarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyModeToolbarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background, // Match background so it hides text scrolling behind it
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), // padding horizontal + bottom margin
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  double get maxExtent => 76.0; // 52 (height of toolbar) + 24 (bottom padding) = 76

  @override
  double get minExtent => 76.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
