import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_update_model.dart';
import 'package:mediverse/feature/doctorPages/repo/doctor_repo.dart';

class DoctorProfileController extends GetxController {
  final DoctorRepo _repo = DoctorRepo();
  final isSaving = false.obs;

  Future<DoctorProfileUpdateResponse?> saveDoctorProfile(
    DoctorProfileUpdateRequest request,
  ) async {
    try {
      isSaving.value = true;
      final response = await _repo.saveDoctorProfile(request);
      return response;
    } catch (e) {
      debugPrint('DoctorProfileController.saveDoctorProfile error: $e');
      return null;
    } finally {
      isSaving.value = false;
    }
  }

}
