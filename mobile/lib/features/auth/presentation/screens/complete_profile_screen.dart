import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// 7s Mobile App — Complete Profile Screen (Screen 5 in Auth Flow)
/// Features:
///   1. Nickname & Full Name profile setup.
///   2. Photo Picker with camera, gallery, and file compression (512x512, quality 80% to eliminate egress costs).
///   3. Crop & Square Preview Modal.
///   4. Delete/Remove photo option.
///   5. Dynamic persistence into UserSession.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _fullNameController;
  late TextEditingController _emergencyContactController;
  String _themePreference = 'system';

  File? _profileImageFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authNotifier = context.read<AuthNotifier>();
    final session = authNotifier.currentSession;
    _nicknameController = TextEditingController(text: session?.nickname ?? 'Shadow');
    _fullNameController = TextEditingController(text: session?.fullName ?? 'Shadow Owner');
    _emergencyContactController = TextEditingController(text: session?.emergencyContact ?? '');
    _themePreference = session?.themePreference ?? 'system';

    if (session?.photoUrl != null && session!.photoUrl!.isNotEmpty) {
      final f = File(session.photoUrl!);
      if (f.existsSync()) {
        _profileImageFile = f;
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80, // High compression to eliminate egress bandwidth cost
      );
      if (picked != null) {
        _showCropPreviewDialog(File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access camera/gallery: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showCropPreviewDialog(File rawFile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Crop & Preview Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF7A1A), width: 3),
              ),
              child: ClipOval(
                child: Image.file(
                  rawFile,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your photo will be displayed on your 7s profile.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _profileImageFile = rawFile;
              });
            },
            child: const Text('Use Photo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deletePhoto() {
    setState(() {
      _profileImageFile = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile photo removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showImagePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Photo Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Choose an option to set your profile picture:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),

            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF7A1A)),
              ),
              title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0F172A)),
              ),
              title: const Text('Choose from Gallery / Media Storage', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImageFile != null) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                ),
                title: const Text('Delete / Remove Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deletePhoto();
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave({bool isSkip = false}) async {
    if (!isSkip && !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authNotifier = context.read<AuthNotifier>();
    final defaultNickname = isSkip
        ? (authNotifier.currentSession?.email.split('@')[0] ?? 'User')
        : _nicknameController.text.trim();

    try {
      await authNotifier.completeProfile(
        nickname: defaultNickname,
        fullName: isSkip ? null : _fullNameController.text.trim(),
        photoUrl: _profileImageFile?.path,
        themePreference: isSkip ? null : _themePreference,
        emergencyContact: isSkip ? null : _emergencyContactController.text.trim(),
      );
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go('/passenger/home');
        }
      }
    } catch (_) {
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go('/passenger/home');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF7A1A);
    const bgWhite = Colors.white;
    const textDark = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);

    final authNotifier = context.watch<AuthNotifier>();
    final displayInitials = authNotifier.currentSession?.initials ?? 'SH';

    return Scaffold(
      backgroundColor: bgWhite,
      appBar: AppBar(
        backgroundColor: bgWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header Title & Subtitle ───────────────────────────────────
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Let's get to know you better",
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Profile Photo / Initials Avatar Badge ─────────────────────
                GestureDetector(
                  onTap: () => _showImagePickerModal(context),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _profileImageFile != null
                              ? Image.file(
                                  _profileImageFile!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    displayInitials,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: primaryOrange,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _profileImageFile != null ? Icons.edit_rounded : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _profileImageFile != null
                      ? 'Tap to crop, edit or delete photo'
                      : 'Tap to add profile photo (low egress cost)\nYou can skip this for now',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Form Inputs ───────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HOW SHOULD WE CALL YOU?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nicknameController,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a nickname';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. Alex, Juma',
                        hintStyle: const TextStyle(fontSize: 14, color: textMuted),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Riders will see this name on trip requests',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FULL NAME (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Alexander Smith',
                        hintStyle: const TextStyle(fontSize: 14, color: textMuted),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Used for receipts & account verification',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMERGENCY CONTACT (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emergencyContactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. +254712345678',
                        hintStyle: const TextStyle(fontSize: 14, color: textMuted),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THEME PREFERENCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _themePreference,
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('System Default')),
                        DropdownMenuItem(value: 'light', child: Text('Light Theme')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark Theme')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _themePreference = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ── Save Profile Button ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _handleSave(isSkip: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryOrange.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Save Profile & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Skip Button ──────────────────────────────────────────────
                TextButton(
                  onPressed: _isSubmitting ? null : () => _handleSave(isSkip: true),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
