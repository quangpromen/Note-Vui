import 'package:flutter/material.dart';

import '../controllers/drawing_toolbar_controller.dart';

Color _getToolColor(DrawingTool tool) {
  switch (tool) {
    case DrawingTool.pen:
      return Colors.black87;
    case DrawingTool.highlighter:
      return Colors.yellowAccent.withValues(alpha: 0.4);
    default:
      return Colors.transparent;
  }
}

double _getToolStrokeWidth(DrawingTool tool) {
  switch (tool) {
    case DrawingTool.pen:
      return 3.0;
    case DrawingTool.highlighter:
      return 20.0;
    case DrawingTool.eraser:
      return 24.0;
    default:
      return 3.0;
  }
}

/// Overlay widget that allows drawing on top of its child when a drawing tool is selected.
class DrawingCanvas extends StatefulWidget {
  final DrawingToolbarController controller;
  final Widget child;

  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset>? _currentPoints;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isDrawingMode = widget.controller.selectedTool != DrawingTool.keyboard;

        return Stack(
          children: [
            widget.child,
            if (isDrawingMode)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentPoints = [details.localPosition];
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentPoints?.add(details.localPosition);
                    });
                  },
                  onPanEnd: (details) {
                    if (_currentPoints != null && _currentPoints!.length > 1) {
                      widget.controller.addStroke(
                        StrokeAction(
                          points: List.from(_currentPoints!),
                          color: _getToolColor(widget.controller.selectedTool),
                          strokeWidth: _getToolStrokeWidth(widget.controller.selectedTool),
                          tool: widget.controller.selectedTool,
                        ),
                      );
                    }
                    setState(() {
                      _currentPoints = null;
                    });
                  },
                  child: CustomPaint(
                    painter: _StrokePainter(
                      strokes: widget.controller.strokes,
                      currentPoints: _currentPoints,
                      currentTool: widget.controller.selectedTool,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            if (!isDrawingMode && widget.controller.strokes.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _StrokePainter(
                      strokes: widget.controller.strokes,
                      currentPoints: null,
                      currentTool: widget.controller.selectedTool,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<StrokeAction> strokes;
  final List<Offset>? currentPoints;
  final DrawingTool currentTool;

  _StrokePainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Save layer is required so the eraser can use BlendMode.clear
    // to erase strokes without erasing the background UI.
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke.points, stroke.tool, stroke.color, stroke.strokeWidth);
    }

    if (currentPoints != null) {
      _paintStroke(
        canvas,
        currentPoints!,
        currentTool,
        _getToolColor(currentTool),
        _getToolStrokeWidth(currentTool),
      );
    }

    canvas.restore();
  }

  void _paintStroke(Canvas canvas, List<Offset> points, DrawingTool tool, Color color, double strokeWidth) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (tool == DrawingTool.eraser) {
      paint.blendMode = BlendMode.clear;
      paint.color = Colors.transparent;
    } else {
      paint.color = color;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return true;
  }
}
