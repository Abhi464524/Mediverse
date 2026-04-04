import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/emergency_appointment_model.dart';
import 'package:mediverse/feature/doctorPages/repo/doctor_repo.dart';

class EmergencyAppointmentsController extends GetxController {
  final DoctorRepo _doctorRepo = DoctorRepo();

  final isLoading = false.obs;
  final error = ''.obs;
  final appointments = <EmergencyAppointmentModel>[].obs;

  Future<void> loadEmergencyAppointments() async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _doctorRepo.fetchEmergencyAppointments();
      appointments.assignAll(result);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
