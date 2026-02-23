import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/ai_provider.dart';

/// BottomSheet hiển thị kết quả "Sửa lỗi ngữ pháp & chính tả bằng AI".
///
/// Flow:
/// 1. Mở sheet → tự động gọi API grammar
/// 2. Hiển thị shimmer loading trong lúc chờ
/// 3. Khi thành công: hiện so sánh "Bản gốc" vs "Bản đã sửa" + 3 nút (Thay thế / Copy / Đóng)
/// 4. Khi lỗi 403: hiện Dialog nâng cấp VIP
/// 5. Khi lỗi khác: hiện thông báo lỗi + nút Thử lại
class AiGrammarBottomSheet extends StatefulWidget {
  final String originalContent;
  final Function(String) onReplace;
  final String? noteId;

  const AiGrammarBottomSheet({
    super.key,
    required this.originalContent,
    required this.onReplace,
    this.noteId,
  });

  /// Hiện BottomSheet sửa ngữ pháp
  static void show(
    BuildContext context, {
    required String originalContent,
    required Function(String) onReplace,
    String? noteId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AiGrammarBottomSheet(
        originalContent: originalContent,
        onReplace: onReplace,
        noteId: noteId,
      ),
    );
  }

  @override
  State<AiGrammarBottomSheet> createState() => _AiGrammarBottomSheetState();
}

