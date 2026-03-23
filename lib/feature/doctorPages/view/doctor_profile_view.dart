import 'package:doctor_app/common/view/user_selection_view.dart';
import 'package:doctor_app/common/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'working_hours_view.dart';
import 'dart:io';

class DoctorProfilePage extends StatefulWidget {
  final String name;
  final String specialization;
  final VoidCallback onEditProfile;
  const DoctorProfilePage({
    super.key,
    required this.name,
    required this.onEditProfile,
    required this.specialization,
  });

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  String _selectedLanguage = 'English';
  File? _profileImageFile;
  final List<String> _languages = [
    'English',
    'Hindi (हिंदी)',
    'Marathi (मराठी)',
    'Kannada (ಕನ್ನಡ)',
    'Punjabi (ਪੰਜਾਬੀ)',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadSavedProfileImage();
  }

  Future<void> _loadPreferences() async {
    final storage = await StorageService.getInstance();
    setState(() {
      final langCode = storage.getLanguage();
      if (langCode.contains('hi')) {
        _selectedLanguage = 'Hindi (हिंदी)';
      } else if (langCode.contains('mr')) {
        _selectedLanguage = 'Marathi (मराठी)';
      } else if (langCode.contains('pa')) {
        _selectedLanguage = 'Punjabi (ਪੰਜਾਬੀ)';
      } else if (langCode.contains('kn')) {
        _selectedLanguage = 'Kannada (ಕನ್ನಡ)';
      } else {
        _selectedLanguage = 'English';
      }
    });
  }

  String _profileImageKey(String username) => "doctor_profile_image_$username";

