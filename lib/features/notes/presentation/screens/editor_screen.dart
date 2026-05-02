import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/ai_provider.dart';
import '../../data/models/note_model.dart';
import '../../domain/note_service.dart';
import '../controllers/drawing_toolbar_controller.dart';
import '../widgets/ai_bottom_sheet.dart';
import '../widgets/ai_grammar_bottom_sheet.dart';
import '../widgets/ai_ideas_bottom_sheet.dart';
import '../widgets/ai_translation_bottom_sheet.dart';
import '../widgets/bottom_formatting_toolbar.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/drawing_toolbar.dart';

// =============================================================================
// Design tokens local to this screen
// =============================================================================

/// Colors used exclusively within the editor screen widgets.
abstract final class _EditorColors {
  // AppBar buttons
  static const Color aiGradientStart = Color(0xFFF3AEFF);
  static const Color aiGradientEnd = Color(0xFFFCD6FF);
  static const Color aiText = Color(0xFF753B83);
  static const Color aiShadow = Color(0xFF824790);

  static const Color saveBackground = Color(0xFF9AE6B4);
  static const Color saveText = Color(0xFF1B6941);
  static const Color saveShadow = Color(0xFF1E6B43);

  // Divider accent
  static const Color dividerAccent = Color(0xFF9AE6B4);
}

// =============================================================================
// EditorScreen — Public API
// =============================================================================

/// Full-screen note editor for creating and editing notes.
///
/// Provides a title field, rich content area, drawing toolbar,
/// AI assistant integration, and bottom formatting toolbar.
class EditorScreen extends StatefulWidget {
  /// If non-null the editor opens in *edit* mode; otherwise *create* mode.
  final NoteModel? note;

  /// Service used to persist notes.
  final NoteService noteService;

  const EditorScreen({super.key, this.note, required this.noteService});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

// =============================================================================
// _EditorScreenState
// =============================================================================

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final DrawingToolbarController _toolbarController;

  bool _isSaving = false;
  bool _isDeleting = false;

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  bool get _isEditMode => widget.note != null;
  String get _defaultTitle => 'Không có tiêu đề';

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _toolbarController = DrawingToolbarController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _toolbarController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Snackbar helpers (DRY — eliminates repeated SnackBar boilerplate)
  // ---------------------------------------------------------------------------

  void _showIconSnackBar({
    required IconData icon,
    required String message,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    _showIconSnackBar(
      icon: CupertinoIcons.exclamationmark_circle,
      message: message,
      backgroundColor: Colors.orange,
    );
  }

  void _showErrorSnackBar(String message) {
    _showIconSnackBar(
      icon: CupertinoIcons.xmark_circle,
      message: message,
      backgroundColor: Colors.red,
    );
  }

  void _showSuccessSnackBar(String message) {
    _showIconSnackBar(
      icon: CupertinoIcons.checkmark_circle_fill,
      message: message,
      backgroundColor: AppColors.primary,
    );
  }

  // ---------------------------------------------------------------------------
  // AI actions
  // ---------------------------------------------------------------------------

  Future<void> _showAIBottomSheet() async {
    final action = await AIBottomSheet.show(context);
    if (action != null && mounted) {
      await _handleAIAction(action);
    }
  }

  Future<void> _handleAIAction(AIAction action) async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      _showWarningSnackBar('Bạn cần nhập nội dung để sử dụng tính năng AI!');
      return;
    }

