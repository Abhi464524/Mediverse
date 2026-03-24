import 'package:mediverse/common/config/api_config.dart';

class EndPoints {
  static const String baseURL = ApiConfig.baseUrl;

  // Auth
  static const String userLoginURL = "$baseURL/users/login";
  static const String userSignUpURL = "$baseURL/users/signup";

  // Doctor APIs
  static const String medicineDetailsURL = "$baseURL/medicines";
  static const String addPatientURL = "$baseURL/add-patient";

  // Patient APIs
  static const String patientProfileURL = "$baseURL/patient/profile";
  static const String patientDoctorsURL = "$baseURL/patient/doctors";
  static const String patientAppointmentsURL = "$baseURL/patient/appointments";
}