  Future<void> _loadSavedProfileImage() async {
    try {
      final storage = await StorageService.getInstance();
      final profile = await storage.getCurrentUserProfile();
      final username = profile?['username'];
      if (username == null || username.isEmpty) return;
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

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_language'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A9C89),
                ),
              ),
              const SizedBox(height: 10),
              ..._languages.map((lang) => ListTile(
                    title: Text(lang,
                        style: TextStyle(
                          fontWeight: _selectedLanguage == lang
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedLanguage == lang
                              ? const Color(0xFF6A9C89)
                              : Colors.black87,
                        )),
                    trailing: _selectedLanguage == lang
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF6A9C89))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLanguage = lang;
                      });

                      StorageService.getInstance().then((storage) {
                        if (lang.contains('Hindi')) {
                          Get.updateLocale(const Locale('hi', 'IN'));
                          storage.saveLanguage('hi_IN');
                        } else if (lang.contains('Marathi')) {
                          Get.updateLocale(const Locale('mr', 'IN'));
                          storage.saveLanguage('mr_IN');
                        } else if (lang.contains('Punjabi')) {
                          Get.updateLocale(const Locale('pa', 'IN'));
                          storage.saveLanguage('pa_IN');
                        } else if (lang.contains('Kannada')) {
                          Get.updateLocale(const Locale('kn', 'IN'));
                          storage.saveLanguage('kn_IN');
                        } else {
                          Get.updateLocale(const Locale('en', 'US'));
                          storage.saveLanguage('en_US');
                        }
                      });

                      Get.back();
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Grouped data for the new layout - defined inside build for reactive translation
    final List<Map<String, dynamic>> accountItems = [
      {
        "name": "edit_your_details".tr,
        "icon": Icons.edit,
        "action": "editProfile"
      },
    ];

    final List<Map<String, dynamic>> generalItems = [
      {
        "name": "language".tr,
        "icon": Icons.language,
        "action": "language",
        "subtitle": _selectedLanguage
      },
      {
        "name": "help_support".tr,
        "icon": Icons.help_outline,
        "action": "helpSupport"
      },
    ];

    final List<Map<String, dynamic>> clinicRulesItems = [
      {
        "name": "working_hours".tr,
        "icon": Icons.schedule,
        "action": "workingHours",
        "subtitle": "working_hours_desc".tr
      },
    ];

    final List<Map<String, dynamic>> legalItems = [
      {
        "name": "privacy_policy".tr,
        "icon": Icons.privacy_tip_outlined,
        "action": "privacyPolicy"
      },
      {
        "name": "terms_and_conditions".tr,
        "icon": Icons.description_outlined,
        "action": "termsAndConditions"
      },
    ];

    final List<Map<String, dynamic>> securityItems = [
      {
        "name": "change_password".tr,
        "icon": Icons.lock_outline,
        "action": "changePassword"
      },
      {
        "name": "logout".tr,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9), // Very pale mint/white
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 60), // Space for status bar/app bar
            _buildProfileHeader(),
            SizedBox(height: 20),
            _buildSection("account".tr, accountItems),
            _buildSection("general".tr, generalItems),
            _buildSection("clinic_rules".tr, clinicRulesItems),
            _buildSection("security".tr, securityItems),
            _buildSection("about_legal".tr, legalItems),
            const SizedBox(height: 30),
            Center(
              child: Text(
                'v1.0.0 (Build 12)',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool _obscureCurrent = true;
    bool _obscureNew = true;
    bool _obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F7F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_outline,
                            color: Color(0xFF6A9C89)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'change_password'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: currentPasswordController,
                    label: 'current_password'.tr,
                    obscureText: _obscureCurrent,
                    icon: Icons.lock_clock_outlined,
                    onToggle: () => setDialogState(
                      () => _obscureCurrent = !_obscureCurrent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: newPasswordController,
                    label: 'new_password'.tr,
                    obscureText: _obscureNew,
                    icon: Icons.lock_reset_outlined,
                    onToggle: () => setDialogState(
                      () => _obscureNew = !_obscureNew,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    label: 'confirm_password'.tr,
                    obscureText: _obscureConfirm,
                    icon: Icons.verified_user_outlined,
                    onToggle: () => setDialogState(
                      () => _obscureConfirm = !_obscureConfirm,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'cancel'.tr,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final current = currentPasswordController.text.trim();
                            final newPass = newPasswordController.text.trim();
                            final confirm =
                                confirmPasswordController.text.trim();

                            if (current.isEmpty ||
                                newPass.isEmpty ||
                                confirm.isEmpty) {
                              Get.snackbar('Error', 'Please fill all fields',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.red.shade100,
                                  colorText: Colors.red.shade900);
                              return;
                            }

                            if (newPass != confirm) {
                              Get.snackbar('Error',
                                  'New password and confirm password must be same',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.red.shade100,
                                  colorText: Colors.red.shade900);
                              return;
                            }

                            final storage = await StorageService.getInstance();
                            final isCurrentCorrect =
                                await storage.verifyCurrentPassword(current);

                            if (!isCurrentCorrect) {
                              Get.snackbar(
                                  'Error', 'Current password is incorrect',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.red.shade100,
                                  colorText: Colors.red.shade900);
                              return;
                            }

                            final success = await storage.updatePassword(newPass);
                            if (success) {
                              Get.back();
                              Get.snackbar(
                                  'success'.tr, 'password_updated_success'.tr,
                                  backgroundColor: const Color(0xFFC4DAD2),
                                  colorText: Colors.black87);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A9C89),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('update'.tr,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This will permanently delete your account and local data on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final storage = await StorageService.getInstance();
    final deleted = await storage.deleteCurrentAccount();
    if (!mounted) return;
    if (deleted) {
      Get.offAll(() => const userSelectionPage());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete account.')),
      );
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required IconData icon,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6A9C89)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6A9C89), width: 1.8),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FBF9),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFC4DAD2),
                width: 3), // Soft Sage Accent border
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC4DAD2).withOpacity(0.5),
                blurRadius: 20,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFC4DAD2),
            backgroundImage:
                _profileImageFile != null ? FileImage(_profileImageFile!) : null,
            child: _profileImageFile == null
                ? Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
        ),
        SizedBox(height: 16),
        Text(
          widget.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 4),
        Text(
          widget.specialization,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F7F5), // Soft Mint
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC4DAD2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star,
                  color: const Color(0xFFDFC666), size: 18), // Soft Gold
              SizedBox(width: 6),
              Text(
                "4.8",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(width: 4),
              Text(
                "(230 reviews)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
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
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDestructive
                              ? const Color(0xFFFFF0F0)
                              : const Color(0xFFF2F7F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item["icon"],
                            size: 20,
                            color: isDestructive
                                ? const Color(0xFFFFC0C0)
                                : const Color(0xFF6A9C89)),
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
                      subtitle: item["subtitle"] != null
                          ? Text(item["subtitle"],
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500))
                          : null,
                      trailing: Icon(Icons.chevron_right,
                          size: 20, color: Colors.grey.shade400),
                      onTap: () {
                        switch (item["action"]) {
                          case "editProfile":
                            widget.onEditProfile();
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
                          case "language":
                            _showLanguageSelector();
                            break;
                          case "workingHours":
                            Get.to(() => const WorkingHoursView());
                            break;
                          case "changePassword":
                            _showChangePasswordDialog();
                            break;
                          case "privacyPolicy":
                            // Navigate to privacy policy
                            break;
                          case "termsAndConditions":
                            // Navigate to terms
                            break;
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
