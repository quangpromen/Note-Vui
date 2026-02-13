import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../notes/domain/note_service.dart';
import '../../../notes/presentation/screens/home_screen.dart';

/// Premium Register Screen with Glassmorphism design.
///
/// Features:
/// - Gradient background (Lime → Teal) with animated floating orbs
/// - Glassmorphism card with frosted glass effect
/// - Full Name, Email, Password, and Confirm Password fields
/// - Real-time validation for all fields
/// - Show/hide password toggles
/// - Loading indicator on register button
/// - Haptic feedback on interactions
/// - Smooth page transitions
/// - Auto-login after successful registration
///
/// Font: Google Fonts 'Outfit' for premium modern feel
class RegisterScreen extends StatefulWidget {
  final NoteService noteService;

  const RegisterScreen({super.key, required this.noteService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // Form
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Animations
  late AnimationController _bgAnimController;
  late AnimationController _formAnimController;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    // Background floating orbs animation (looping)
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Form entrance animation
    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _formSlideAnimation = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
        parent: _formAnimController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _formFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _formAnimController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Start entrance animation
    _formAnimController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _bgAnimController.dispose();
    _formAnimController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Handles the register button press with haptic feedback.
  Future<void> _handleRegister() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim(),
      );

      if (success && mounted) {
        // Success haptic
        HapticFeedback.mediumImpact();

        // Navigate to HomeScreen with smooth transition
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                HomeScreen(noteService: widget.noteService),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
          (route) => false,
        );
      } else if (mounted) {
        // Error haptic
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Đăng ký thất bại.';
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Navigate back to Login screen.
  void _navigateBack() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Gradient Background
          _buildGradientBackground(),

          // Layer 2: Animated floating orbs
          _buildFloatingOrbs(),

          // Layer 3: Content (scrollable)
          SafeArea(
            child: AnimatedBuilder(
              animation: _formAnimController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _formSlideAnimation.value),
                  child: Opacity(
                    opacity: _formFadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // Custom AppBar with back button
                  _buildCustomAppBar(),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Welcome text
                          _buildWelcomeText(),

                          const SizedBox(height: 36),

                          // Glassmorphism Register Card
                          _buildGlassCard(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BACKGROUND LAYERS
  // ===========================================================================

  /// Full-screen gradient from Lime to Teal (reversed direction for variety).
  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFBFFF00), // Lime
            Color(0xFF4ECDC4), // Bright Teal
            Color(0xFF008080), // Teal
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  /// Animated floating translucent orbs.
  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, _) {
        final value = _bgAnimController.value;
        return Stack(
          children: [
            // Large orb - top left
            Positioned(
              top: -100 + (value * 25),
              left: -50 + (value * 30),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            // Medium orb - bottom right
            Positioned(
              bottom: -60 + (value * 35),
              right: -70 + (value * 20),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Small orb - center
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35 + (value * 15),
              left: MediaQuery.of(context).size.width * 0.15 - (value * 10),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // HEADER SECTION
  // ===========================================================================

  /// Custom AppBar with translucent back button.
  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateBack,
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
        ],
      ),
    );
  }

  /// Welcome title and subtitle.
  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Tạo tài khoản mới',
          style: GoogleFonts.outfit(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Đăng ký để lưu trữ, đồng bộ ghi chú & sử dụng AI',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ===========================================================================
  // GLASSMORPHISM CARD
  // ===========================================================================

  /// Main register card with frosted glass effect.
  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name Field
                _buildTextField(
                  controller: _fullNameController,
                  focusNode: _fullNameFocusNode,
                  hint: 'Họ và tên',
                  icon: CupertinoIcons.person,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_emailFocusNode),
                  validator: _validateFullName,
                ),

                const SizedBox(height: 16),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  hint: 'Email',
                  icon: CupertinoIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocusNode),
                  validator: _validateEmail,
                ),

                const SizedBox(height: 16),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hint: 'Mật khẩu',
                  icon: CupertinoIcons.lock,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(
                    context,
                  ).requestFocus(_confirmPasswordFocusNode),
                  suffixIcon: _buildPasswordToggle(
                    isObscure: _obscurePassword,
                    onToggle: () {
                      HapticFeedback.selectionClick();
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                _buildTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  hint: 'Xác nhận mật khẩu',
                  icon: CupertinoIcons.lock_shield,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  suffixIcon: _buildPasswordToggle(
                    isObscure: _obscureConfirmPassword,
                    onToggle: () {
                      HapticFeedback.selectionClick();
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                  validator: _validateConfirmPassword,
                ),

                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null) ...[
                  _buildErrorBanner(),
                  const SizedBox(height: 16),
                ],

                // Register Button
                _buildRegisterButton(),

                const SizedBox(height: 20),

                // Login Link
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FORM FIELDS
  // ===========================================================================

  /// Glassmorphic text field with semi-transparent background.
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.7),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        errorStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFFFD93D),
        ),
      ),
    );
  }

  /// Eye icon to toggle password visibility (reusable for both fields).
  Widget _buildPasswordToggle({
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        isObscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
        color: Colors.white.withValues(alpha: 0.6),
        size: 20,
      ),
      onPressed: onToggle,
    );
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  /// Validates full name is not empty and has minimum length.
  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  /// Validates email format using regex.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ (ví dụ: abc@gmail.com)';
    }

    return null;
  }

  /// Validates password length (min 6 characters).
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  /// Validates confirm password matches original password.
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  // ===========================================================================
  // SECONDARY UI ELEMENTS
  // ===========================================================================

  /// Error banner with red/amber styling.
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: Color(0xFFFFD93D),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Premium gradient register button with loading state.
  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRegister,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.1),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.15),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Tạo tài khoản',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  /// "Đã có tài khoản? Đăng nhập" link.
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        GestureDetector(
          onTap: _navigateBack,
          child: Text(
            'Đăng nhập',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
