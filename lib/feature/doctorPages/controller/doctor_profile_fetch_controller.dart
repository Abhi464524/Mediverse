import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_fetch_model.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_update_model.dart';
import 'package:mediverse/feature/doctorPages/repo/doctor_repo.dart';

class DoctorProfileFetchController extends GetxController {
  final DoctorRepo _repo = DoctorRepo();
  final isFetching = false.obs;

  Future<DoctorProfileFetchResponse?> fetchDoctorProfile(
    DoctorProfileFetchRequest request, {
    DoctorProfileUpdateRequest? fallbackRequest,
  }) async {
    try {
      isFetching.value = true;
      final response = await _repo.fetchDoctorProfile(
        request.doctorId,
        fallbackRequest: fallbackRequest,
      );
      return response;
    } catch (e) {
      debugPrint('DoctorProfileFetchController.fetchDoctorProfile error: $e');
      return null;
    } finally {
      isFetching.value = false;
    }
  }
}
