import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// A soft, rounded search bar with floating appearance.
///
/// Features:
/// - White background with subtle shadow
/// - Rounded corners (24px radius)
/// - Search icon prefix
/// - Clear button when text is present
/// - Vietnamese placeholder text
class SoftSearchBar extends StatelessWidget {
  /// Controller for the text input
  final TextEditingController controller;

  /// Callback when the search text changes
  final ValueChanged<String> onChanged;

  const SoftSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm ghi chú...',
          hintStyle: GoogleFonts.nunito(
            fontSize: 16,
            color: AppColors.textHint,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              CupertinoIcons.search,
              color: AppColors.textHint,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          suffixIcon: _buildClearButton(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  /// Builds the clear button that appears when there's text in the field.
  Widget? _buildClearButton() {
    if (controller.text.isEmpty) return null;

    return IconButton(
      icon: const Icon(
        CupertinoIcons.xmark_circle_fill,
        color: AppColors.textHint,
        size: 20,
      ),
      onPressed: () {
        controller.clear();
        onChanged('');
      },
    );
  }
}
