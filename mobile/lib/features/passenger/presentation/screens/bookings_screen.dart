import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// 7s Mobile App — 1:1 Pixel-Perfect Redesigned Bookings & Trip History Screen
/// Exact match to reference screenshot: Navy Title Header with Calendar-Clock Badge,
/// Floating 4-Tab Switcher Bar with Active Orange Underline Indicator,
/// Soft Peach Hero Motorcycle Landscape Empty State with Location Pin & Dotted Path,
/// Orange "Book a Ride" CTA Button, Support Help Banner, and Trip History Cards.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0; // 0 = Active Rides, 1 = Scheduled, 2 = Past Trips, 3 = Canceled

  static const Color primaryOrange = Color(0xFFFF5E00);
  static const Color bgCream = Color(0xFFFAF9F6);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textNavy = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF64748B);

  final List<Map<String, dynamic>> _activeRides = [];
  final List<Map<String, dynamic>> _scheduledRides = [
    {
      'id': 'sch_001',
      'title': 'Voi SGR Station Express',
      'dateTime': 'Tomorrow, 08:30 AM',
      'pickup': 'Voi Town Center • Posta Road',
      'dropoff': 'Voi SGR Station Terminal',
      'vehicle': 'Bodaboda Motorcycle',
      'vehicleIcon': Icons.two_wheeler_rounded,
      'fare': 'KSh 180',
      'status': 'Confirmed',
    },
  ];
  final List<Map<String, dynamic>> _pastTrips = [];
  final List<Map<String, dynamic>> _canceledTrips = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Section (Title + Calendar/Clock Badge) ───────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Bookings',
                        style: GoogleFonts.manrope(
                          color: textNavy,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View and manage your rides',
                        style: GoogleFonts.manrope(
                          color: textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Top Right Badge Container (Interactive Schedule Ride Tap)
                  InkWell(
                    onTap: () => context.push('/passenger/schedule'),
                    borderRadius: BorderRadius.circular(27),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: textNavy,
                              size: 24,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: primaryOrange,
                                  size: 12,
                                ),
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

            // ── Modern 4-Tab Switcher matching reference with Underline ────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildModernTabPill(index: 0, label: 'Active', icon: Icons.two_wheeler_outlined, count: _activeRides.length),
                    _buildModernTabPill(index: 1, label: 'Scheduled', icon: Icons.calendar_month_outlined, count: _scheduledRides.length),
                    _buildModernTabPill(index: 2, label: 'Past', icon: Icons.history_rounded, count: _pastTrips.length),
                    _buildModernTabPill(index: 3, label: 'Canceled', icon: Icons.cancel_outlined, count: _canceledTrips.length),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Main Content Body ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Expanded(
                      child: _selectedTab == 0
                          ? (_activeRides.isEmpty
                              ? _buildEmptyState(
                                  title: 'No Active Rides Right Now',
                                  subtitle: 'Book a motorcycle or cab ride in Voi Town to get moving.',
                                  icon: Icons.two_wheeler_rounded,
                                )
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _activeRides.length,
                                  itemBuilder: (context, index) => _buildTripCard(_activeRides[index]),
                                ))
                          : _selectedTab == 1
                              ? (_scheduledRides.isEmpty
                                  ? _buildEmptyState(
                                      title: 'No Scheduled Rides',
                                      subtitle: 'Schedule upcoming rides in advance from the Home Screen.',
                                      icon: Icons.calendar_month_rounded,
                                    )
                                  : ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _scheduledRides.length,
                                      itemBuilder: (context, index) => _buildScheduledRideCard(_scheduledRides[index]),
                                    ))
                              : _selectedTab == 2
                                  ? (_pastTrips.isEmpty
                                      ? _buildEmptyState(
                                          title: 'No Past Trips Found',
                                          subtitle: 'Completed ride receipts will automatically show up here.',
                                          icon: Icons.history_rounded,
                                        )
                                      : ListView.builder(
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: _pastTrips.length,
                                          itemBuilder: (context, index) => _buildTripCard(_pastTrips[index]),
                                        ))
                                  : (_canceledTrips.isEmpty
                                      ? _buildEmptyState(
                                          title: 'No Canceled Rides',
                                          subtitle: 'Canceled requests and refunds will be listed here.',
                                          icon: Icons.highlight_off_rounded,
                                        )
                                      : ListView.builder(
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: _canceledTrips.length,
                                          itemBuilder: (context, index) => _buildTripCard(_canceledTrips[index]),
                                        )),
                    ),

                    // ── Bottom Support Banner Card matching reference ────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5ED),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFFFE4D6)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Support Headset Circular Badge
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE8D6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.headset_mic_rounded,
                                color: primaryOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Need Help Text Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need help with a trip?',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Visit our Help Center for support',
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

                            // Get Help > Pill Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => context.push('/help-center'),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFFFD8BF)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x08000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Get Help',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: primaryOrange,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: primaryOrange,
                                        size: 16,
                                      ),
                                    ],
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Pill Switcher with Active Orange Underline Bar matching reference ──
  Widget _buildModernTabPill({
    required int index,
    required String label,
    required IconData icon,
    required int count,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? primaryOrange : textMuted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? primaryOrange : textMuted,
                    ),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryOrange : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Scheduled Ride Card Component ──────────────────────────────────────────
  Widget _buildScheduledRideCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE4D6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD8BF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, color: primaryOrange, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      item['dateTime'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item['status'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['pickup'] as String,
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 7),
            child: SizedBox(height: 10, child: VerticalDivider(width: 1, color: Color(0xFFCBD5E1))),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: primaryOrange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['dropoff'] as String,
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(item['vehicleIcon'] as IconData? ?? Icons.two_wheeler_rounded, color: textMuted, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    item['vehicle'] as String,
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
                  ),
                ],
              ),
              Text(
                item['fare'] as String,
                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w900, color: primaryOrange),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/driver-chat'),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                  label: Text('Chat Driver', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF0E6),
                    foregroundColor: primaryOrange,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFFFD8BF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scheduled ride modified'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('Reschedule', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: textDark)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _scheduledRides.removeWhere((r) => r['id'] == item['id']);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scheduled ride canceled'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('Cancel', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 1:1 Empty State Layout matching Reference Mockup ─────────────────────────
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Soft Peach Circular Backdrop with Motorcycle Graphic & Pin Path
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft radial background
                Container(
                  width: 220,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFF2E8).withValues(alpha: 0.9),
                        const Color(0xFFFFF7F2).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 0.75, 1.0],
                    ),
                  ),
                ),
                // City / Hill Silhouette Background
                Opacity(
                  opacity: 0.25,
                  child: Icon(
                    Icons.landscape_rounded,
                    size: 160,
                    color: const Color(0xFFFFB88C),
                  ),
                ),
                // Dotted Path Pin leading to Motorcycle
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: primaryOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x33FA5B16), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.more_vert_rounded, color: primaryOrange, size: 18),
                    const SizedBox(height: 4),
                    const Icon(Icons.two_wheeler_rounded, size: 64, color: primaryOrange),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Main Title (Navy Bold matching reference)
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textNavy,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: textMuted,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Functional Book a Ride CTA Button matching reference
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/passenger/search'),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                ),
                label: Text(
                  'Book a Ride',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: primaryOrange.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Trip Card Renderer ──────────────────────────────────────────────────────
  Widget _buildTripCard(Map<String, dynamic> trip) {
    final status = trip['status'] as String;
    final isCompleted = status == 'COMPLETED';
    final isCanceled = status == 'CANCELED';

    final Color statusBg = isCompleted
        ? const Color(0xFFDCFCE7)
        : isCanceled
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFFF0E6);

    final Color statusTextColor = isCompleted
        ? const Color(0xFF10B981)
        : isCanceled
            ? const Color(0xFFEF4444)
            : primaryOrange;

    final IconData statusIcon = isCompleted
        ? Icons.check_circle_rounded
        : isCanceled
            ? Icons.cancel_rounded
            : Icons.bolt_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: trip['iconBg'] as Color? ?? const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: trip['iconColor'] as Color? ?? const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    trip['date'],
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusTextColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trip['pickup'],
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 3.5),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(
                width: 1,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: primaryOrange, size: 14),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  trip['destination'],
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: primaryOrange, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['rider'],
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip['bike'],
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trip['fare'],
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
