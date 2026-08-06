import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/voi_town_landmarks.dart';

/// 7s Mobile App — Pixel-Perfect Redesigned Schedule a Boda Ride Screen
/// Matches reference design 1:1 with Hero Rider Banner, Pickup/Destination Location Cards,
/// Date/Time Dropdown Selectors, Ride Options (Fastest/Standard/Economy),
/// Payment Method Selectors (M-Pesa/Cash/Wallet), Scheduled & Secure Banner, and Schedule Ride CTA.
class ScheduleRideScreen extends StatefulWidget {
  const ScheduleRideScreen({super.key});

  @override
  State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends State<ScheduleRideScreen> {
  static const Color primaryOrange = Color(0xFFFA5B16);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color bgCream = Color(0xFFF8FAFC);

  String _pickupLocationTitle = 'Voi Town Center';
  String _pickupLocationSubtitle = 'Opposite Voi Town Market';

  String _destinationLocationTitle = 'Where are you going?';
  String _destinationLocationSubtitle = 'Select destination in Voi';

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 30);

  String _selectedRideOption = 'Fastest'; // 'Fastest', 'Standard', 'Economy'
  String _selectedPaymentMethod = 'M-Pesa STK Push'; // 'M-Pesa STK Push', 'Cash', 'Wallet'

  int _calculatedFare = 180;

  void _recalculateFare() {
    if (_destinationLocationTitle == 'Where are you going?') {
      _calculatedFare = 150;
      return;
    }

    int base = 150;
    if (_destinationLocationTitle.contains('SGR') || _pickupLocationTitle.contains('SGR')) {
      base = 200;
    } else if (_destinationLocationTitle.contains('Hospital') || _destinationLocationTitle.contains('TTU')) {
      base = 180;
    }

    if (_selectedRideOption == 'Fastest') {
      _calculatedFare = base + 30;
    } else if (_selectedRideOption == 'Economy') {
      _calculatedFare = base - 20;
    } else {
      _calculatedFare = base;
    }
  }

  void _showLocationPickerModal({required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final matchingLandmarks = VoiTownLandmarksData.filterLandmarks(searchQuery);

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPickup ? 'Select Pickup Location' : 'Select Destination Location',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: TextField(
                      onChanged: (val) {
                        setModalState(() => searchQuery = val);
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          isPickup ? Icons.my_location_rounded : Icons.location_on_rounded,
                          color: isPickup ? const Color(0xFF10B981) : primaryOrange,
                        ),
                        hintText: 'Search Voi landmarks & areas...',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: matchingLandmarks.length,
                      itemBuilder: (context, index) {
                        final item = matchingLandmarks[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isPickup ? Icons.my_location_rounded : Icons.location_on_rounded,
                              color: primaryOrange,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: GoogleFonts.manrope(fontSize: 12, color: textMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: textMuted),
                          onTap: () {
                            setState(() {
                              if (isPickup) {
                                _pickupLocationTitle = item.title;
                                _pickupLocationSubtitle = item.subtitle;
                              } else {
                                _destinationLocationTitle = item.title;
                                _destinationLocationSubtitle = item.subtitle;
                              }
                              _recalculateFare();
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule a Boda Ride',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            Text(
              'Plan your ride in advance',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Rider Banner Card ──────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF4EC), Color(0xFFFFE5D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFD8BF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Motorcycle Icon Container
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: primaryOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33FA5B16),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),

                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '7s Express BodaBoda',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Fast, reliable motorcycle rides anywhere in Voi Town',
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

                    // Delivery Rider Badge Graphic
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '7s',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── 2. Pickup Location Selection Card ──────────────────────────
              Text(
                'Pickup Location',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showLocationPickerModal(isPickup: true),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickupLocationTitle,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _pickupLocationSubtitle,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: textMuted, size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── 3. Destination Location Selection Card ─────────────────────
              Text(
                'Destination Location',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showLocationPickerModal(isPickup: false),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF0E6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: primaryOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _destinationLocationTitle,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _destinationLocationTitle == 'Where are you going?' ? textMuted : textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_destinationLocationTitle != 'Where are you going?') ...[
                              const SizedBox(height: 2),
                              Text(
                                _destinationLocationSubtitle,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: textMuted, size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── 4. Schedule Date & Time Selectors ──────────────────────────
              Text(
                'Schedule Date & Time',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Date Dropdown Selector Pill
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: primaryOrange, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedDate.day} ${_monthAbbrev(_selectedDate.month)} ${_selectedDate.year}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: textMuted, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Time Dropdown Selector Pill
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_filled_rounded, color: primaryOrange, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime.format(context),
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: textMuted, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── 5. Ride Options Selector (Fastest / Standard / Economy) ──────
              Text(
                'Ride Options',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRideOptionChip('Fastest', Icons.bolt_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRideOptionChip('Standard', Icons.two_wheeler_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRideOptionChip('Economy', Icons.eco_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── 6. Payment Method Selector ─────────────────────────────────
              Text(
                'Payment Method',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodChip('M-Pesa STK Push', Icons.check_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPaymentMethodChip('Cash', Icons.payments_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPaymentMethodChip('Wallet', Icons.account_balance_wallet_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── 7. Scheduled & Secure Guarantee Banner ───────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5EE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFE4D6)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE8D6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: primaryOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled & Secure',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "We'll notify you and your rider, so you're always on time and safe.",
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 8. Schedule Ride CTA Primary Button & Charging Subtitle ─────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final pickup = _pickupLocationTitle;
                    final dest = _destinationLocationTitle == 'Where are you going?'
                        ? 'Voi Town Destination'
                        : _destinationLocationTitle;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bodaboda Ride scheduled for $pickup ➔ $dest on ${_selectedDate.day}/${_selectedDate.month} at ${_selectedTime.format(context)} (KSh $_calculatedFare)!',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primaryOrange.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Schedule Ride',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  "You'll be charged only after your ride is completed.",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ride Options Chip Builder ──────────────────────────────────────────────
  Widget _buildRideOptionChip(String label, IconData icon) {
    final bool isSelected = _selectedRideOption == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRideOption = label;
          _recalculateFare();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0E6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryOrange : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? primaryOrange : textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primaryOrange : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Payment Method Chip Builder ────────────────────────────────────────────
  Widget _buildPaymentMethodChip(String label, IconData icon) {
    final bool isSelected = _selectedPaymentMethod == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryOrange : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x22FA5B16),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : primaryOrange,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthAbbrev(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
