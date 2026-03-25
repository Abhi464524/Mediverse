class DoctorProfileFetchRequest {
  final int doctorId;

  const DoctorProfileFetchRequest({required this.doctorId});

  Map<String, dynamic> toJson() {
    return {"doctorId": doctorId};
  }
}

class DoctorProfileFetchResponse {
  final int doctorId;
  final int experienceYears;
  final String email;
  final String clinicAddress;
  final int consultationFee;

  const DoctorProfileFetchResponse({
    required this.doctorId,
    required this.experienceYears,
    required this.email,
    required this.clinicAddress,
    required this.consultationFee,
  });

  factory DoctorProfileFetchResponse.fromJson(Map<String, dynamic> json) {
    final data = json["data"] is Map<String, dynamic>
        ? json["data"] as Map<String, dynamic>
        : json;
    final profile = data["profile"] is Map<String, dynamic>
        ? data["profile"] as Map<String, dynamic>
        : data;

    return DoctorProfileFetchResponse(
      doctorId: int.tryParse((data["doctorId"] ?? 0).toString()) ?? 0,
      experienceYears: int.tryParse((profile["experienceYears"] ?? 0).toString()) ?? 0,
      email: (profile["email"] ?? "").toString(),
      clinicAddress: (profile["clinicAddress"] ?? "").toString(),
      consultationFee: int.tryParse((profile["consultationFee"] ?? 0).toString()) ?? 0,
    );
  }
}
