import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/ai_provider.dart';

class AiTranslationBottomSheet extends StatefulWidget {
  final String originalContent;
  final Function(String) onReplace;
  final String? noteId;

  const AiTranslationBottomSheet({
    super.key,
    required this.originalContent,
    required this.onReplace,
    this.noteId,
  });

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
      builder: (context) => AiTranslationBottomSheet(
        originalContent: originalContent,
        onReplace: onReplace,
        noteId: noteId,
      ),
    );
  }

  @override
  State<AiTranslationBottomSheet> createState() =>
      _AiTranslationBottomSheetState();
}

class _AiTranslationBottomSheetState extends State<AiTranslationBottomSheet> {
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'Tiếng Anh'},
    {'code': 'vi', 'name': 'Tiếng Việt'},
    {'code': 'ja', 'name': 'Tiếng Nhật'},
    {'code': 'ko', 'name': 'Tiếng Hàn'},
    {'code': 'zh', 'name': 'Tiếng Trung'},
    {'code': 'fr', 'name': 'Tiếng Pháp'},
  ];

  String? _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    // Reset state before starting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiProvider>().resetState();
    });
  }

  void _translate() {
    if (_selectedLanguageCode == null) return;
    context.read<AiProvider>().translateContent(
      widget.originalContent,
      _selectedLanguageCode!,
      noteId: widget.noteId,
    );
  }

  void _copyAndClose(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã sao chép vào bộ nhớ tạm!',
          style: GoogleFonts.nunito(),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _replaceAndClose(String text) {
    widget.onReplace(text);
    Navigator.pop(context);
  }

  void _showPremiumDialog() {
    Navigator.pop(context); // Đóng bottom sheet hiện tại
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.star_fill, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'Tính năng Premium',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Phần dịch thuật AI dài và nâng cao chỉ dành riêng cho thành viên VIP. Vui lòng nâng cấp Premium để tiếp tục trải nghiệm.',
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
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
            child: Text(
              'Nâng cấp ngay',
              style: GoogleFonts.nunito(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
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

    // Nếu có lỗi VIP -> Hiển thị pop VIP và pop luôn BottomSheet hiện tại
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.cyan.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.globe,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dịch bằng AI',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Chuyển tự động sang ngôn ngữ bạn muốn',
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
          ),

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
        return _buildLanguageSelector();
    }
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn ngôn ngữ đích:',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _languages.map((lang) {
            final isSelected = _selectedLanguageCode == lang['code'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLanguageCode = lang['code'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  lang['name']!,
                  style: GoogleFonts.nunito(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            onPressed: _selectedLanguageCode != null ? _translate : null,
            child: Text(
              'Dịch ngay',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'AI đang dịch nội dung...',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String errorMsg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Đã xảy ra lỗi',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorMsg,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            context.read<AiProvider>().resetState();
          },
          child: const Text('Thử lại'),
        ),
      ],
    );
  }

  Widget _buildSuccessResult(String translatedText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Text(
            translatedText,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: AppColors.primary),
                ),
                onPressed: () => _copyAndClose(translatedText),
                icon: const Icon(
                  CupertinoIcons.doc_on_clipboard,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Copy & Đóng',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _replaceAndClose(translatedText),
                icon: const Icon(
                  CupertinoIcons.arrow_right_arrow_left,
                  size: 18,
                ),
                label: Text(
                  'Thay thế gốc',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
