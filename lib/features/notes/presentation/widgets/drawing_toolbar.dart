import 'package:flutter/material.dart';

import '../controllers/drawing_toolbar_controller.dart';

/// Design tokens used exclusively by the drawing toolbar.
abstract final class _ToolbarColors {
  static const Color surface = Color(0xFFF1F5EF);
  static const Color activeBackground = Color(0xFF9AE6B4);
  static const Color activeForeground = Color(0xFF1E6B43);
  static const Color inactiveForeground = Color(0xFF404941);
}

/// A horizontal scrollable toolbar that displays drawing tool icons
/// and undo/redo action buttons.
///
/// Listens to [DrawingToolbarController] and rebuilds only itself
/// when the selected tool or history state changes.
class DrawingToolbar extends StatelessWidget {
  /// The controller that owns the toolbar state.
  final DrawingToolbarController controller;

  const DrawingToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _ToolbarColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 72,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ToolIcon(
                    icon: Icons.keyboard_outlined,
                    isActive: controller.selectedTool == DrawingTool.keyboard,
                    onTap: () => controller.setTool(DrawingTool.keyboard),
                  ),
                  _ToolIcon(
                    icon: Icons.edit_outlined,
                    isActive: controller.selectedTool == DrawingTool.pen,
                    onTap: () => controller.setTool(DrawingTool.pen),
                  ),
                  _ToolIcon(
                    icon: Icons.border_color_outlined,
                    isActive: controller.selectedTool == DrawingTool.highlighter,
                    onTap: () => controller.setTool(DrawingTool.highlighter),
                  ),
                  _ToolIcon(
                    icon: Icons.cleaning_services_outlined,
                    isActive: controller.selectedTool == DrawingTool.eraser,
                    onTap: () => controller.setTool(DrawingTool.eraser),
                  ),
                  // Tạm ẩn công cụ Lasso
                  // _ToolIcon(
                  //   icon: Icons.gesture,
                  //   isActive: controller.selectedTool == DrawingTool.lasso,
                  //   onTap: () => controller.setTool(DrawingTool.lasso),
                  // ),
                  _ActionIcon(
                    icon: Icons.undo,
                    isEnabled: controller.canUndo,
                    onTap: controller.undo,
                  ),
                  _ActionIcon(
                    icon: Icons.redo,
                    isEnabled: controller.canRedo,
                    onTap: controller.redo,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A selectable tool icon with active/inactive visual states.
class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? _ToolbarColors.activeBackground.withValues(alpha: 0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? _ToolbarColors.activeForeground
              : _ToolbarColors.inactiveForeground,
        ),
      ),
    );
  }
}

/// An action icon (undo/redo) that visually dims when disabled.
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: _ToolbarColors.inactiveForeground
              .withValues(alpha: isEnabled ? 1.0 : 0.3),
        ),
      ),
    );
  }
}
