import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mediverse/common/services/dio/api_service.dart';
import 'package:mediverse/common/services/storage_service.dart';
import 'package:mediverse/endPoints.dart';
import 'package:mediverse/feature/doctorPages/model/emergency_appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_fetch_model.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_update_model.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
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

  Future<DoctorProfileUpdateResponse> saveDoctorProfile(
    DoctorProfileUpdateRequest request,
  ) async {
    final response = await _dioClient.post(
      EndPoints.doctorProfileURL,
      data: request.toJson(),
    );
    final map = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    return DoctorProfileUpdateResponse.fromJson(map);
  }

  Future<DoctorProfileFetchResponse?> fetchDoctorProfile(
    int doctorId, {
    DoctorProfileUpdateRequest? fallbackRequest,
  }) async {
    final path = EndPoints.doctorProfileURL;
    try {
      final response = await _dioClient.get(
        path,
        queryParameters: {"doctorId": doctorId},
      );
      final map = _responseToMap(response.data);
      return DoctorProfileFetchResponse.fromJson(map);
    } catch (getError) {
      debugPrint('fetchDoctorProfile GET failed: $getError');
      if (fallbackRequest == null) {
        // Do not POST with only doctorId on page open.
        return null;
      }
      try {
        // Some backends expose fetch on POST. If so, send full payload
        // to avoid overwriting existing fields with nulls.
        final postData = fallbackRequest.toJson();
        final response = await _dioClient.post(
          path,
          data: postData,
        );
        final map = _responseToMap(response.data);
        return DoctorProfileFetchResponse.fromJson(map);
      } catch (postError) {
        debugPrint('fetchDoctorProfile POST fallback failed: $postError');
        return null;
      }
    }
  }

  Map<String, dynamic> _responseToMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  /// Fetches appointments with optional date and search filters.
  /// [date] — "yyyy-MM-dd" format. [search] — patient name or phone.
  Future<List<AppointmentModel>> fetchAppointments({
    String? date,
    String? search,
  }) async {
    final doctorId = await _getDoctorId();
    final queryParams = <String, dynamic>{};
    if (doctorId.isNotEmpty) queryParams['doctor_id'] = doctorId;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dioClient.get(
      EndPoints.doctorAppointmentsURL,
      queryParameters: queryParams,
    );
    final payload = response.data;

    List<dynamic> list;
    if (payload is List) {
      list = payload;
    } else if (payload is Map<String, dynamic> && payload['data'] is List) {
      list = payload['data'];
    } else {
      return const <AppointmentModel>[];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(AppointmentModel.fromJson)
        .toList();
  }

  Future<List<EmergencyAppointmentModel>> fetchEmergencyAppointments() async {
    final doctorId = await _getDoctorId();
    final queryParams = <String, dynamic>{};
    if (doctorId.isNotEmpty) queryParams['doctor_id'] = doctorId;
    final response = await _dioClient.get(
      EndPoints.emergencyAppointmentsURL,
      queryParameters: queryParams,
    );
    final payload = response.data;

    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(EmergencyAppointmentModel.fromJson)
          .toList();
    }

    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(EmergencyAppointmentModel.fromJson)
            .toList();
      }
    }

    return const <EmergencyAppointmentModel>[];
  }
}