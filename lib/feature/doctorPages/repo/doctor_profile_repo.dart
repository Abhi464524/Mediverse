import 'package:flutter/foundation.dart';
import 'package:mediverse/common/services/dio/api_service.dart';
import 'package:mediverse/endPoints.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_model.dart';

class DoctorProfileRepo {
  final DioClient _dioClient = DioClient();

  Future<DoctorProfile?> fetchDoctorProfile(int doctorId) async {
    try {
      final response = await _dioClient.get(
        EndPoints.doctorGetProfileURL,
        queryParameters: {'doctorId': doctorId},
      );
      if (response.data != null) {
        // Handle different response formats (naked object or wrapped in 'data')
        final payload = response.data is Map<String, dynamic> &&
                response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return DoctorProfile.fromJson(payload);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("Error fetching doctor profile: $e");
      return null;
    }
  }

  Future<DoctorProfile?> saveDoctorProfile(DoctorProfile profile) async {
    try {
      final response = await _dioClient.post(
        EndPoints.doctorProfileURL,
        data: profile.toJson(),
      );
      if (response.data != null) {
        // Handle potential data wrapping
        final payload = response.data is Map<String, dynamic> &&
                response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return DoctorProfile.fromJson(payload);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("Error saving doctor profile: $e");
      return null;
    }
  }
}
