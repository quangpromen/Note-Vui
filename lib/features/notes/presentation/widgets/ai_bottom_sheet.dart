import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// A modal bottom sheet displaying AI-powered features.
///
/// Features available (in Vietnamese):
/// - Tóm tắt nội dung (Summarize content)
/// - Sửa lỗi chính tả (Fix spelling)
/// - Dịch sang tiếng Anh (Translate to English)
/// - Gợi ý ý tưởng (Suggest ideas)
class AIBottomSheet extends StatelessWidget {
  const AIBottomSheet({super.key});

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
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AIBottomSheet(),
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

  void _handleOptionTap(BuildContext context, _AIOption option) {
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
