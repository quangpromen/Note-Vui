import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';

/// A modal bottom sheet displaying AI-powered features.
///
/// Features available (in Vietnamese):
/// - Tóm tắt nội dung (Summarize content)
/// - Sửa lỗi chính tả (Fix spelling)
/// - Dịch sang tiếng Anh (Translate to English)
/// - Gợi ý ý tưởng (Suggest ideas)
///
/// **Feature Gating:**
/// - If user is logged in: Proceeds with AI call
/// - If Guest: Shows dialog prompting to login
class AIBottomSheet extends StatelessWidget {
  /// Optional callback to navigate to login screen
  final VoidCallback? onNavigateToLogin;

  const AIBottomSheet({super.key, this.onNavigateToLogin});

  /// List of AI options with their icons, titles, and colors
  static final List<_AIOption> _options = [
    _AIOption(
      icon: CupertinoIcons.doc_text_search,
      title: 'Tóm tắt nội dung',
      subtitle: 'Rút gọn văn bản thành ý chính',
      backgroundColor: AppColors.aiSummarizeBg,
      iconColor: AppColors.aiSummarize,
    ),
    _AIOption(
      icon: CupertinoIcons.textformat_abc,
      title: 'Sửa lỗi chính tả',
      subtitle: 'Kiểm tra và sửa lỗi tự động',
      backgroundColor: AppColors.aiSpellCheckBg,
      iconColor: AppColors.aiSpellCheck,
    ),
    _AIOption(
      icon: CupertinoIcons.globe,
      title: 'Dịch sang tiếng Anh',
      subtitle: 'Chuyển đổi ngôn ngữ nhanh chóng',
      backgroundColor: AppColors.aiTranslateBg,
      iconColor: AppColors.aiTranslate,
    ),
    _AIOption(
      icon: CupertinoIcons.lightbulb,
      title: 'Gợi ý ý tưởng',
      subtitle: 'Mở rộng và phát triển nội dung',
      backgroundColor: AppColors.aiIdeasBg,
      iconColor: AppColors.aiIdeas,
    ),
  ];

  /// Shows the AI bottom sheet modal
  static void show(BuildContext context, {VoidCallback? onNavigateToLogin}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AIBottomSheet(onNavigateToLogin: onNavigateToLogin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          _buildHandleBar(),

          // Header
          _buildHeader(),

          // Options list
          _buildOptionsList(context),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // AI icon with gradient background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade100, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Colors.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Hỗ trợ',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Chọn tính năng bạn muốn sử dụng',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: _options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AIOptionTile(
              option: option,
              onTap: () => _handleOptionTap(context, option),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleOptionTap(BuildContext context, _AIOption option) async {
    // Check if user is logged in before allowing AI features
    final isLoggedIn = await AuthService().isLoggedIn();

    if (!context.mounted) return;

    if (!isLoggedIn) {
      // Show feature gating dialog for guests
      _showGuestDialog(context);
      return;
    }

    // User is logged in - proceed with AI feature
    Navigator.pop(context);

    // Show a demo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.sparkles, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Đang xử lý: ${option.title}...',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: option.iconColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a dialog prompting guests to login for premium features
  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.sparkles,
                color: Colors.purple.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Tính năng cao cấp',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn cần đăng nhập để sử dụng AI và đồng bộ dữ liệu.',
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
              Navigator.of(dialogContext).pop(); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              // Navigate to login screen if callback provided
              if (onNavigateToLogin != null) {
                onNavigateToLogin!();
              }
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
}

/// Data class for AI option configuration
class _AIOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;

  const _AIOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
  });
}

/// A single option tile in the AI bottom sheet
class _AIOptionTile extends StatelessWidget {
  final _AIOption option;
  final VoidCallback onTap;

  const _AIOptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: option.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: option.iconColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: option.iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(option.icon, color: option.iconColor, size: 22),
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              CupertinoIcons.chevron_right,
              color: option.iconColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
