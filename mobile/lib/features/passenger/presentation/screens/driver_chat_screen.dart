import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 7s Mobile App — Live Driver Chat Screen
class DriverChatScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;
  final String vehiclePlate;

  const DriverChatScreen({
    super.key,
    this.driverName = 'Juma Omondi',
    this.driverPhone = '+254712345678',
    this.vehiclePlate = 'KMF 482B (Bodaboda)',
  });

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  static const primaryOrange = Color(0xFFFA5B16);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'text': 'Habari! I have accepted your scheduled Bodaboda ride. I will arrive 10 minutes before pickup time in Voi.',
      'isDriver': true,
      'time': '10:14 AM',
    },
    {
      'id': '2',
      'text': 'Asante! Please bring an extra passenger helmet.',
      'isDriver': false,
      'time': '10:15 AM',
    },
    {
      'id': '3',
      'text': 'Sawakabisa! Clean helmet will be ready for you.',
      'isDriver': true,
      'time': '10:15 AM',
    },
  ];

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'isDriver': false,
        'time': 'Just now',
      });
    });

    if (quickText == null) {
      _messageController.clear();
    }
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFF0E6),
              child: Text(
                widget.driverName[0],
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: primaryOrange),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.driverName,
                    style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: textDark),
                  ),
                  Text(
                    widget.vehiclePlate,
                    style: GoogleFonts.manrope(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: primaryOrange),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling driver ${widget.driverName} (${widget.driverPhone})...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scheduled Ride Info Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF0E6),
              child: Row(
                children: [
                  const Icon(Icons.two_wheeler_rounded, color: primaryOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduled Bodaboda Ride • Driver Assigned',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: primaryOrange),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (ctx, index) {
                  final msg = _messages[index];
                  final bool isDriver = msg['isDriver'] as bool;

                  return Align(
                    alignment: isDriver ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDriver ? Colors.white : primaryOrange,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isDriver ? 4 : 18),
                          bottomRight: Radius.circular(isDriver ? 18 : 4),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: isDriver ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: isDriver ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          Text(
                            msg['text'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: isDriver ? textDark : Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDriver ? const Color(0xFF94A3B8) : const Color(0xFFFFD8BF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick Reply Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildQuickChip('I am at pickup location'),
                  const SizedBox(width: 8),
                  _buildQuickChip('Running 5 mins late'),
                  const SizedBox(width: 8),
                  _buildQuickChip('Please bring helmet'),
                ],
              ),
            ),

            // Bottom Text Field Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.manrope(fontSize: 14, color: textDark),
                      decoration: InputDecoration(
                        hintText: 'Message driver...',
                        hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _sendMessage(),
                    icon: const Icon(Icons.send_rounded, color: primaryOrange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: textDark)),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _sendMessage(label),
    );
  }
}
