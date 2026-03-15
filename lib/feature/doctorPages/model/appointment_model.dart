class AppointmentModel {
  final String id;
  final String patientName;
  final String time;
  final String diagnosis;
  final String status;

  AppointmentModel({
    required this.id,
    required this.patientName,
    required this.time,
    required this.diagnosis,
    this.status = 'Scheduled',
  });

  // Factory for potential JSON parsing
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      patientName: json['patientName'] ?? '',
      time: json['time'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      status: json['status'] ?? 'Scheduled',
    );
  }
}
