import 'package:mediverse/common/config/api_config.dart';

/// Route paths relative to [ApiConfig.baseUrl] (must stay non-const so URLs
/// update when the user changes the API base in settings).
class EndPoints {
  static String get baseURL => ApiConfig.baseUrl;

  // Auth
  static String get userLoginURL => '$baseURL/users/login';
  static String get userPhoneLoginURL => '$baseURL/users/login-phone';
  static String get userSignUpURL => '$baseURL/users/signup';

  // Doctor APIs
  static String get medicineDetailsURL => '$baseURL/medicines';
  static String get doctorGetProfileURL => '$baseURL/doctor/getProfile';
  static String get doctorProfileURL => '$baseURL/doctor/profile';
  static String get addPatientURL => '$baseURL/doctor/add-patient';
  static String get updatePatientURL => '$baseURL/doctor/update-patient';
  static String get doctorAppointmentsURL => '$baseURL/doctor/getAppointments';
  static String get emergencyAppointmentsURL =>
      '$baseURL/doctor/getEmergencyAppointments';
  static String get updateAppointmentURL =>
      '$baseURL/doctor/updateAppointments';
  static String get updateEmergencyAppointmentURL =>
      '$baseURL/doctor/updateEmergencyAppointments';

  // Patient APIs
  static String get patientProfileURL => '$baseURL/patient/profile';
  static String get patientDoctorsURL => '$baseURL/patient/doctors';
  static String get patientAppointmentsURL => '$baseURL/patient/appointments';
}
