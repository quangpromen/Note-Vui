import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../notes/domain/note_service.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

/// Màn hình Thông tin cá nhân — hiện thông tin user sau khi đăng nhập.
///
/// Features:
/// - Avatar lớn (hoặc icon mặc định nếu chưa có avatar)
/// - Hiển thị: Họ tên, Email, User ID
/// - Nút "Đổi mật khẩu" → navigate sang [ChangePasswordScreen]
/// - Nút "Đăng xuất" với xác nhận dialog
/// - Thiết kế Glassmorphism đồng bộ với Login/ForgotPassword
/// - Tất cả text tiếng Việt, font Nunito
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.noteService});

  final NoteService noteService;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ─────────────────────────────────────
          _buildGradientBackground(),

          // ── Floating orbs ───────────────────────────────────────────
          _buildFloatingOrbs(),

          // ── Content ─────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // ── Back button ───────────────────────────────────
                  _buildBackButton(context),

                  const SizedBox(height: 12),

                  // ── Title ─────────────────────────────────────────
                  Text(
                    'Thông tin cá nhân',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Quản lý tài khoản của bạn',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Avatar ────────────────────────────────────────
                  _buildAvatar(user?.avatarUrl),

                  const SizedBox(height: 16),

                  // ── User name ─────────────────────────────────────
                  Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName
                        : 'Người dùng',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  if (user?.email != null && user!.email!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Glass card: thông tin chi tiết ─────────────────
                  _buildInfoCard(context, user, authProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVATAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAvatar(String? avatarUrl) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(CupertinoIcons.person_fill, size: 48, color: Colors.white),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASS INFO CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInfoCard(
    BuildContext context,
    dynamic user,
    AuthProvider authProvider,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Thông tin chi tiết ────────────────────────────────
              _buildInfoRow(
                icon: CupertinoIcons.person,
                label: 'Họ và tên',
                value: user?.fullName?.isNotEmpty == true
                    ? user!.fullName
                    : 'Chưa cập nhật',
              ),

              _buildDivider(),

              _buildInfoRow(
                icon: CupertinoIcons.mail,
                label: 'Email',
                value: user?.email?.isNotEmpty == true
                    ? user!.email!
                    : 'Chưa cập nhật',
              ),

              const SizedBox(height: 24),

              // ── Nút Đổi mật khẩu ──────────────────────────────────
              _buildActionButton(
                context: context,
                icon: CupertinoIcons.lock_rotation,
                label: 'Đổi mật khẩu',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChangePasswordScreen(noteService: noteService),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // ── Nút Đăng xuất ─────────────────────────────────────
              _buildActionButton(
                context: context,
                icon: CupertinoIcons.power,
                label: 'Đăng xuất',
                isDestructive: true,
                onTap: () => _handleLogout(context, authProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INFO ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Label + Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.12));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFFF6B6B) : Colors.white;
    final bgColor = isDestructive
        ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.12);
    final borderColor = isDestructive
        ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.25);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handleLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    HapticFeedback.selectionClick();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(noteService: noteService),
          ),
          (route) => false,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBFFF00), Color(0xFF60D394), Color(0xFF008080)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildFloatingOrbs() {
    return Stack(
      children: [
        Positioned(top: -80, right: -60, child: _orb(size: 250, opacity: 0.08)),
        Positioned(
          bottom: -40,
          left: -80,
          child: _orb(size: 210, opacity: 0.06),
        ),
      ],
    );
  }

  Widget _orb({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
