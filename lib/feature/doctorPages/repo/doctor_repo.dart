import 'package:dio/dio.dart';
import 'package:mediverse/common/services/dio/api_service.dart';
import 'package:mediverse/endPoints.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';

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