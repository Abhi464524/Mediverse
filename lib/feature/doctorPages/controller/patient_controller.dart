import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import 'package:mediverse/feature/doctorPages/repo/doctor_repo.dart';

class PatientController extends GetxController {
  final DoctorRepo _doctorRepo = DoctorRepo();

  var isLoading = false.obs;
  var appointments = <AppointmentModel>[].obs;
  var error = ''.obs;

  /// Fetch appointments from backend.
  /// Pass [date] as "yyyy-MM-dd" to filter by date.
  /// Pass [search] to filter by patient name or phone.
  /// When [search] is provided, [date] is ignored (search across all dates).
  Future<void> fetchAppointments({String? date, String? search}) async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _doctorRepo.fetchAppointments(
        date: date,
        search: search,
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
