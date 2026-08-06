import 'package:flutter/material.dart';

/// 7s Mobile App — Offers & Promo Vouchers Screen (Tab 3)
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  static const primaryOrange = Color(0xFFFF7A1A);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final TextEditingController _promoController = TextEditingController();
  String? _appliedMessage;

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == 'VOISGR' || code == 'FIRST3') {
      setState(() {
        _appliedMessage = 'Promo code $code applied! KSh 50 discount added to your next ride.';
      });
    } else {
      setState(() {
        _appliedMessage = 'Invalid promo code. Try VOISGR or FIRST3.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header Bar
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: const Text('Offers & Discounts', style: TextStyle(color: OffersScreen.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Promo Entry Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HAVE A PROMO CODE?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: OffersScreen.textMuted, letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Enter code (e.g. VOISGR)',
                                hintStyle: const TextStyle(fontSize: 13, color: OffersScreen.textMuted),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _applyPromo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: OffersScreen.primaryOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      if (_appliedMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _appliedMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _appliedMessage!.contains('applied') ? const Color(0xFF166534) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('ACTIVE VOI TOWN DISCOUNTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: OffersScreen.textMuted, letterSpacing: 0.8)),
                const SizedBox(height: 10),

                // SGR Offer Voucher
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFE0CC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: OffersScreen.primaryOrange, shape: BoxShape.circle),
                        child: const Icon(Icons.train_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Voi SGR Station Special', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: OffersScreen.textDark)),
                            SizedBox(height: 2),
                            Text('KSh 50 off all rides to/from Voi SGR Station.', style: TextStyle(fontSize: 12, color: OffersScreen.textMuted)),
                            SizedBox(height: 6),
                            Text('CODE: VOISGR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: OffersScreen.primaryOrange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // First 3 Rides Voucher
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                        child: const Icon(Icons.percent_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Welcome 20% Discount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: OffersScreen.textDark)),
                            SizedBox(height: 2),
                            Text('20% discount on your first 3 motorcycle rides in Voi.', style: TextStyle(fontSize: 12, color: OffersScreen.textMuted)),
                            SizedBox(height: 6),
                            Text('CODE: FIRST3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
