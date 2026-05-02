import 'dart:ui';

import 'package:flutter/material.dart';

/// Design tokens for the bottom formatting toolbar.
abstract final class _ToolbarColors {
  static const Color borderTop = Color(0x1A000000);
}

/// A glassmorphic bottom toolbar for text formatting actions.
///
/// Displays formatting icons (checkbox, palette, font size, bold, alignment)
/// with a frosted-glass visual effect.
class BottomFormattingToolbar extends StatelessWidget {
  const BottomFormattingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: bottomPadding + 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, -4),
                blurRadius: 20,
              ),
            ],
            border: const Border(
              top: BorderSide(color: _ToolbarColors.borderTop),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FormatIcon(icon: Icons.check_box_outlined, isActive: true),
              _FormatIcon(icon: Icons.palette_outlined),
              _FormatIcon(icon: Icons.format_size),
              _FormatIcon(icon: Icons.format_bold),
              _FormatIcon(icon: Icons.format_align_left),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single formatting icon with active/inactive visual states.
class _FormatIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _FormatIcon({required this.icon, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 24,
        color: isActive ? Colors.green.shade700 : Colors.grey.shade400,
      ),
    );
  }
}
