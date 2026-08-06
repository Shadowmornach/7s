import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// 7s Mobile Client — Sign In Screen
/// Rebuilt to match the new reference visual design specs EXACTLY.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final authNotifier = context.read<AuthNotifier>();
    try {
      await authNotifier.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        context.go('/passenger/home');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Invalid credentials. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleSubmitting) return;

    // Show Google Account Chooser bottom sheet matching official Google OAuth dark theme specs
    final selectedAccount = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle Bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header: Google G Icon + Sign in with Google
              Row(
                children: [
                  const MultiColorGoogleIcon(size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title: Choose an account
              Text(
                'Choose an account',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: 'to continue to ',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  children: [
                    TextSpan(
                      text: '7s Delivery',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF818CF8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Clean Account Entry Prompt
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Select your Google account to sign in securely.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFF1E293B)),

              // Account 3: Use another account
              InkWell(
                onTap: () async {
                  final inputController = TextEditingController();
                  final customEmail = await showDialog<String>(
                    context: ctx,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Use another account', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: TextFormField(
                        controller: inputController,
                        style: GoogleFonts.manrope(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your Google email',
                          hintStyle: GoogleFonts.manrope(color: const Color(0xFF64748B)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF818CF8))),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(null),
                          child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF94A3B8))),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(inputController.text.trim()),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8772A)),
                          child: Text('Continue', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (customEmail != null && customEmail.isNotEmpty) {
                    Navigator.of(ctx).pop({
                      'email': customEmail,
                      'name': customEmail.split('@')[0],
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_circle_outlined,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Use another account',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Footer Legal Text
              Text(
                'Before using this app, you can review 7s\'s Privacy Policy and Terms of Service.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selectedAccount == null) return;

    setState(() => _isGoogleSubmitting = true);
    try {
      final email = selectedAccount['email']!;
      final name = selectedAccount['name']!;
      final idToken = 'id_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      final authNotifier = context.read<AuthNotifier>();
      await authNotifier.signInWithGoogle(
        idToken: idToken,
        email: email,
        displayName: name,
      );

      if (mounted) {
        if (!authNotifier.isProfileComplete) {
          context.go('/complete-profile');
        } else {
          context.go('/passenger/home');
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Google Sign-In failed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
    }
  }

  void _handleForgotPassword() {
    context.push('/forgot-password');
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
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: textNavy,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to continue your journey',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textGray,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Orange Center Dot Divider
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: brandOrange,
                              shape: BoxShape.circle,
                            ),
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
                                    hintText: 'shadow@example.com',
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
                                  obscureText: _isObscure,
                                  style: GoogleFonts.manrope(fontSize: 15, color: textNavy),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: GoogleFonts.manrope(color: textGray.withValues(alpha: 0.7), fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: textGray, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: textGray,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _isObscure = !_isObscure),
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
                                    if (v == null || v.isEmpty) {
                                      return 'Enter your password';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // ── Remember Me & Forgot Password Row ──────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: brandOrange,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Remember Me',
                                            style: GoogleFonts.manrope(
                                              fontSize: 13,
                                              color: textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _handleForgotPassword,
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: brandOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // ── Action 1: Sign In Button ────────────────────────
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _isSubmitting ? null : _handleSignIn,
                                    icon: _isSubmitting
                                        ? const SizedBox.shrink()
                                        : const Icon(
                                            Icons.lock_outline_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                    label: _isSubmitting
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: GoogleFonts.manrope(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: brandOrange,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: brandOrange.withValues(alpha: 0.35),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ── "OR" Divider Line ───────────────────────────────
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Text(
                                        'OR',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textGray.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // ── Action 2: Continue with Google Button ───────────
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: _isGoogleSubmitting ? null : _handleGoogleSignIn,
                                    icon: _isGoogleSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: brandOrange,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const MultiColorGoogleIcon(size: 22),
                                    label: Text(
                                      'Continue with Google',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textNavy,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ── Navigation: Create Account Link ─────────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        color: textGray,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push('/sign-up'),
                                      child: Text(
                                        'Create Account',
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

                                // ── Footer: Terms & Privacy ─────────────────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: brandOrange,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'By continuing you agree to our ',
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              color: textGray,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => context.push('/terms'),
                                            child: Text(
                                              'Terms & Conditions',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: textNavy,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            ' | ',
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              color: textGray,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => context.push('/privacy-policy'),
                                            child: Text(
                                              'Privacy Policy',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: textNavy,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

/// Custom 4-Color Google "G" Icon Widget matching official Google logo design specs.
class MultiColorGoogleIcon extends StatelessWidget {
  final double size;
  const MultiColorGoogleIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GoogleGLogoPainter(),
      ),
    );
  }
}

class GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw Google G Arcs
    canvas.drawArc(rect, -0.4, 1.6, false, bluePaint);
    canvas.drawArc(rect, 1.2, 1.2, false, greenPaint);
    canvas.drawArc(rect, 2.4, 1.1, false, yellowPaint);
    canvas.drawArc(rect, 3.5, 1.3, false, redPaint);

    // Draw Blue Horizontal Crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(center.dx - strokeWidth / 2, center.dy - strokeWidth / 2, radius * 0.85, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Background Painter for Top Right Route Curve & Map Pin Accent
class TopRoutePinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top right route curve line
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

    // Orange location map pin head in top right
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
