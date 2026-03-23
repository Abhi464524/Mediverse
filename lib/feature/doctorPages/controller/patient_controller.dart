import 'package:get/get.dart';
import 'package:doctor_app/feature/doctorPages/model/patient_model.dart';
import 'package:doctor_app/feature/doctorPages/repo/doctor_repo.dart';

class PatientController extends GetxController {
  final DoctorRepo _doctorRepo = DoctorRepo();
  
  var isLoading = false.obs;

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
