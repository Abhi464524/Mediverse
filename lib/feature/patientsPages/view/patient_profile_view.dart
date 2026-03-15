import 'package:doctor_app/common/view/user_selection_view.dart';
import 'package:doctor_app/common/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientProfilePage extends StatefulWidget {
  final String name;
  final VoidCallback onEditProfile;
  const PatientProfilePage({
    super.key,
    required this.name,
    required this.onEditProfile,
  });

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  // Grouped data for the new layout
  final List<Map<String, dynamic>> accountItems = [
    {"name": "Edit Your Details", "icon": Icons.edit, "action": "editProfile"},
  ];

  final List<Map<String, dynamic>> generalItems = [
    {"name": "Settings", "icon": Icons.settings, "action": "viewSettings"},
    {"name": "Language", "icon": Icons.language, "action": "language"},
    {
      "name": "Help & Support",
      "icon": Icons.help_outline,
      "action": "helpSupport"
    },
  ];

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
  ];

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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF6B9AC4),
                width: 3), // Soft Azure Accent border
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B9AC4).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF6B9AC4),
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
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
                  color: Colors.grey.withOpacity(0.05),
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
                          // Add other cases as needed
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
