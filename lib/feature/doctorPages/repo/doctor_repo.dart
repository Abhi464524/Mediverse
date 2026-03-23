import 'package:dio/dio.dart';
import 'package:doctor_app/common/services/dio/api_service.dart';
import 'package:doctor_app/endPoints.dart';
import 'package:doctor_app/feature/doctorPages/model/patient_model.dart';

class DoctorRepo {
  final DioClient _dioClient = DioClient();

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
}