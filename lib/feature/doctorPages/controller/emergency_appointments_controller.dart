import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/emergency_appointment_model.dart';

class EmergencyAppointmentsController extends GetxController {
  final isLoading = false.obs;
  final error = ''.obs;
  final appointments = <EmergencyAppointmentModel>[].obs;

  List<EmergencyAppointmentModel> _dummyEmergencyAppointments() {
    return const [
      EmergencyAppointmentModel(
        id: 'e-101',
        patientName: 'Rohit Sharma',
        time: '09:15 AM',
        diagnosis: 'Severe chest pain',
        severity: 'Critical',
        status: 'Pending',
      ),
      EmergencyAppointmentModel(
        id: 'e-102',
        patientName: 'Neha Verma',
        time: '10:05 AM',
        diagnosis: 'Breathing difficulty',
        severity: 'High',
        status: 'In Progress',
      ),
      EmergencyAppointmentModel(
        id: 'e-103',
        patientName: 'Arjun Mehta',
        time: '11:40 AM',
        diagnosis: 'Road accident trauma',
        severity: 'Critical',
        status: 'Waiting',
      ),
      EmergencyAppointmentModel(
        id: 'e-104',
        patientName: 'Kavya Nair',
        time: '01:20 PM',
        diagnosis: 'High fever with dehydration',
        severity: 'Moderate',
        status: 'Pending',
      ),
    ];
  }

  Future<void> loadEmergencyAppointments() async {
    isLoading.value = true;
    error.value = '';
    await Future<void>.delayed(const Duration(milliseconds: 250));
    appointments.assignAll(_dummyEmergencyAppointments());
    isLoading.value = false;
  }
}
