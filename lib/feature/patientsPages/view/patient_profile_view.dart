import 'package:mediverse/common/view/user_selection_view.dart';
import 'package:mediverse/common/services/storage_service.dart';
import 'package:mediverse/common/utils/language_utils.dart';
import 'package:mediverse/feature/patientsPages/view/patient_health_profile_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_notifications_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PatientProfilePage extends StatefulWidget {
  final String name;
  const PatientProfilePage({
    super.key,
    required this.name,
  });

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  String _selectedLanguage = 'English';
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImageFile;
  String? _currentUsername;
  final List<Map<String, dynamic>> healthItems = [
    {
      "name": "My health information",
      "icon": Icons.health_and_safety_outlined,
      "action": "healthProfile",
    },
  ];

  final List<Map<String, dynamic>> accountItems = [
    {
      "name": "Notifications",
      "icon": Icons.notifications_outlined,
      "action": "notifications",
    },
  ];

  final List<Map<String, dynamic>> generalItems = [
    {
      "name": "Language",
      "icon": Icons.language,
      "action": "language",
      "subtitle": "_selectedLanguage",
    },
    {
      "name": "Help & Support",
      "icon": Icons.help_outline,
      "action": "helpSupport"
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _loadSavedProfileImage();
  }

  Future<void> _loadLanguagePreference() async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedLanguage = LanguageUtils.labelFromCode(storage.getLanguage());
    });
  }

  String _profileImageKey(String username) => 'patient_profile_image_$username';

  Future<void> _loadSavedProfileImage() async {
    try {
      final storage = await StorageService.getInstance();
      final profile = await storage.getCurrentUserProfile();
      final username = profile?['username'];
      if (username == null || username.isEmpty) return;
      _currentUsername = username;
      final savedPath = storage.getString(_profileImageKey(username));
      if (savedPath == null || savedPath.isEmpty) return;
      final file = File(savedPath);
      if (!file.existsSync()) return;
      if (!mounted) return;
      setState(() {
        _profileImageFile = file;
      });
    } catch (_) {
      // Ignore failures and keep placeholder avatar.
    }
  }

  Future<void> _saveProfileImagePath(String path) async {
    final storage = await StorageService.getInstance();
    String? username = _currentUsername;
    if (username == null || username.isEmpty) {
      final profile = await storage.getCurrentUserProfile();
      username = profile?['username'];
      _currentUsername = username;
    }
    if (username == null || username.isEmpty) return;
    await storage.setString(_profileImageKey(username), path);
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;
      final file = File(pickedFile.path);
      setState(() {
        _profileImageFile = file;
      });
      await _saveProfileImagePath(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to pick image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> securityItems = [
    {
      "name": "Change Password",
      "icon": Icons.lock_open_outlined,
      "action": "changePassword"
    },
    {
      "name": "Forgot Password",
      "icon": Icons.lock_clock_rounded,
      "action": "forgotPassword"
    },
    {
      "name": "LogOut",
      "icon": Icons.logout,
      "action": "logout",
      "isDestructive": true
    },
    {
      "name": "Delete account",
      "icon": Icons.delete_forever_outlined,
      "action": "deleteAccount",
      "isDestructive": true
    },
  ];

  Future<void> _confirmDeleteAccount() async {
    final confirmController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete your account and local data on this device.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Type DELETE to confirm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
              onPressed: confirmController.text.trim().toUpperCase() == 'DELETE'
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    confirmController.dispose();
    if (confirm != true) return;
    final storage = await StorageService.getInstance();
    final deleted = await storage.deleteCurrentAccount();
    if (!mounted) return;
    if (deleted) {
      Get.offAll(() => const userSelectionPage());
      Get.snackbar(
        'Account deleted',
        'Your account has been deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete account.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Soft Slate Background
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60), // Space for status bar/app bar
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildSection("Health", healthItems),
            _buildSection("Account", accountItems),
            _buildSection("General", generalItems),
            _buildSection("Security", securityItems),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF6B9AC4),
                    width: 3), // Soft Azure Accent border
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B9AC4).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF6B9AC4),
                backgroundImage:
                    _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                child: _profileImageFile == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _showImageSourceSheet,
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF6B9AC4),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Patient",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA), // Soft Whisper White
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_rounded,
                  color: Color(0xFF6B9AC4), size: 18), // Soft Azure
              const SizedBox(width: 8),
              Text(
                "Verified Profile",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: items.map((item) {
                bool isLast = items.last == item;
                bool isDestructive = item["isDestructive"] == true;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDestructive
                              ? const Color(0xFFFFF0F0)
                              : const Color(0xFFF5F7FA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item["icon"],
                            size: 20,
                            color: isDestructive
                                ? const Color(0xFFFFC0C0)
                                : const Color(0xFF6B9AC4)),
                      ),
                      title: Text(
                        item["name"],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDestructive
                              ? Colors.red.shade400
                              : Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      subtitle: item["action"] == "language"
                          ? Text(
                              _selectedLanguage,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            )
                          : null,
                      trailing: Icon(Icons.chevron_right,
                          size: 20, color: Colors.grey.shade400),
                      onTap: () {
                        switch (item["action"]) {
                          case "healthProfile":
                            Get.to(() => const PatientHealthProfilePage());
                            break;
                          case "language":
                            LanguageUtils.showLanguageSelector(
                              context,
                              selectedLabel: _selectedLanguage,
                              accentColor: const Color(0xFF6B9AC4),
                              backgroundColor: const Color(0xFFF8FAFC),
                              onSelected: (lang) {
                                if (!mounted) return;
                                setState(() => _selectedLanguage = lang);
                              },
                            );
                            break;
                          case "notifications":
                            Get.to(() => const PatientNotificationsPage());
                            break;
                          case "logout":
                            StorageService.getInstance().then((storage) {
                              storage.clearSession();
                              Get.offAll(() => const userSelectionPage());
                            });
                            break;
                          case "deleteAccount":
                            _confirmDeleteAccount();
                            break;
                          default:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${item["name"]} — coming soon',
                                ),
                              ),
                            );
                        }
                      },
                    ),
                    if (!isLast)
                      Divider(
                          height: 1, indent: 70, color: Colors.grey.shade100),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
