import 'package:mediverse/feature/doctorPages/model/patient_model.dart';

class AppointmentModel {
  final String id;
  final String patientName;
  final String phone;
  final String time;
  final String date;
  final String diagnosis;
  final String status;
  final NewPatientResponse? patient;

  AppointmentModel({
    required this.id,
    required this.patientName,
    this.phone = '',
    required this.time,
    this.date = '',
    required this.diagnosis,
    this.status = 'Scheduled',
    this.patient,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      patientName: json['patient_name'] ?? json['patientName'] ?? '',
      phone: json['phone'] ?? '',
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      status: json['status'] ?? 'Scheduled',
      patient: json['patient'] != null
          ? NewPatientResponse.fromJson(json['patient'])
          : null,
    );
  }
}
