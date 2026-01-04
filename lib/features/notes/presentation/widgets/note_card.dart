import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/note_model.dart';

/// A card widget that displays a single note with pastel background.
///
/// Features:
/// - Pastel background color unique to each note
/// - Soft shadow for depth
/// - Rounded corners (24px radius)
/// - Title, content preview, and date display
/// - Vietnamese date formatting
class NoteCard extends StatelessWidget {
  /// The note data to display
  final NoteModel note;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  /// Formats the date in Vietnamese format (e.g., "04 Th1" for January 4th)
  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM', 'vi_VN');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: note.backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: note.backgroundColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                note.title,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Content preview
              Text(
                note.content,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Date row
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(note.createdAt),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
