import 'package:flutter/material.dart';

/// The five primary drawing tools available in the editor toolbar.
enum DrawingTool {
  keyboard,
  pen,
  highlighter,
  eraser,
  lasso,
}

/// Represents a single drawing action that can be undone or redone.
class StrokeAction {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  StrokeAction({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });
}

/// Manages the drawing toolbar state: active tool selection and stroke history.
class DrawingToolbarController extends ChangeNotifier {
  DrawingTool _selectedTool = DrawingTool.keyboard;

  /// The currently active drawing tool.
  DrawingTool get selectedTool => _selectedTool;

  final List<StrokeAction> _undoStack = [];
  final List<StrokeAction> _redoStack = [];
  
  /// The current list of strokes to render
  List<StrokeAction> get strokes => _undoStack;

  /// Whether there is at least one action that can be undone.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there is at least one action that can be redone.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Switches the active tool. No-op if [tool] is already selected.
  void setTool(DrawingTool tool) {
    if (_selectedTool == tool) return;
    _selectedTool = tool;
    notifyListeners();
  }

  /// Records a new stroke, clearing the redo history.
  void addStroke(StrokeAction action) {
    _undoStack.add(action);
    _redoStack.clear();
    notifyListeners();
  }

  /// Moves the most recent stroke from the undo stack to the redo stack.
  void undo() {
    if (!canUndo) return;
    _redoStack.add(_undoStack.removeLast());
    notifyListeners();
  }

  /// Moves the most recent stroke from the redo stack back to the undo stack.
  void redo() {
    if (!canRedo) return;
    _undoStack.add(_redoStack.removeLast());
    notifyListeners();
  }
}
