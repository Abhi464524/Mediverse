import 'package:doctor_app/common/view/user_selection_view.dart';
import 'package:doctor_app/common/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'working_hours_view.dart';

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
      {
        "name": "payment_methods".tr,
        "icon": Icons.payments_outlined,
        "action": "paymentMethods",
        "subtitle": "payment_methods_desc".tr
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('change_password'.tr,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF6A9C89))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'current_password'.tr,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'new_password'.tr,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setDialogState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'confirm_password'.tr,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child:
                  Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final current = currentPasswordController.text.trim();
                final newPass = newPasswordController.text.trim();
                final confirm = confirmPasswordController.text.trim();

                if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                  return;
                }

                if (newPass != confirm) {
                  Get.snackbar('error'.tr, 'passwords_dont_match'.tr,
                      backgroundColor: Colors.red.shade100,
                      colorText: Colors.red.shade900);
                  return;
                }

                final storage = await StorageService.getInstance();
                final isCurrentCorrect =
                    await storage.verifyCurrentPassword(current);

                if (!isCurrentCorrect) {
                  Get.snackbar('error'.tr, 'incorrect_current_password'.tr,
                      backgroundColor: Colors.red.shade100,
                      colorText: Colors.red.shade900);
                  return;
                }

                final success = await storage.updatePassword(newPass);
                if (success) {
                  Get.back();
                  Get.snackbar('success'.tr, 'password_updated_success'.tr,
                      backgroundColor: const Color(0xFFC4DAD2),
                      colorText: Colors.black87);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A9C89),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('update'.tr,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
            child: Icon(Icons.person, size: 60, color: Colors.white),
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
