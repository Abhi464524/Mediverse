class EmergencyAppointmentModel {
  final String id;
  final String patientName;
  final String time;
  final String diagnosis;
  final String severity;
  final String status;

  const EmergencyAppointmentModel({
    required this.id,
    required this.patientName,
    required this.time,
    required this.diagnosis,
    required this.severity,
    required this.status,
  });

  factory EmergencyAppointmentModel.fromJson(Map<String, dynamic> json) {
    return EmergencyAppointmentModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      patientName: (json['patientName'] ?? json['name'] ?? 'Unknown').toString(),
      time: (json['time'] ?? json['scheduledTime'] ?? '').toString(),
      diagnosis: (json['diagnosis'] ?? json['reason'] ?? '').toString(),
      severity: (json['severity'] ?? 'Emergency').toString(),
      status: (json['status'] ?? 'Pending').toString(),
    );
  }
}
