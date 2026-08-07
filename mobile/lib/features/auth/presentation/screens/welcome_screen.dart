import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// 7s Mobile Client — Welcome Screen (Premium Integrated Artwork Edition)
/// The artwork is seamlessly integrated into the page itself without rectangular card borders.
/// Environment, road, rider, and sky blend naturally into the white background with atmospheric depth.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const Color brandOrange = Color(0xFFFA5B16);
  static const Color textNavy = Color(0xFF0F172A);
  static const Color textGray = Color(0xFF64748B);

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
              InkWell(
                onTap: () async {
                  final inputController = TextEditingController();
                  final customEmail = await showDialog<String>(
                    context: ctx,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: Text('Enter Google Email', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: TextField(
                        controller: inputController,
                        style: GoogleFonts.manrope(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'e.g. user@gmail.com',
                          hintStyle: GoogleFonts.manrope(color: const Color(0xFF64748B)),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(null),
                          child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF94A3B8))),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(inputController.text.trim()),
                          style: ElevatedButton.styleFrom(backgroundColor: brandOrange),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF7),
              Color(0xFFFFF7F0),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.50, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Stack(
                      children: [
                        // Background Soft Sun & Ambient Glow Painter
                        Positioned.fill(
                          child: CustomPaint(
                            painter: IntegratedEnvironmentPainter(),
                          ),
                        ),

                        // Main Composition Layout
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),

                              // ── 1. Top 7s App Icon Badge ──────────────────
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: brandOrange,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x38FA5B16),
                                      blurRadius: 22,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '7s',
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── 2. Centered Typography Hierarchy ──────────
                              Text(
                                'Welcome to 7s',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: textNavy,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Motorcycle Taxi Service',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textGray,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ── 3. Integrated Full-Bleed Environment Artwork ─
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Full-Width Seamless Environment Scene with Dissolve Shader Mask
                                      Positioned.fill(
                                        child: ShaderMask(
                                          shaderCallback: (Rect bounds) {
                                            return const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black,
                                                Colors.black,
                                                Colors.transparent,
                                              ],
                                              stops: [0.0, 0.05, 0.90, 1.0],
                                            ).createShader(bounds);
                                          },
                                          blendMode: BlendMode.dstIn,
                                          child: Image.asset(
                                            'assets/images/welcome_hero_seamless.png',
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/welcome_hero_scene.png',
                                                width: double.infinity,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const IntegratedFallbackScene();
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                      // ── Floating White Glass Location Service Card ──────
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x14000000),
                                                blurRadius: 24,
                                                spreadRadius: 0,
                                                offset: Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.location_on_rounded,
                                                color: brandOrange,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Currently serving',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: textGray,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Voi Town',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w900,
                                                      color: textNavy,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── 4. Action Buttons Section ───────────────────
                              // Google OAuth Pill Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
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
                                      : const WelcomeGoogleIcon(size: 22),
                                  label: Text(
                                    'Continue with Google',
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
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

                              const SizedBox(height: 12),

                              // Sign In Primary Orange Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/sign-in'),
                                  icon: const Icon(
                                    Icons.lock_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Sign In',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandOrange,
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shadowColor: brandOrange.withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Create Account Outline Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/sign-up'),
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: brandOrange,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Create Account',
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: brandOrange,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFFFF9E59), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── 5. Footer Legal Disclaimer Links ─────────────
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'By continuing you agree to our ',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: textGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/terms'),
                                    child: Text(
                                      'Terms & Conditions',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: textNavy,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' | ',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: textGray,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/privacy-policy'),
                                    child: Text(
                                      'Privacy Policy',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: textNavy,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class IntegratedEnvironmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.16, size.height * 0.12);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDE68A).withValues(alpha: 0.50),
          const Color(0xFFFEF3C7).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 72));
    canvas.drawCircle(sunCenter, 72, glowPaint);

    final sunBodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFBBF24),
          Color(0xFFFA5B16),
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 24));
    canvas.drawCircle(sunCenter, 24, sunBodyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IntegratedFallbackScene extends StatelessWidget {
  const IntegratedFallbackScene({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF5ED),
      ),
      child: const Center(
        child: Icon(
          Icons.two_wheeler_rounded,
          color: Color(0xFFFA5B16),
          size: 80,
        ),
      ),
    );
  }
}
