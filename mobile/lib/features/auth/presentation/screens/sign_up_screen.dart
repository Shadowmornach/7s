import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// 7s Mobile App — Sign Up Screen (Screen 4 in Auth Flow)
/// Rebuilt to match the exact visual reference design spec.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  bool _isSubmitting = false;

  bool get _hasMinLength => _passwordController.text.length >= 10;
  bool get _hasUpper => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'\d'));
  bool get _hasSpecial => _passwordController.text.contains(RegExp(r'[^a-zA-Z0-9]'));

  Widget _buildChecklistItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isMet ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: isMet ? const Color(0xFF334155) : const Color(0xFF94A3B8),
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    if (!_agreeToTerms || !_agreeToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Please accept both Terms of Service and Privacy Policy to continue.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authNotifier = context.read<AuthNotifier>();
    try {
      await authNotifier.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        context.go('/complete-profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Failed to create account. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFE8772A);
    const textNavy = Color(0xFF0F172A);
    const textGray = Color(0xFF64748B);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF6ED),
              Color(0xFFFFF9F3),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top Right Route Curve & Pin Background Painter
              Positioned.fill(
                child: CustomPaint(
                  painter: TopRoutePinPainter(),
                ),
              ),

              // Main Scrollable Content
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),

                          // ── Header Logo Badge ─────────────────────────────────────
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: brandOrange,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x38E8772A),
                                  blurRadius: 18,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '7s',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Header Title & Subtitle ───────────────────────────────
                          Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: textNavy,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              text: 'Join ',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textGray,
                              ),
                              children: [
                                TextSpan(
                                  text: '7s Delivery',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    color: brandOrange,
                                  ),
                                ),
                                const TextSpan(text: ' and start your journey'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Stepper Progress Line (Orange + Gray Segment)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: brandOrange,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Main Floating White Form Card ─────────────────────────
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 28,
                                  spreadRadius: 0,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Email Input Field ──────────────────────────────
                                Text(
                                  'Email Address',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textNavy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.manrope(fontSize: 15, color: textNavy),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: GoogleFonts.manrope(color: textGray.withValues(alpha: 0.7), fontSize: 14),
                                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: textGray, size: 20),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: brandOrange, width: 1.5),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty || !v.contains('@')) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 18),

                                // ── Password Input Field ───────────────────────────
                                Text(
                                  'Password',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textNavy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _isObscurePassword,
                                  style: GoogleFonts.manrope(fontSize: 15, color: textNavy),
                                  decoration: InputDecoration(
                                    hintText: 'Create a password',
                                    hintStyle: GoogleFonts.manrope(color: textGray.withValues(alpha: 0.7), fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: textGray, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isObscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: textGray,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _isObscurePassword = !_isObscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: brandOrange, width: 1.5),
                                    ),
                                  ),
                                  onChanged: (v) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Create a password';
                                    if (!_hasMinLength || !_hasUpper || !_hasLower || !_hasNumber || !_hasSpecial) {
                                      return 'Please meet all password requirements';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // ── Password Strength Checklist ──
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildChecklistItem('At least 10 characters', _hasMinLength),
                                      _buildChecklistItem('One uppercase letter', _hasUpper),
                                      _buildChecklistItem('One lowercase letter', _hasLower),
                                      _buildChecklistItem('One number', _hasNumber),
                                      _buildChecklistItem('One special character', _hasSpecial),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // ── Confirm Password Input Field ───────────────────
                                Text(
                                  'Confirm Password',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textNavy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _isObscureConfirm,
                                  style: GoogleFonts.manrope(fontSize: 15, color: textNavy),
                                  decoration: InputDecoration(
                                    hintText: 'Confirm your password',
                                    hintStyle: GoogleFonts.manrope(color: textGray.withValues(alpha: 0.7), fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: textGray, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isObscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: textGray,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: brandOrange, width: 1.5),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ── Checkbox 1: Terms of Service ───────────────────
                                GestureDetector(
                                  onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: Checkbox(
                                          value: _agreeToTerms,
                                          activeColor: brandOrange,
                                          side: const BorderSide(color: brandOrange, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => context.push('/terms'),
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'I have read and agree to the ',
                                              style: GoogleFonts.manrope(fontSize: 12, color: textNavy),
                                              children: [
                                                TextSpan(
                                                  text: 'Terms of Service',
                                                  style: GoogleFonts.manrope(
                                                    fontWeight: FontWeight.w700,
                                                    color: brandOrange,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // ── Checkbox 2: Privacy Policy ─────────────────────
                                GestureDetector(
                                  onTap: () => setState(() => _agreeToPrivacy = !_agreeToPrivacy),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: Checkbox(
                                          value: _agreeToPrivacy,
                                          activeColor: brandOrange,
                                          side: const BorderSide(color: brandOrange, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          onChanged: (v) => setState(() => _agreeToPrivacy = v ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => context.push('/privacy-policy'),
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'I have read the ',
                                              style: GoogleFonts.manrope(fontSize: 12, color: textNavy),
                                              children: [
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: GoogleFonts.manrope(
                                                    fontWeight: FontWeight.w700,
                                                    color: brandOrange,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Action: Create Account Button (Below Form Card) ───────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandOrange,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: brandOrange.withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.person_add_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Create Account',
                                          style: GoogleFonts.manrope(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Navigation: Sign In Link ─────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: textGray,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/sign-in'),
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: brandOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Top Left Floating Circular Back Button (Highest Z-Index)
              Positioned(
                top: 12,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/welcome');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: textNavy,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Background Painter for Top Right Route Curve & Map Pin Accent
class TopRoutePinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = const Color(0xFFFDBA74).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.72, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.84, size.height * 0.10,
        size.width * 0.90, size.height * 0.05,
      );

    canvas.drawPath(path, routePaint);

    final pinCenter = Offset(size.width * 0.90, size.height * 0.06);
    final pinPaint = Paint()
      ..color = const Color(0xFFE8772A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pinCenter, 10, pinPaint);
    final pinInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinCenter, 4, pinInnerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