class _AiGrammarBottomSheetState extends State<AiGrammarBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Reset state và tự động gọi API ngay khi mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = context.read<AiProvider>();
      aiProvider.resetState();
      aiProvider.fixGrammarContent(
        widget.originalContent,
        noteId: widget.noteId,
      );
    });
  }

  void _copyAndClose(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Đã sao chép vào bộ nhớ tạm!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _replaceAndClose(String text) {
    widget.onReplace(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Đã thay thế nội dung bằng bản đã sửa!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.aiSpellCheck,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _showPremiumDialog() {
    Navigator.pop(context); // Đóng bottom sheet hiện tại
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade50,
                Colors.orange.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crown icon với hiệu ứng nổi bật
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade300, Colors.orange.shade400],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.star_fill,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nâng cấp Premium',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tính năng sửa ngữ pháp AI chỉ dành riêng cho thành viên VIP. '
                  'Nâng cấp ngay để mở khoá toàn bộ sức mạnh AI!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Các ưu điểm VIP
                _buildVipBenefit(
                  CupertinoIcons.textformat_abc,
                  'Sửa ngữ pháp & chính tả không giới hạn',
                ),
                _buildVipBenefit(
                  CupertinoIcons.globe,
                  'Dịch thuật AI nâng cao',
                ),
                _buildVipBenefit(
                  CupertinoIcons.sparkles,
                  'Tóm tắt & gợi ý ý tưởng thông minh',
                ),
                const SizedBox(height: 24),
                // Nút nâng cấp
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.amber.withValues(alpha: 0.4),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Điều hướng đến trang thanh toán / nâng cấp VIP
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đang chuyển đến trang nâng cấp...',
                            style: GoogleFonts.nunito(),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.star_fill, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Nâng cấp ngay',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Nút đóng
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Để sau',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVipBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.amber.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe state từ Provider
    final aiProvider = context.watch<AiProvider>();
    final state = aiProvider.state;

    // Nếu có lỗi VIP -> Hiển thị popup VIP và pop luôn BottomSheet hiện tại
    if (state == AiProviderState.showPremiumDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPremiumDialog();
        aiProvider.resetState();
      });
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          _buildHeader(),

          // Content (Loading / Success / Error)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildContent(state, aiProvider),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Icon với gradient xanh mint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.aiSpellCheckBg,
                  AppColors.aiSpellCheck.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.textformat_abc,
              color: AppColors.aiSpellCheck,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✏️ Sửa ngữ pháp',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Kiểm tra và sửa lỗi chính tả tự động',
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

  Widget _buildContent(AiProviderState state, AiProvider provider) {
    switch (state) {
      case AiProviderState.loading:
        return _buildLoadingShimmer();
      case AiProviderState.success:
        final result = provider.lastResponse?.result ?? '';
        return _buildSuccessResult(result);
      case AiProviderState.error:
        return _buildError(provider.errorMessage ?? 'Có lỗi xảy ra.');
      case AiProviderState.initial:
      default:
        return _buildLoadingShimmer(); // Khi vừa mở đã gọi API rồi
    }
  }

  Widget _buildLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.aiSpellCheck,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI đang kiểm tra ngữ pháp...',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.aiSpellCheck,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Shimmer placeholder lines
        Shimmer.fromColors(
          baseColor: AppColors.aiSpellCheck.withValues(alpha: 0.15),
          highlightColor: AppColors.aiSpellCheckBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerLine(double.infinity),
              const SizedBox(height: 12),
              _shimmerLine(MediaQuery.of(context).size.width * 0.85),
              const SizedBox(height: 12),
              _shimmerLine(MediaQuery.of(context).size.width * 0.92),
              const SizedBox(height: 12),
              _shimmerLine(MediaQuery.of(context).size.width * 0.7),
              const SizedBox(height: 12),
              _shimmerLine(MediaQuery.of(context).size.width * 0.78),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shimmerLine(double width) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildError(String errorMsg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Colors.red.shade400,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Đã xảy ra lỗi',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.red.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorMsg,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Đóng',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aiSpellCheck,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                final aiProvider = context.read<AiProvider>();
                aiProvider.resetState();
                aiProvider.fixGrammarContent(
                  widget.originalContent,
                  noteId: widget.noteId,
                );
              },
              icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 16),
              label: Text(
                'Thử lại',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessResult(String correctedText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Bản gốc ───
        _buildTextSection(
          icon: CupertinoIcons.doc_text,
          label: 'Bản gốc',
          labelColor: AppColors.textSecondary,
          bgColor: Colors.grey.shade50,
          borderColor: Colors.grey.shade200,
          text: widget.originalContent,
        ),
        const SizedBox(height: 16),

        // ─── Bản đã sửa ───
        _buildTextSection(
          icon: CupertinoIcons.checkmark_seal_fill,
          label: 'Bản đã sửa',
          labelColor: AppColors.aiSpellCheck,
          bgColor: AppColors.aiSpellCheckBg,
          borderColor: AppColors.aiSpellCheck.withValues(alpha: 0.3),
          text: correctedText,
        ),

        const SizedBox(height: 8),
        // Token info
        if (context.read<AiProvider>().lastResponse != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Quota còn lại: ${context.read<AiProvider>().lastResponse!.remainingQuota}',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ),
        const SizedBox(height: 16),

        // ─── 3 nút hành động ───
        Row(
          children: [
            // Nút Đóng
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Đóng',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Nút Copy
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: AppColors.aiSpellCheck.withValues(alpha: 0.5),
                  ),
                ),
                onPressed: () => _copyAndClose(correctedText),
                icon: Icon(
                  CupertinoIcons.doc_on_clipboard,
                  size: 16,
                  color: AppColors.aiSpellCheck,
                ),
                label: Text(
                  'Copy',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: AppColors.aiSpellCheck,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Nút Thay thế
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.aiSpellCheck,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.aiSpellCheck.withValues(alpha: 0.3),
                ),
                onPressed: () => _replaceAndClose(correctedText),
                icon: const Icon(
                  CupertinoIcons.arrow_right_arrow_left,
                  size: 16,
                ),
                label: Text(
                  'Thay thế',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Widget helper tạo section hiển thị văn bản (Bản gốc / Bản đã sửa)
  Widget _buildTextSection({
    required IconData icon,
    required String label,
    required Color labelColor,
    required Color bgColor,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: labelColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            text,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
