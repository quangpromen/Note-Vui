import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/token_storage.dart';
import '../../data/models/user_profile_models.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfileResponse profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditProfileController _controller;
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _controller = EditProfileController();
    _controller.addListener(_handleStatusChange);

    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _emailController = TextEditingController(text: widget.profile.email);
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStatusChange);
    _controller.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleStatusChange() {
    if (!mounted) return;

    if (_controller.isUnauthorized) {
      _navigateToLogin();
      return;
    }

    if (_controller.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Đã xảy ra lỗi.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Reset state để không bị show thông báo liên tục
      return;
    }

    if (_controller.isSuccess && _controller.updatedProfile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cập nhật thông tin thành công',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(_controller.updatedProfile);
    }
  }

  Future<void> _navigateToLogin() async {
    await TokenStorage().clearAll();
    if (!mounted) return;
    // Navigation đến màn login - giả sử không truyền noteService vì nó bắt nguồn từ profile (đã login)
    // Tạm thời push thẳng LoginScreen và xóa stack (người dùng sẽ phải đăng nhập lại)
    // Để cho an toàn, ta dùng pushAndRemoveUntil
    // Trong file này LoginScreen được import, ta cứ mock tham số noteService nếu cần hoặc thay đổi hàm build LoginScreen...
    // Tuy nhiên theo clean architecture ta chỉ pop về root, tùy context.
    // Thực tế project này LoginScreen cần noteService (giống UserProfileScreen).
    // Vì không có noteService trong EditProfileScreen (chỉ truyền profile),
    // tạm thời Navigator.of(context).maybePop() hoặc yêu cầu truyền NoteService từ ngoài vào.
    // Cách an toàn nhất là quay lại UserProfileScreen để đó catch lỗi 401.
    // EditProfileController sẽ raise unauthorized, mình chỉ pop() và để UserProfileController handle load lại -> unauthorized
    Navigator.of(
      context,
    ).pop(true); // Pop với true để báo là cần load lại profile -> 401
  }

  void _submitForm() {
    if (_controller.isLoading) return;
    HapticFeedback.selectionClick();

    // Đóng bàn phím
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() == true) {
      _controller.editProfile(
        fullName: _fullNameController.text,
        avatarUrl: _avatarUrl,
      );
    }
  }

  Future<void> _showAvatarInputDialog() async {
    HapticFeedback.selectionClick();
    final urlController = TextEditingController(text: _avatarUrl);

    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3E50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Nhập URL hình ảnh',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: urlController,
            style: GoogleFonts.nunito(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: GoogleFonts.nunito(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Hủy',
                style: GoogleFonts.nunito(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, urlController.text),
              child: Text(
                'Đồng ý',
                style: GoogleFonts.nunito(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (newUrl != null && newUrl.trim().isNotEmpty) {
      setState(() {
        _avatarUrl = newUrl.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        body: Stack(
          children: [
            _buildGradientBackground(),
            _buildFloatingOrbs(),
            SafeArea(
              child: Consumer<EditProfileController>(
                builder: (context, ctrl, _) {
                  return Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            _buildBackButton(context),
                            Expanded(
                              child: Text(
                                'Chỉnh sửa hồ sơ',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 44,
                            ), // Cân bằng không gian với nút back
                          ],
                        ),
                      ),

                      // Form nội dung
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildAvatarEditor(),
                                const SizedBox(height: 40),
                                _buildTextField(
                                  controller: _fullNameController,
                                  label: 'Họ và tên',
                                  icon: CupertinoIcons.person_fill,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Tên đầy đủ không được để trống';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email (không thể thay đổi)',
                                  icon: CupertinoIcons.mail_solid,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 48),
                                _buildSubmitButton(ctrl),
                              ],
                            ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAvatarEditor() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? Image.network(
                      _avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showAvatarInputDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF008080),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.pencil,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(CupertinoIcons.person_fill, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: readOnly ? Colors.white60 : Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 22,
        ),
        filled: true,
        fillColor: readOnly
            ? Colors.black.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.redAccent.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: GoogleFonts.nunito(
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(EditProfileController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008080),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF008080).withValues(alpha: 0.6),
          // Disable form background color handle automatically when onPressed is null
        ),
        onPressed: ctrl.isLoading ? null : _submitForm,
        child: ctrl.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Lưu thay đổi',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
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
