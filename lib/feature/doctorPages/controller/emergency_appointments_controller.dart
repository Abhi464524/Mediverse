import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/emergency_appointment_model.dart';
import 'package:mediverse/feature/doctorPages/repo/appointment_repo.dart';

class EmergencyAppointmentsController extends GetxController {
  final AppointmentRepo _appointmentRepo = AppointmentRepo();

  final isLoading = false.obs;
  final error = ''.obs;
  final appointments = <EmergencyAppointmentModel>[].obs;

  final selectedDate = DateTime.now().obs;
  final searchQuery = ''.obs;

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadEmergencyAppointments({String? date, String? search}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final effectiveDate = date ?? (searchQuery.value.isEmpty ? _formatDate(selectedDate.value) : null);
      final effectiveSearch = search ?? (searchQuery.value.isNotEmpty ? searchQuery.value : null);

      final result = await _appointmentRepo.fetchEmergencyAppointments(
        date: effectiveDate,
        search: effectiveSearch,
      );
      appointments.assignAll(result);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  Future<bool> updateEmergencyAppointment(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      error.value = '';
      final response = await _appointmentRepo.updateEmergencyAppointment(data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        error.value = 'Failed to update emergency appointment: ${response.statusMessage}';
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
