import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/subscription_controller.dart';
import 'request_history_screen.dart';

class UpgradePlanScreen extends StatefulWidget {
  final String currentPlanType;

  const UpgradePlanScreen({super.key, this.currentPlanType = 'Free'});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  final TextEditingController _noteController = TextEditingController();
  late int _selectedPlan; // 1: Tháng, 2: Năm

  bool get _isMonthlyPlan =>
      widget.currentPlanType.contains('Month') ||
      widget.currentPlanType.contains('Tháng') ||
      widget.currentPlanType == '1';

  @override
  void initState() {
    super.initState();
    // Nếu đang ở gói tháng, mặc định chọn gói năm (2)
    _selectedPlan = _isMonthlyPlan ? 2 : 1;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitRequest(SubscriptionController ctrl) async {
    HapticFeedback.selectionClick();

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    final result = await ctrl.createUpgradeRequest(
      planType: _selectedPlan,
      note: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (result == SubscriptionResult.success) {
      if (ctrl.successMessage != null) {
        _showSnackBar(ctrl.successMessage!, isError: false);
      }
      // Chuyển sang màn Lịch sử hoặc pop về
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RequestHistoryScreen()),
      );
    } else if (result == SubscriptionResult.error) {
      if (ctrl.errorMessage != null) {
        _showSnackBar(ctrl.errorMessage!, isError: true);
      }
    }
    // unauthorized thì controller tự navigate về login ở UI gốc, ta không tự xử lý ở đây
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? CupertinoIcons.xmark_circle_fill
                  : CupertinoIcons.checkmark_alt_circle_fill,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ta bọc bằng Provider để dễ inject, nhưng nếu gọi từ ngoài thì đã có Provider.
    // Ở đây ta tự tạo luôn nếu đứng độc lập:
    return ChangeNotifierProvider(
      create: (_) => SubscriptionController(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _buildGradientBackground(),
            _buildFloatingOrbs(),
            SafeArea(
              child: Consumer<SubscriptionController>(
                builder: (context, ctrl, _) {
                  return Column(
                    children: [
                      _buildAppBar(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Plans
                              Text(
                                'Chọn gói nâng cấp',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPlanCard(
                                planType: 1,
                                title: 'Premium (Tháng)',
                                price: '49.000đ / tháng',
                                icon: CupertinoIcons.star,
                                disabled: _isMonthlyPlan,
                              ),
                              const SizedBox(height: 12),
                              _buildPlanCard(
                                planType: 2,
                                title: 'Premium (Năm)',
                                price: '490.000đ / năm',
                                icon: CupertinoIcons.star_fill,
                                disabled: false,
                              ),

                              const SizedBox(height: 32),

                              // Banking Info
                              _buildBankingInfo(),

                              const SizedBox(height: 24),

                              // Note Field
                              Text(
                                'Ghi chú chuyển khoản (Tùy chọn)',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildNoteInput(),

                              const SizedBox(height: 32),

                              // Submit Button
                              _buildSubmitButton(ctrl),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Nâng cấp VIP',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RequestHistoryScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.clock_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int planType,
    required String title,
    required String price,
    required IconData icon,
    bool disabled = false,
  }) {
    final isSelected = _selectedPlan == planType;
    return GestureDetector(
      onTap: disabled
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Bạn đang sử dụng gói này rồi!',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.orange.shade400,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : () {
              HapticFeedback.selectionClick();
              setState(() => _selectedPlan = planType);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withValues(alpha: 0.05)
              : isSelected
              ? const Color(0xFFFFD700).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: disabled
                ? Colors.white.withValues(alpha: 0.1)
                : isSelected
                ? const Color(0xFFFFD700)
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: disabled
                    ? Colors.white.withValues(alpha: 0.1)
                    : isSelected
                    ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: disabled
                    ? Colors.white.withValues(alpha: 0.3)
                    : isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? Colors.white.withValues(alpha: 0.3)
                          : isSelected
                          ? const Color(0xFFFFD700)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    disabled ? 'Đã đăng ký' : price,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: disabled
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                color: Color(0xFFFFD700),
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingInfo() {
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
              Row(
                children: [
                  Icon(
                    CupertinoIcons.building_2_fill,
                    color: Colors.blue.shade100,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thông tin chuyển khoản',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Ngân hàng', 'Vietcombank (VCB)'),
              const SizedBox(height: 8),
              _buildInfoRow('Số tài khoản', '1234567890'),
              const SizedBox(height: 8),
              _buildInfoRow('Chủ tài khoản', 'NGUYEN VAN A'),
              const SizedBox(height: 12),
              Text(
                'Nội dung chuyển khoản: <Email tài khoản> hoặc <Tên tài khoản>',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _noteController,
        style: GoogleFonts.nunito(color: Colors.white),
        maxLength: 200,
        maxLines: 3,
        decoration: InputDecoration(
          hintText:
              'Nhập mã giao dịch hoặc thông tin để Admin dễ dàng kiểm tra...',
          hintStyle: GoogleFonts.nunito(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterStyle: GoogleFonts.nunito(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(SubscriptionController ctrl) {
    final isLoading = ctrl.isLoadingForm;
    return GestureDetector(
      onTap: isLoading ? null : () => _submitRequest(ctrl),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey : const Color(0xFFFFD700),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: isLoading ? 0 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Gửi Yêu Cầu Nâng Cấp',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
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
