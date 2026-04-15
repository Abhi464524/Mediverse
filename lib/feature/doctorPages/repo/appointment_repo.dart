import 'package:dio/dio.dart';
import 'package:mediverse/common/services/dio/api_service.dart';
import 'package:mediverse/common/services/storage_service.dart';
import 'package:mediverse/endPoints.dart';
import 'package:mediverse/feature/doctorPages/model/emergency_appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';

class AppointmentRepo {
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

  Future<Response> updatePatient(
      String patientId, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.put(
        '${EndPoints.updatePatientURL}/$patientId',
        data: data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateAppointment(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(
        EndPoints.updateAppointmentURL,
        data: data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateEmergencyAppointment(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(
        EndPoints.updateEmergencyAppointmentURL,
        data: data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
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
}
