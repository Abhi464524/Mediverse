import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/config/app_colors.dart';
import '../../../common/services/storage_service.dart';
import 'appointments_view.dart';
import 'digital_prescription_view.dart';
import 'doctor_homepage_view.dart';
import 'emergency_appointments_view.dart';

class DoctorFooter extends StatefulWidget {
  const DoctorFooter({super.key});

  @override
  State<DoctorFooter> createState() => _DoctorFooterState();
}

class _DoctorFooterState extends State<DoctorFooter> {
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
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () async {
              final profile = await _getDoctorProfile();
              Get.offAll(() => DoctorHomePage(
                name: profile['name']!,
                speciality: profile['speciality'],
              ));
            },
            icon: Icon(
              Icons.home,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            onPressed: () {
              Get.to(() => const DigitalPrescriptionView());
            },
            icon: const Icon(
              Icons.receipt_long,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.message_outlined,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            onPressed: () {
              Get.to(() => const EmergencyAppointmentsPage());
            },
            icon: const Icon(
              Icons.emergency,
              size: 30,
              color: AppColors.emergency,
            ),
          ),
          IconButton(
            onPressed: () {
              Get.to(() => AppointmentsPage());
            },
            icon: Icon(
              Icons.people_alt_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
