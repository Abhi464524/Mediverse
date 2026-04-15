import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/config/app_colors.dart';
import '../../../common/services/storage_service.dart';
import 'appointments_view.dart';
import 'digital_prescription_view.dart';
import 'doctor_homepage_view.dart';
import 'emergency_appointments_view.dart';

class DoctorFooter extends StatefulWidget {
  final int? selectedIndex;
  const DoctorFooter({super.key, this.selectedIndex});

  @override
  State<DoctorFooter> createState() => _DoctorFooterState();
}

class _DoctorFooterState extends State<DoctorFooter> {
  // ... (keep _getDoctorProfile as is)
  Future<Map<String, String>> _getDoctorProfile() async {
    try {
      StorageService storage = await StorageService.getInstance();
      final profile = await storage.getCurrentUserProfile();
      return {
        'name': profile?['username'] ?? 'Doctor',
        'speciality': profile?['speciality'] ?? '',
      };
    } catch (e) {
      print("Error fetching doctor profile from SharedPreferences: $e");
      return {'name': 'Doctor', 'speciality': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home, "Home", () async {
              final profile = await _getDoctorProfile();
              Get.offAll(() => DoctorHomePage(
                    name: profile['name']!,
                    speciality: profile['speciality'],
                  ));
            }),
            _buildNavItem(1, Icons.receipt_long, "Rx", () {
              Get.to(() => const DigitalPrescriptionView());
            }),
            _buildNavItem(2, Icons.message_outlined, "Chat", () {}),
            _buildNavItem(3, Icons.emergency, "Emergency", () {
              Get.to(() => const EmergencyAppointmentsPage());
            }, isEmergency: true),
            _buildNavItem(4, Icons.people_alt_rounded, "Patients", () {
              Get.to(() => AppointmentsPage());
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, VoidCallback onTap,
      {bool isEmergency = false}) {
    final isSelected = widget.selectedIndex == index;
    final activeColor = isEmergency ? AppColors.emergency : AppColors.primary;
    final inactiveColor = Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