    switch (action) {
      case AIAction.summarize:
        await _handleSummarize(content);
      case AIAction.translate:
        _handleTranslate(content);
      case AIAction.suggestIdeas:
        _handleSuggestIdeas(content);
      case AIAction.spellCheck:
        _handleSpellCheck(content);
    }
  }

  Future<void> _handleSummarize(String content) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final aiProvider = context.read<AiProvider>();
    await aiProvider.summarizeContent(content);

    if (!mounted) return;
    Navigator.pop(context);

    switch (aiProvider.state) {
      case AiProviderState.success when aiProvider.lastResponse != null:
        _showAIResultDialog(
          'Tóm tắt nội dung',
          aiProvider.lastResponse!.result ?? '',
        );
      case AiProviderState.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: ${aiProvider.errorMessage}',
              style: GoogleFonts.nunito(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      case AiProviderState.showPremiumDialog:
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
      default:
        break;
    }
  }

  void _handleTranslate(String content) {
    AiTranslationBottomSheet.show(
      context,
      originalContent: content,
      noteId: widget.note?.id,
      onReplace: (translatedText) {
        setState(() => _contentController.text = translatedText);
      },
    );
  }

  void _handleSuggestIdeas(String content) {
    AiIdeasBottomSheet.show(
      context,
      originalContent: content,
      noteId: widget.note?.id,
      onAppend: (ideaText) {
        setState(() {
          final current = _contentController.text;
          _contentController.text = current.isNotEmpty
              ? '$current\n\n---\n💡 Ý tưởng AI:\n$ideaText'
              : ideaText;
        });
      },
    );
  }

  void _handleSpellCheck(String content) {
    AiGrammarBottomSheet.show(
      context,
      originalContent: content,
      noteId: widget.note?.id,
      onReplace: (correctedText) {
        setState(() => _contentController.text = correctedText);
      },
    );
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
              setState(() => _contentController.text = result);
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

  // ---------------------------------------------------------------------------
  // CRUD actions
  // ---------------------------------------------------------------------------

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      _showWarningSnackBar('Vui lòng nhập tiêu đề hoặc nội dung!');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final resolvedTitle = title.isNotEmpty ? title : _defaultTitle;

      if (_isEditMode) {
        await widget.noteService.updateNote(
          id: widget.note!.id,
          title: resolvedTitle,
          content: content,
        );
      } else {
        await widget.noteService.addNote(
          title: resolvedTitle,
          content: content,
        );
      }

      if (mounted) {
        _showSuccessSnackBar('Đã lưu ghi chú thành công!');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar('Lỗi khi lưu ghi chú!');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteNote() async {
    if (!_isEditMode) return;

    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await widget.noteService.deleteNote(widget.note!.id);
      if (mounted) {
        _showIconSnackBar(
          icon: CupertinoIcons.trash,
          message: 'Đã chuyển vào thùng rác!',
          backgroundColor: Colors.red.shade400,
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar('Lỗi khi xóa ghi chú!');
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
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
          'Ghi chú này sẽ được chuyển vào thùng rác. '
          'Bạn có thể khôi phục nó trong vòng 30 ngày.',
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
  }

  // ---------------------------------------------------------------------------
  // Build — root
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildScrollableBody()),
          const BottomFormattingToolbar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build — AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _EditorBackButton(onPressed: () => Navigator.pop(context)),
      actions: [
        if (_isEditMode) ...[
          _EditorDeleteButton(
            isDeleting: _isDeleting,
            onTap: _deleteNote,
          ),
          const SizedBox(width: 8),
        ],
        _EditorAIButton(onTap: _showAIBottomSheet),
        const SizedBox(width: 12),
        _EditorSaveButton(isSaving: _isSaving, onTap: _saveNote),
        const SizedBox(width: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build — Body
  // ---------------------------------------------------------------------------

  Widget _buildScrollableBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EditorTitleField(controller: _titleController),
                const SizedBox(height: 8),
                const _EditorDivider(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyToolbarDelegate(
            child: DrawingToolbar(controller: _toolbarController),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: DrawingCanvas(
              controller: _toolbarController,
              child: _EditorContentField(controller: _contentController),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Private extracted widgets — AppBar buttons
// =============================================================================

class _EditorBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditorBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
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
    );
  }
}

class _EditorDeleteButton extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onTap;

  const _EditorDeleteButton({
    required this.isDeleting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDeleting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDeleting ? Colors.red.shade100 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isDeleting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                ),
              )
            : Icon(CupertinoIcons.trash, size: 20, color: Colors.red.shade400),
      ),
    );
  }
}

class _EditorAIButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditorAIButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_EditorColors.aiGradientStart, _EditorColors.aiGradientEnd],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: _EditorColors.aiShadow.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: _EditorColors.aiText),
            const SizedBox(width: 6),
            Text(
              'AI Hỗ trợ',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _EditorColors.aiText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onTap;

  const _EditorSaveButton({required this.isSaving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSaving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSaving
              ? _EditorColors.saveBackground.withValues(alpha: 0.5)
              : _EditorColors.saveBackground,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: _EditorColors.saveShadow.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _EditorColors.saveText,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.check,
                    size: 18,
                    color: _EditorColors.saveText,
                  ),
            const SizedBox(width: 6),
            Text(
              'Lưu',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _EditorColors.saveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Private extracted widgets — Editor body
// =============================================================================

class _EditorTitleField extends StatelessWidget {
  final TextEditingController controller;

  const _EditorTitleField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
}

class _EditorDivider extends StatelessWidget {
  const _EditorDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: _EditorColors.dividerAccent,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _EditorContentField extends StatelessWidget {
  final TextEditingController controller;

  const _EditorContentField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
}

// =============================================================================
// Sliver delegate — sticky drawing toolbar
// =============================================================================

/// Keeps the [DrawingToolbar] pinned at the top when the user scrolls.
class _StickyToolbarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyToolbarDelegate({required this.child});

  static const double _height = 76.0; // 52 (toolbar) + 24 (bottom padding)

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyToolbarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
