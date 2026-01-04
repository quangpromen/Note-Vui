import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A soft, gradient floating action button.
///
/// Features:
/// - Pink to blue gradient background
/// - Circular shape (50px border radius)
/// - Soft shadow matching the gradient
/// - Large touch target (64x64)
class SoftFab extends StatelessWidget {
  /// Callback when the FAB is pressed
  final VoidCallback onPressed;

  const SoftFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.fabStart, AppColors.fabEnd],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.fabStart.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
