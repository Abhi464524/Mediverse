import 'package:mediverse/common/config/api_config.dart';

class EndPoints {
  static const String baseURL = ApiConfig.baseUrl;

  // Auth
  static const String userLoginURL = "$baseURL/users/login";
  static const String userPhoneLoginURL = "$baseURL/users/login-phone";
  /// POST signup — `http://localhost:3000/api/users/signup` when [baseURL] is default.
  /// JSON: `userName`, `password`, `role` (`doctor` | `patient`), `speciality` (doctor; empty for patient).
  static const String userSignUpURL = "$baseURL/users/signup";

  // Doctor APIs
  static const String medicineDetailsURL = "$baseURL/medicines";
  static const String addPatientURL = "$baseURL/add-patient";

  // Patient APIs
  static const String patientProfileURL = "$baseURL/patient/profile";
  static const String patientDoctorsURL = "$baseURL/patient/doctors";
  static const String patientAppointmentsURL = "$baseURL/patient/appointments";
}