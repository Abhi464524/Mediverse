import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mediverse/common/services/dio/api_service.dart';
import 'package:mediverse/common/services/storage_service.dart';
import 'package:mediverse/endPoints.dart';
import 'package:mediverse/feature/doctorPages/model/emergency_appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_model.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';

class DoctorRepo {
  final DioClient _dioClient = DioClient();

  Future<String> _getDoctorId() async {
    final storage = await StorageService.getInstance();
    final profile = await storage.getCurrentUserProfile();
    return profile?['userId'] ?? '';
  }

  Future<Response> addPatient(NewPatientResponse patient) async {
    try {
      final response = await _dioClient.post(
        EndPoints.addPatientURL,
        data: patient.toJson(),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _responseToMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  Future<List<AppointmentModel>> fetchAppointments({
    String? date,
    String? search,
  }) async {
    final rawId = await _getDoctorId();
    final doctorId = int.tryParse(rawId);
    
    final queryParams = <String, dynamic>{};
    if (doctorId != null) queryParams['doctorId'] = doctorId;
    queryParams['isemergency'] = false;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    print('DEBUG APPOINTMENTS URL: ${EndPoints.doctorAppointmentsURL}?${queryParams.entries.map((e) => "${e.key}=${e.value}").join("&")}');

    final response = await _dioClient.get(
      EndPoints.doctorAppointmentsURL,
      queryParameters: queryParams,
    );
    
    print('DEBUG APPOINTMENTS RESPONSE: ${response.data}');

    final payload = response.data;
    List<dynamic> list = [];

    if (payload is List) {
      list = payload;
    } else if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) list = data;
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(AppointmentModel.fromJson)
        .toList();
  }

  Future<List<EmergencyAppointmentModel>> fetchEmergencyAppointments({
    String? date,
    String? search,
  }) async {
    final rawId = await _getDoctorId();
    final doctorId = int.tryParse(rawId);
    
    final queryParams = <String, dynamic>{};
    if (doctorId != null) queryParams['doctorId'] = doctorId;
    queryParams['isemergency'] = true;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    
    final response = await _dioClient.get(
      EndPoints.emergencyAppointmentsURL,
      queryParameters: queryParams,
    );
    
    final payload = response.data;
    List<dynamic> list = [];

    if (payload is List) {
      list = payload;
    } else if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) list = data;
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(EmergencyAppointmentModel.fromJson)
        .toList();
  }

  Future<DoctorProfile?> fetchDoctorProfile(int doctorId) async {
    try {
      final response = await _dioClient.get(
        EndPoints.doctorProfileURL,
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
