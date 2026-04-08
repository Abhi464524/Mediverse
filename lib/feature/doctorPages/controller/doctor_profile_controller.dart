import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_model.dart';
import 'package:mediverse/feature/doctorPages/repo/doctor_repo.dart';

class DoctorProfileController extends GetxController {
  final DoctorRepo _doctorRepo = DoctorRepo();
  
  final RxBool isSaving = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<DoctorProfile?> doctorProfile = Rx<DoctorProfile?>(null);

  Future<DoctorProfile?> fetchDoctorProfile(int doctorId) async {
    isLoading.value = true;
    try {
      final profile = await _doctorRepo.fetchDoctorProfile(doctorId);
      doctorProfile.value = profile;
      return profile;
    } finally {
      isLoading.value = false;
    }
  }

  Future<DoctorProfile?> saveDoctorProfile(DoctorProfile profile) async {
    isSaving.value = true;
    try {
      final savedProfile = await _doctorRepo.saveDoctorProfile(profile);
      if (savedProfile != null) {
        doctorProfile.value = savedProfile;
      }
      return savedProfile;
    } finally {
      isSaving.value = false;
    }
  }
}
