class DoctorProfileUpdateRequest {
  final int doctorId;
  final int experienceYears;
  final String email;
  final String clinicAddress;
  final int consultationFee;

  const DoctorProfileUpdateRequest({
    required this.doctorId,
    required this.experienceYears,
    required this.email,
    required this.clinicAddress,
    required this.consultationFee,
  });

  Map<String, dynamic> toJson() {
    return {
      "doctorId": doctorId,
      "experienceYears": experienceYears,
      "email": email,
      "clinicAddress": clinicAddress,
      "consultationFee": consultationFee,
    };
  }
}

class DoctorProfileUpdateResponse {
  final int experienceYears;
  final String email;
  final String clinicAddress;
  final int consultationFee;

  const DoctorProfileUpdateResponse({
    required this.experienceYears,
    required this.email,
    required this.clinicAddress,
    required this.consultationFee,
  });

  factory DoctorProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    final profile = json["profile"] is Map<String, dynamic>
        ? json["profile"] as Map<String, dynamic>
        : json["data"] is Map<String, dynamic>
            ? json["data"] as Map<String, dynamic>
            : json;

    return DoctorProfileUpdateResponse(
      experienceYears: int.tryParse((profile["experienceYears"] ?? 0).toString()) ?? 0,
      email: (profile["email"] ?? "").toString(),
      clinicAddress: (profile["clinicAddress"] ?? "").toString(),
      consultationFee: int.tryParse((profile["consultationFee"] ?? 0).toString()) ?? 0,
    );
  }
}
