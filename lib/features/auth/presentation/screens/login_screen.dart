import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../notes/domain/note_service.dart';
import '../../../notes/presentation/screens/home_screen.dart';
import 'register_screen.dart';

/// Premium Login Screen with Glassmorphism design.
///
/// Features:
/// - Gradient background (Lime → Teal) with animated floating orbs
/// - Glassmorphism card with frosted glass effect
/// - Email and Password fields with real-time validation
/// - Show/hide password toggle
/// - Loading indicator on login button
/// - Haptic feedback on button press
/// - Smooth page transitions
/// - "Quên mật khẩu" and "Đăng ký mới" links
/// - Guest Mode for offline usage
///
/// Font: Google Fonts 'Outfit' for a modern premium feel
class LoginScreen extends StatefulWidget {
  final NoteService noteService;

  const LoginScreen({super.key, required this.noteService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Form
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // State
  bool _obscurePassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _bgAnimController.dispose();
    _formAnimController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Handles the login button press with haptic feedback.
  Future<void> _handleLogin() async {
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
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
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
          _errorMessage = authProvider.errorMessage ?? 'Đăng nhập thất bại.';
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

  /// Navigates to the Register screen with a smooth slide transition.
  void _navigateToRegister() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            RegisterScreen(noteService: widget.noteService),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// Handles Guest Mode → go straight to HomeScreen.
  void _handleGuestMode() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            HomeScreen(noteService: widget.noteService),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (route) => false,
    );
  }

  /// Placeholder for "Quên mật khẩu" feature.
  void _handleForgotPassword() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tính năng đặt lại mật khẩu sẽ sớm được cập nhật!',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF008080),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Logo
                    _buildLogo(),

                    const SizedBox(height: 24),

                    // Welcome text
                    _buildWelcomeText(),

                    const SizedBox(height: 40),

                    // Glassmorphism Login Card
                    _buildGlassCard(),

                    const SizedBox(height: 24),

                    // Divider
                    _buildDivider(),

                    const SizedBox(height: 24),

                    // Guest Mode Button
                    _buildGuestModeButton(),

                    const SizedBox(height: 40),
                  ],
                ),
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

  /// Full-screen gradient from Lime to Teal.
  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFBFFF00), // Lime
            Color(0xFF60D394), // Mid green
            Color(0xFF008080), // Teal
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  /// Animated floating translucent orbs for premium background effect.
  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, _) {
        final value = _bgAnimController.value;
        return Stack(
          children: [
            // Large orb - top right
            Positioned(
              top: -80 + (value * 30),
              right: -60 + (value * 20),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Medium orb - bottom left
            Positioned(
              bottom: -40 + (value * 40),
              left: -80 + (value * 25),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Small orb - center right
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4 + (value * 20),
              right: 20 - (value * 15),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
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

  /// App logo with shadow and rounded container.
  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/images/logo.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                CupertinoIcons.doc_text_fill,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Welcome title and subtitle.
  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Chào mừng trở lại!',
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
          'Đăng nhập để đồng bộ ghi chú & sử dụng AI',
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

  /// Main login card with frosted glass effect.
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

                const SizedBox(height: 18),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hint: 'Mật khẩu',
                  icon: CupertinoIcons.lock,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  suffixIcon: _buildPasswordToggle(),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 12),

                // Forgot Password Link
                _buildForgotPasswordLink(),

                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage != null) ...[
                  _buildErrorBanner(),
                  const SizedBox(height: 16),
                ],

                // Login Button
                _buildLoginButton(),

                const SizedBox(height: 20),

                // Register Link
                _buildRegisterLink(),
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

  /// Eye icon to toggle password visibility.
  Widget _buildPasswordToggle() {
    return IconButton(
      icon: Icon(
        _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
        color: Colors.white.withValues(alpha: 0.6),
        size: 20,
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _obscurePassword = !_obscurePassword);
      },
    );
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  /// Validates email format.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }

    // Regex for basic email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ (ví dụ: abc@gmail.com)';
    }

    return null;
  }

  /// Validates password length.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  // ===========================================================================
  // SECONDARY UI ELEMENTS
  // ===========================================================================

  /// "Quên mật khẩu?" link aligned right.
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _handleForgotPassword,
        child: Text(
          'Quên mật khẩu?',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

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

  /// Premium gradient login button with loading state.
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
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
                  'Đăng nhập',
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

  /// "Chưa có tài khoản? Đăng ký ngay" link.
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        GestureDetector(
          onTap: _navigateToRegister,
          child: Text(
            'Đăng ký ngay',
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

  // ===========================================================================
  // BOTTOM SECTION
  // ===========================================================================

  /// Divider with "hoặc" text.
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }

  /// Semi-transparent guest mode button.
  Widget _buildGuestModeButton() {
    return GestureDetector(
      onTap: _handleGuestMode,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_badge_minus,
              color: Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'Dùng không cần tài khoản',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
