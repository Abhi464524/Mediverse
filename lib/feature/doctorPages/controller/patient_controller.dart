import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import 'package:mediverse/feature/doctorPages/repo/doctor_repo.dart';

class PatientController extends GetxController {
  final DoctorRepo _doctorRepo = DoctorRepo();

  var isLoading = false.obs;
  var appointments = <AppointmentModel>[].obs;
  var error = ''.obs;

  final selectedDate = DateTime.now().obs;
  final searchQuery = ''.obs;

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Fetch appointments from backend.
  /// Pass [date] or [search] override if needed, otherwise uses controller state.
  Future<void> fetchAppointments({String? date, String? search}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final effectiveDate = date ?? (searchQuery.value.isEmpty ? _formatDate(selectedDate.value) : null);
      final effectiveSearch = search ?? (searchQuery.value.isNotEmpty ? searchQuery.value : null);

      final result = await _doctorRepo.fetchAppointments(
        date: effectiveDate,
        search: effectiveSearch,
      );
      appointments.value = result;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addPatient(NewPatientResponse patient) async {
    try {
      isLoading.value = true;
      final response = await _doctorRepo.addPatient(patient);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Patient added successfully');
        return true;
      } else {
        Get.snackbar('Error', 'Failed to add patient: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
