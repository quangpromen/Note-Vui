import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/auth/token_storage.dart';
import '../../../../providers/auth_provider.dart';
import '../../../notes/domain/note_service.dart';
import '../../data/models/user_profile_models.dart';
import '../controllers/user_profile_controller.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import '../../../subscription/presentation/screens/upgrade_plan_screen.dart';

/// Màn hình Hồ sơ cá nhân — hiển thị thông tin chi tiết từ API.
///
/// Features:
/// - Header: Avatar, Họ tên, Email
/// - Gói VIP: Badge VIP sáng nổi bật nếu isVip = true
/// - Thống kê ghi chú: tổng đồng bộ + đang có (2 card ngang)
/// - Thống kê AI: lượt dùng hôm nay + trong tháng
/// - Pull-to-refresh (RefreshIndicator)
/// - Shimmer loading khi đang tải
/// - Xử lý lỗi 401 → navigate về Login
/// - Xử lý lỗi mạng → icon + text + nút Thử lại
/// - Thiết kế Glassmorphism, font Nunito, UI tiếng Việt
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.noteService});

  final NoteService noteService;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UserProfileController();
    // Fetch data ngay khi vào màn hình
    _controller.fetchProfile();
    // Lắng nghe để xử lý unauthorized (navigate về Login)
    _controller.addListener(_handleStatusChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStatusChange);
    _controller.dispose();
    super.dispose();
  }

  /// Xử lý khi status thay đổi — đặc biệt là unauthorized (401).
  void _handleStatusChange() {
    if (!mounted) return;
    if (_controller.isUnauthorized) {
      _navigateToLogin();
    }
  }

  /// Xóa token + navigate về Login (xóa toàn bộ stack).
  Future<void> _navigateToLogin() async {
    await TokenStorage().clearAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(noteService: widget.noteService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Background gradient ─────────────────────────────────────
            _buildGradientBackground(),

            // ── Floating orbs ───────────────────────────────────────────
            _buildFloatingOrbs(),

            // ── Content ─────────────────────────────────────────────────
            SafeArea(
              child: Consumer<UserProfileController>(
                builder: (context, ctrl, _) {
                  // ── Loading state — hiệu ứng Shimmer ──────────────────
                  if (ctrl.isLoading) {
                    return _buildShimmerLoading();
                  }

                  // ── Error state — icon + text + nút Thử lại ──────────
                  if (ctrl.hasError) {
                    return _buildErrorView(ctrl);
                  }

                  // ── Success state — nội dung chính ────────────────────
                  if (ctrl.hasData) {
                    return _buildProfileContent(ctrl.profile!);
                  }

                  // Fallback (không nên xảy ra)
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE CONTENT — Nội dung chính (Success state)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileContent(UserProfileResponse profile) {
    return RefreshIndicator(
      onRefresh: _controller.refreshProfile,
      color: const Color(0xFF008080),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ── Header (Back & Edit) ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBackButton(context),
                _buildEditProfileButton(context, profile),
              ],
            ),

            const SizedBox(height: 12),

            // ── Title ───────────────────────────────────────────────
            Text(
              'Hồ sơ cá nhân',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Thông tin tài khoản của bạn',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),

            const SizedBox(height: 28),

            // ── Avatar ──────────────────────────────────────────────
            _buildAvatar(profile.avatarUrl),

            const SizedBox(height: 16),

            // ── Full name ───────────────────────────────────────────
            Text(
              profile.fullName.isNotEmpty ? profile.fullName : 'Người dùng',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            // ── Email ───────────────────────────────────────────────
            if (profile.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                profile.email,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Subscription Section ────────────────────────────────
            _buildSubscriptionSection(profile.subscription),

            const SizedBox(height: 16),

            // ── Nút Nâng cấp VIP ────────────────────────────────────
            if (!profile.subscription.planType.contains('Year') &&
                !profile.subscription.planType.contains('Năm')) ...[
              _buildUpgradeVipCard(context, profile.subscription.planType),
              const SizedBox(height: 16),
            ],

            // ── Notes Stats Section ─────────────────────────────────
            _buildNotesStatsSection(
              profile.totalNotesBackedUp,
              profile.activeNotes,
            ),

            const SizedBox(height: 16),

            // ── AI Usage Section ────────────────────────────────────
            _buildAiUsageSection(profile.aiUsage),

            const SizedBox(height: 16),

            // ── Action Buttons (Đổi mật khẩu + Đăng xuất) ──────────
            _buildActionsCard(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPGRADE VIP SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildUpgradeVipCard(BuildContext context, String currentPlanType) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UpgradePlanScreen(currentPlanType: currentPlanType),
          ),
        );
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.sparkles,
              color: Colors.black87,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Nâng cấp lên Premium',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ],
        ),
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
  // SUBSCRIPTION SECTION — Gói đăng ký / VIP
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSubscriptionSection(UserSubscriptionInfo subscription) {
    final isVip = subscription.isVip;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Nền khác nhau cho VIP vs Free
            gradient: isVip
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x40FFD700), Color(0x30FFA500)],
                  )
                : null,
            color: isVip ? null : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              // Viền vàng nổi bật cho VIP
              color: isVip
                  ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.3),
              width: isVip ? 2.0 : 1.5,
            ),
          ),
          child: Column(
            children: [
              // ── Header: Icon + Tên gói + Badge VIP ────────────────
              Row(
                children: [
                  // Icon gói
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isVip
                          ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isVip ? CupertinoIcons.star_fill : CupertinoIcons.gift,
                      color: isVip
                          ? const Color(0xFFFFD700)
                          : Colors.white.withValues(alpha: 0.8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Tên gói + Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gói đăng ký',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subscription.planName,
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isVip
                                ? const Color(0xFFFFD700)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge VIP
                  if (isVip)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '⭐ VIP',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),

              // ── Chi tiết VIP: số ngày còn lại ─────────────────────
              if (isVip) ...[
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Số ngày còn lại
                    _buildSubscriptionDetail(
                      icon: CupertinoIcons.time,
                      label: 'Còn lại',
                      value: '${subscription.daysRemaining} ngày',
                      isVip: true,
                    ),
                    // Gia hạn tự động
                    _buildSubscriptionDetail(
                      icon: CupertinoIcons.arrow_2_circlepath,
                      label: 'Tự động gia hạn',
                      value: subscription.isAutoRenew ? 'Bật' : 'Tắt',
                      isVip: true,
                    ),
                  ],
                ),
              ] else ...[
                // Người dùng Free: hiển thị "Miễn phí"
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bạn đang sử dụng gói Miễn phí',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail({
    required IconData icon,
    required String label,
    required String value,
    required bool isVip,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isVip
              ? const Color(0xFFFFD700).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isVip ? const Color(0xFFFFD700) : Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES STATS SECTION — Thống kê ghi chú (2 card ngang)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNotesStatsSection(int totalNotesBackedUp, int activeNotes) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: CupertinoIcons.cloud_upload,
            iconColor: const Color(0xFF4FC3F7),
            label: 'Đã đồng bộ',
            value: totalNotesBackedUp.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: CupertinoIcons.doc_text_fill,
            iconColor: const Color(0xFF81C784),
            label: 'Đang có',
            value: activeNotes.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              // Value (số lớn, nổi bật)
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              // Label
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI USAGE SECTION — Thống kê sử dụng AI
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAiUsageSection(AiUsageStats aiUsage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA68C8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.bolt_fill,
                      color: Color(0xFFBA68C8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Sử dụng AI',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: 16),

              // ── Grid: 4 ô thống kê ────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildAiStatTile(
                      icon: CupertinoIcons.sun_max_fill,
                      iconColor: const Color(0xFFFFB74D),
                      label: 'Hôm nay',
                      value: aiUsage.usedToday.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAiStatTile(
                      icon: CupertinoIcons.calendar,
                      iconColor: const Color(0xFF4FC3F7),
                      label: 'Tháng này',
                      value: aiUsage.usedThisMonth.toString(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildAiStatTile(
                      icon: CupertinoIcons.chart_bar_fill,
                      iconColor: const Color(0xFF81C784),
                      label: 'Năm nay',
                      value: aiUsage.usedThisYear.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAiStatTile(
                      icon: CupertinoIcons.sum,
                      iconColor: const Color(0xFFE57373),
                      label: 'Tổng cộng',
                      value: aiUsage.totalUsed.toString(),
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

  Widget _buildAiStatTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS CARD — Đổi mật khẩu + Đăng xuất
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionsCard(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // ── Nút Đổi mật khẩu ─────────────────────────────────
              _buildActionButton(
                context: context,
                icon: CupertinoIcons.lock_rotation,
                label: 'Đổi mật khẩu',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChangePasswordScreen(noteService: widget.noteService),
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
            builder: (_) => LoginScreen(noteService: widget.noteService),
          ),
          (route) => false,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING — Hiệu ứng loading đẹp
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.3),
        child: Column(
          children: [
            // Back button placeholder
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title placeholder
            Container(
              width: 180,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(height: 6),

            Container(
              width: 220,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            const SizedBox(height: 28),

            // Avatar placeholder
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(height: 16),

            // Name placeholder
            Container(
              width: 160,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(height: 8),

            // Email placeholder
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            const SizedBox(height: 28),

            // Subscription card placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 16),

            // Notes stats placeholder
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // AI usage placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 16),

            // Actions placeholder
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR VIEW — Lỗi mạng / server
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildErrorView(UserProfileController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon lỗi
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.wifi_exclamationmark,
                size: 40,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Không tải được dữ liệu',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Message
            Text(
              ctrl.errorMessage ?? 'Đã xảy ra lỗi. Vui lòng thử lại.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Nút Thử lại
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ctrl.fetchProfile();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_clockwise,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Thử lại',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nút Quay lại
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Text(
                'Quay lại',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND & DECORATIONS
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

  Widget _buildEditProfileButton(
    BuildContext context,
    UserProfileResponse profile,
  ) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final updatedProfile = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditProfileScreen(profile: profile),
          ),
        );
        if (updatedProfile != null && updatedProfile is UserProfileResponse) {
          if (!context.mounted) return;
          _controller.updateProfile(updatedProfile);
          // Sync AuthProvider để trang chủ và những nơi khác cập nhật theo
          context.read<AuthProvider>().updateUser(
            fullName: updatedProfile.fullName,
            avatarUrl: updatedProfile.avatarUrl,
          );
        } else if (updatedProfile == true) {
          if (!context.mounted) return;
          _navigateToLogin();
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Icon(CupertinoIcons.pencil, color: Colors.white, size: 20),
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
        // Thêm orb phụ cho phong phú hơn
        Positioned(top: 200, left: -40, child: _orb(size: 120, opacity: 0.04)),
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
