import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A skeleton loader for NoteCard to provide professional feedback during loading.
class NoteSkeleton extends StatelessWidget {
  const NoteSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        height: _getRandomHeight(), // Mimic staggered grid variety
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  double _getRandomHeight() {
    // Logic to vary heights to match NoteCard's staggered feel
    final heights = [160.0, 200.0, 180.0, 240.0];
    return heights[DateTime.now().millisecond % heights.length];
  }
}
