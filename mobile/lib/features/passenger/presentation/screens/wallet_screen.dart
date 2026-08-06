import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/payments/presentation/widgets/mpesa_phone_dialog.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';

/// 7s Mobile App — 1:1 Pixel-Perfect Redesigned Wallet & Payments Screen
/// Matches reference screenshot 1:1 with Hero Default Card, Payment Methods,
/// Secure Payments Guarantee Card, Recent Transactions, and M-Pesa STK Push Dialog.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const Color primaryOrange = Color(0xFFFA5B16);
  static const Color bgCream = Color(0xFFFAF9F6);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textNavy = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgCream,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header Section (Title + Wallet Illustration Badge) ──────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Wallet & Payments',
                          style: GoogleFonts.manrope(
                            color: textNavy,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your payments and view\ntransaction history',
                          style: GoogleFonts.manrope(
                            color: textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),

                    // Top Right Badge Container (Wallet + Coin Graphic)
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 14,
                            spreadRadius: 0,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFFFF0E5), width: 1.5),
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: primaryOrange,
                              size: 28,
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(1),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.monetization_on_rounded,
                                  color: Color(0xFFFFB800),
                                  size: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Featured Default Payment Method Hero Card ─────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7A1A), Color(0xFFFF5500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FF7A1A),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Default Tag Translucent Pill Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                                    const SizedBox(width: 5),
                                    Text(
                                      'DEFAULT PAYMENT METHOD',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // White Circular Container with Orange Payments Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.payments_rounded,
                                    color: primaryOrange,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Main Title: Cash on Arrival
                          Text(
                            'Cash on Arrival',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Bottom Zone & Currency Info Bar
                          Row(
                            children: [
                              // Service Zone Column
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                                  const SizedBox(width: 5),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Service Zone',
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Voi Town',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Thin White Vertical Divider Line
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                width: 1,
                                height: 24,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),

                              // Currency Column
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.monetization_on_outlined, color: Colors.white70, size: 14),
                                  const SizedBox(width: 5),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Currency',
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'KSh (KES)',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 2. Payment Methods Section ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Payment Methods'),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  'Manage',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: primaryOrange,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded, color: primaryOrange, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Outer Card Container for Payment Methods
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Item 1: Cash on Arrival (Default Option)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDCFCE7)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDCFCE7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Cash on Arrival',
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: textDark,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Default',
                                              style: GoogleFonts.manrope(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pay rider directly in cash at destination',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 24,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Item 2: M-Pesa Express (STK Push) with Edit & Remove Support
                          Builder(
                            builder: (ctx) {
                              final authNotifier = ctx.watch<AuthNotifier>();
                              final currentPhone = authNotifier.currentSession?.phoneNumber;
                              final hasPhone = currentPhone != null && currentPhone.trim().isNotEmpty;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF0E6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.smartphone_rounded,
                                        color: primaryOrange,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'M-Pesa Express (STK Push)',
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hasPhone ? 'Registered: $currentPhone' : 'Direct prompt on your M-Pesa phone number',
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              color: hasPhone ? const Color(0xFF10B981) : textMuted,
                                              fontWeight: hasPhone ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    if (hasPhone) ...[
                                      // Edit Phone Number Pill / Icon
                                      InkWell(
                                        onTap: () async {
                                          final newPhone = await MpesaPhonePromptDialog.show(context, initialPhone: currentPhone);
                                          if (newPhone != null && newPhone.isNotEmpty) {
                                            authNotifier.updatePhoneNumber(newPhone);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('M-Pesa number updated to $newPhone!'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: const Color(0xFF10B981),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // Remove Phone Number Pill / Icon
                                      InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (dialogCtx) => AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              title: const Row(
                                                children: [
                                                  Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 24),
                                                  SizedBox(width: 10),
                                                  Text('Remove M-Pesa Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                ],
                                              ),
                                              content: Text(
                                                'Are you sure you want to remove your saved M-Pesa phone number ($currentPhone)?',
                                                style: const TextStyle(fontSize: 13, color: textDark),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(dialogCtx).pop(),
                                                  child: const Text('Cancel', style: TextStyle(color: textMuted)),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(dialogCtx).pop();
                                                    authNotifier.updatePhoneNumber(null);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('M-Pesa phone number removed.'),
                                                        behavior: SnackBarBehavior.floating,
                                                        backgroundColor: Color(0xFFEF4444),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFEF4444),
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                  child: const Text('Remove'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                        ),
                                      ),
                                    ] else ...[
                                      // Set Up Action Button
                                      InkWell(
                                        onTap: () async {
                                          final newPhone = await MpesaPhonePromptDialog.show(context);
                                          if (newPhone != null && newPhone.isNotEmpty) {
                                            authNotifier.updatePhoneNumber(newPhone);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('M-Pesa phone number set to $newPhone!'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: const Color(0xFF10B981),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF0E6),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFFFFD8BF)),
                                          ),
                                          child: Text(
                                            'Set Up',
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: primaryOrange,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),


                          const SizedBox(height: 8),

                          // Item 3: Secure Payments Guarantee Card
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFD1FAE5)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Secure Payments',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your payments are safe and protected\nwith bank-level security.',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: textMuted,
                                          height: 1.3,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.lock_rounded,
                                      color: primaryOrange,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 3. Recent Transactions Section ────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Recent Transactions'),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  'View all',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: primaryOrange,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded, color: primaryOrange, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Outer Card Container for Recent Transactions
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF0E6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: primaryOrange,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Transactions Yet',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your completed ride receipts and M-Pesa payments\nwill automatically appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: textMuted,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Header Accent Bar ──────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: primaryOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
      ],
    );
  }

  // ── Transaction Tile Component matching Reference Screenshot ────────────────
  Widget _buildTransactionTile({
    required String title,
    required String timeText,
    required String statusTag,
    required String amountText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.north_east_rounded,
              color: primaryOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      timeText,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: textMuted, fontSize: 11)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusTag,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amountText,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
