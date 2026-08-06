import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 7s Mobile — Full Screen Notifications & Alerts Center Screen
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const primaryOrange = Color(0xFFFA5B16);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Welcome to 7s Voi Town!',
      'body': 'Your account is ready. Book your first Bodaboda or Cab ride anytime across Voi Town.',
      'time': 'Just now',
      'icon': Icons.stars_rounded,
      'iconBg': Color(0xFFFFF0E6),
      'iconColor': primaryOrange,
      'isUnread': true,
    },
    {
      'id': '2',
      'title': 'M-Pesa STK Security Active',
      'body': 'Your payments are encrypted and processed safely directly via Safaricom M-Pesa.',
      'time': '2 hours ago',
      'icon': Icons.shield_rounded,
      'iconBg': Color(0xFFDCFCE7),
      'iconColor': Color(0xFF10B981),
      'isUnread': true,
    },
    {
      'id': '3',
      'title': 'Scheduled Rides Available',
      'body': 'Planning ahead? You can now schedule rides in advance for SGR trips and morning commutes.',
      'time': 'Yesterday',
      'icon': Icons.calendar_month_rounded,
      'iconBg': Color(0xFFEFF6FF),
      'iconColor': Color(0xFF3B82F6),
      'isUnread': false,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item['isUnread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.manrope(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all read',
              style: GoogleFonts.manrope(
                color: primaryOrange,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0E6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_off_rounded, color: primaryOrange, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Notifications Yet',
                      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We will notify you here about trip updates & safety alerts.',
                      style: GoogleFonts.manrope(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = _notifications[index];
                  final bool isUnread = item['isUnread'] as bool;

                  return Container(
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.white : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isUnread ? const Color(0xFFFFE3D1) : const Color(0xFFE2E8F0),
                        width: isUnread ? 1.5 : 1.0,
                      ),
                      boxShadow: isUnread
                          ? const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item['iconBg'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['iconColor'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: textDark,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: primaryOrange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['body'] as String,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: textMuted,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['time'] as String,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
