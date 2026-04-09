import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/emergency_appointment_model.dart';
import 'package:mediverse/feature/doctorPages/repo/doctor_repo.dart';

class EmergencyAppointmentsController extends GetxController {
  final DoctorRepo _doctorRepo = DoctorRepo();

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

      final result = await _doctorRepo.fetchEmergencyAppointments(
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
}
