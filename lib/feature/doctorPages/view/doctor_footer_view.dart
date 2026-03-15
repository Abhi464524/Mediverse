import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/services/storage_service.dart';
import 'appointments_view.dart';
import 'digital_prescription_view.dart';
import 'doctor_homepage_view.dart';

class DoctorFooter extends StatefulWidget {
  const DoctorFooter({super.key});

  @override
  State<DoctorFooter> createState() => _DoctorFooterState();
}

class _DoctorFooterState extends State<DoctorFooter> {
  Future<String> _getDoctorName() async {
    try {
      StorageService storage = await StorageService.getInstance();
      String? doctorName = await storage.getDoctorName();
      return doctorName ?? "Doctor";
    } catch (e) {
      print("Error fetching doctor name from SharedPreferences: $e");
      return "Doctor";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F5), // Soft Mint
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () async {
              String doctorName = await _getDoctorName();
              Get.off(DoctorHomePage(name: doctorName));
            },
            icon: Icon(
              Icons.home,
              size: 30,
              color: const Color(0xFF6A9C89),
            ), // Sage Green
          ),
          // IconButton(
          //   onPressed: () {
          //     Get.to(MedicineDetails());
          //   },
          //   icon: Icon(
          //     Icons.medical_information,
          //     size: 30,
          //     color: const Color(0xFF6A9C89),
          //   ), // Sage Green
          // ),
          IconButton(
            onPressed: () {
              Get.to(() => const DigitalPrescriptionView());
            },
            icon: const Icon(
              Icons.receipt_long,
              size: 30,
              color: Color(0xFF6A9C89),
            ), // Sage Green
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.message_outlined,
              size: 30,
              color: const Color(0xFF6A9C89),
            ), // Sage Green
          ),
          IconButton(
            onPressed: () {
              Get.to(AppointmentsPage());
            },
            icon: Icon(
              Icons.event_note_rounded,
              size: 30,
              color: const Color(0xFF6A9C89),
            ), // Sage Green
          ),
        ],
      ),
    );
  }
}
