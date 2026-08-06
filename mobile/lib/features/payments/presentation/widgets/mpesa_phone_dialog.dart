import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 7s Mobile App — 1:1 Pixel-Perfect Redesigned M-Pesa Setup Dialog
/// Matches the reference screenshot 1:1 with soft top drag handle, soft pink/orange icon container,
/// country code dropdown pill (+254 v), green checkmark validation, saved info note, lock security badge,
/// solid primary orange Continue button, and outline Not Now button.
class MpesaPhonePromptDialog extends StatefulWidget {
  final String? initialPhone;

  const MpesaPhonePromptDialog({
    super.key,
    this.initialPhone,
  });

  /// Displays the modal dialog bottom sheet and returns the confirmed phone number string, or null if cancelled.
  static Future<String?> show(BuildContext context, {String? initialPhone}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MpesaPhonePromptDialog(initialPhone: initialPhone),
    );
  }

  @override
  State<MpesaPhonePromptDialog> createState() => _MpesaPhonePromptDialogState();
}

class _MpesaPhonePromptDialogState extends State<MpesaPhonePromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;

  static const Color primaryOrange = Color(0xFFFA5B16);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    final raw = widget.initialPhone ?? '';
    _phoneController = TextEditingController(
      text: raw.startsWith('+254') ? raw.substring(4) : (raw.startsWith('0') ? raw.substring(1) : raw),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'M-Pesa phone number is required';
    }
    final clean = val.trim().replaceAll(' ', '').replaceAll('-', '');
    final safaricomRegex = RegExp(r'^(7|1)[0-9]{8}$|^0?(7|1)[0-9]{8}$');
    if (!safaricomRegex.hasMatch(clean)) {
      return 'Enter valid Safaricom number (e.g. 712 345 678)';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      var raw = _phoneController.text.trim().replaceAll(' ', '').replaceAll('-', '');
      if (raw.startsWith('0')) {
        raw = raw.substring(1);
      }
      final formatted = '+254$raw';
      Navigator.of(context).pop(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Top Drag Handle Bar ──────────────────────────────────────────
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header Row (Soft Pink/Orange Icon Circle + Title & Description) ─
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soft Light Orange Circular Icon Container
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.smartphone_rounded,
                      color: primaryOrange,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title & Subtitle Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up M-Pesa',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Receive payments securely using STK Push from M-Pesa.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Form Input Section ───────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country Code + Phone Input Outline Container matching Screenshot 1:1
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryOrange, width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Floating Phone Number Field Label
                        Positioned(
                          top: -12,
                          left: 10,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Phone Number',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ),

                        Row(
                          children: [
                            // Country Code Dropdown Pill (+254 v)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+254',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: textMuted,
                                  size: 18,
                                ),
                              ],
                            ),

                            // Vertical Divider Line
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              width: 1,
                              height: 24,
                              color: const Color(0xFFE2E8F0),
                            ),

                            // Main Phone Number Input Field
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                autofocus: true,
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                  letterSpacing: 0.5,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '712 345 678',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                validator: _validatePhone,
                                onChanged: (val) {
                                  setState(() {});
                                },
                              ),
                            ),

                            // Green Verified Checkmark Badge
                            if (_validatePhone(_phoneController.text) == null)
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Saved For Future Payments Checkmark Row
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saved for future payments',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Encryption Security Lock Badge Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your number is securely encrypted and used only for STK Push payments.',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Primary Action Buttons ───────────────────────────────────────
            // 1. Solid Primary Orange Continue Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: primaryOrange.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Outline Not Now Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(null),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: primaryOrange, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Not now',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: primaryOrange,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
