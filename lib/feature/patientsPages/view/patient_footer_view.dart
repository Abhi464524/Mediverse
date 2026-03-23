import 'package:doctor_app/feature/patientsPages/view/patient_my_appointments_view.dart';
import 'package:doctor_app/feature/patientsPages/view/patient_doctors_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Patient app footer: home, appointments list, messages (appointment-focused).
class PatientFooterPage extends StatefulWidget {
  final VoidCallback? onHome;
  final VoidCallback? onAppointments;

  const PatientFooterPage({
    super.key,
    this.onHome,
    this.onAppointments,
  });

  @override
  State<PatientFooterPage> createState() => _PatientFooterPageState();
}

class _PatientFooterPageState extends State<PatientFooterPage> {
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6B9AC4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Home',
              onPressed: () {
                widget.onHome?.call();
              },
              icon: const Icon(
                Icons.home_rounded,
                size: 30,
                color: accent,
              ),
            ),
            IconButton(
              tooltip: 'My appointments',
              onPressed: () async {
                await Get.to(() => const PatientMyAppointmentsPage());
                widget.onAppointments?.call();
              },
              icon: const Icon(
                Icons.event_note_rounded,
                size: 30,
                color: accent,
              ),
            ),
            IconButton(
              tooltip: 'Doctors',
              onPressed: () async {
                await Get.to(() => const PatientDoctorsPage());
                widget.onAppointments?.call();
              },
              icon: const Icon(
                Icons.medical_services_outlined,
                size: 28,
                color: accent,
              ),
            ),
            IconButton(
              tooltip: 'Messages',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Secure messaging — available when chat is connected.'),
                  ),
                );
              },
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 28,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
