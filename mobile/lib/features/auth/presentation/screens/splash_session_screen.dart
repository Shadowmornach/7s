import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/auth/presentation/coordinators/session_coordinator.dart';

/// 7s Mobile App — Splash Screen (Premium Integrated Artwork Edition)
/// The environment artwork (winding road, 7s rider, atmospheric city depth, soft sky)
/// is seamlessly integrated into the interface with zero rectangular card borders.
class SplashSessionScreen extends StatefulWidget {
  const SplashSessionScreen({super.key});

  @override
  State<SplashSessionScreen> createState() => _SplashSessionScreenState();
}

class _SplashSessionScreenState extends State<SplashSessionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const Color brandOrange = Color(0xFFFA5B16);
  static const Color textNavy = Color(0xFF0F172A);
  static const Color textGray = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Auto-restore user session after splash delay
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        context.read<AuthNotifier>().restoreSession();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: GestureDetector(
        onTap: () => context.read<AuthNotifier>().restoreSession(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFBF7),
                Color(0xFFFFF3EA),
                Color(0xFFFFFFFF),
              ],
              stops: [0.0, 0.60, 1.0],
            ),
          ),
          child: SafeArea(
            child: Consumer<AuthNotifier>(
              builder: (context, auth, child) {
                if (auth.state == AuthState.offlineWaiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: brandOrange.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wifi_off_rounded, size: 48, color: brandOrange),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Waiting for Internet Connection',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your network settings. 7s will automatically reconnect.',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: textGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    // Background Soft Atmospheric Cloud & Sun Painter
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SplashAtmospherePainter(),
                      ),
                    ),

                    // Main Composition Layout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // ── 1. Top 7s App Icon Badge ──────────────────────
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: brandOrange,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3BFA5B16),
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

                          // ── 2. Brand Title & Subtitle ────────────────────
                          Text(
                            '7s Delivery',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textNavy,
                              letterSpacing: -0.4,
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

                          const SizedBox(height: 14),

                          // Center Dot & Horizontal Accent Line Divider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 1.5,
                                color: const Color(0xFFFED7AA),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: brandOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 1.5,
                                color: const Color(0xFFFED7AA),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── 3. Full-Bleed Integrated Environment Artwork ──
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // ShaderMask Linear Opacity Dissolve for Seamless Edge Blending
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
                                          stops: [0.0, 0.05, 0.88, 1.0],
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.dstIn,
                                      child: Image.asset(
                                        'assets/images/splash_hero_seamless.png',
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/splash_hero_rider.png',
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const IntegratedSplashFallback();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // Bottom Soft Wave Accent Transition
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: 36,
                                    child: CustomPaint(
                                      painter: SplashWavePainter(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── 4. 3 Carousel Dot Indicators ────────────────
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  final delay = index * 0.33;
                                  final value = (_animController.value - delay) % 1.0;
                                  final normalized = (value < 0 ? value + 1.0 : value);
                                  final scale = 0.8 + 0.4 * (0.5 - (normalized - 0.5).abs());
                                  final isFirst = index == 0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Transform.scale(
                                      scale: isFirst ? 1.0 : scale,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: isFirst
                                              ? brandOrange
                                              : const Color(0xFFFFD8BE),
                                          shape: BoxShape.circle,
                                          boxShadow: isFirst
                                              ? [
                                                  BoxShadow(
                                                    color: brandOrange.withValues(alpha: 0.35),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── 5. Bottom Tagline Text ────────────────────────
                          Text(
                            'Fast. Reliable. Always Nearby.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your ride, our priority.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textGray,
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SplashAtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = const Color(0xFFFFF0E5).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final cloud1 = Path()
      ..addOval(Rect.fromLTWH(size.width * 0.05, size.height * 0.07, 70, 32))
      ..addOval(Rect.fromLTWH(size.width * 0.11, size.height * 0.05, 52, 28));
    canvas.drawPath(cloud1, cloudPaint);

    final cloud2 = Path()
      ..addOval(Rect.fromLTWH(size.width * 0.72, size.height * 0.10, 76, 34))
      ..addOval(Rect.fromLTWH(size.width * 0.66, size.height * 0.12, 48, 26));
    canvas.drawPath(cloud2, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IntegratedSplashFallback extends StatelessWidget {
  const IntegratedSplashFallback({super.key});

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
