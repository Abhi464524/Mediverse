class DoctorProfile {
  int? doctorId;
  PersonalInfo? personalInfo;
  ContactDetails? contactDetails;
  ClinicDetails? clinicDetails;

  DoctorProfile({
    this.doctorId,
    this.personalInfo,
    this.contactDetails,
    this.clinicDetails,
  });

  DoctorProfile.fromJson(Map<String, dynamic> json) {
    doctorId = json['doctorId'];
    personalInfo = json['personalInfo'] != null
        ? PersonalInfo.fromJson(json['personalInfo'])
        : null;
    contactDetails = json['contactDetails'] != null
        ? ContactDetails.fromJson(json['contactDetails'])
        : null;
    clinicDetails = json['clinicDetails'] != null
        ? ClinicDetails.fromJson(json['clinicDetails'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['doctorId'] = doctorId;
    if (personalInfo != null) {
      data['personalInfo'] = personalInfo!.toJson();
    }
    if (contactDetails != null) {
      data['contactDetails'] = contactDetails!.toJson();
    }
    if (clinicDetails != null) {
      data['clinicDetails'] = clinicDetails!.toJson();
    }
    return data;
  }

  DoctorProfile copyWith({
    int? doctorId,
    PersonalInfo? personalInfo,
    ContactDetails? contactDetails,
    ClinicDetails? clinicDetails,
  }) {
    return DoctorProfile(
      doctorId: doctorId ?? this.doctorId,
      personalInfo: personalInfo ?? this.personalInfo,
      contactDetails: contactDetails ?? this.contactDetails,
      clinicDetails: clinicDetails ?? this.clinicDetails,
    );
  }
}

class PersonalInfo {
  String? fullName;
  String? specialization;
  int? experienceYears;

  PersonalInfo({this.fullName, this.specialization, this.experienceYears});

  PersonalInfo.fromJson(Map<String, dynamic> json) {
    fullName = json['fullName'];
    specialization = json['specialization'];
    experienceYears = json['experienceYears'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fullName'] = fullName;
    data['specialization'] = specialization;
    data['experienceYears'] = experienceYears;
    return data;
  }

  PersonalInfo copyWith({
    String? fullName,
    String? specialization,
    int? experienceYears,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      specialization: specialization ?? this.specialization,
      experienceYears: experienceYears ?? this.experienceYears,
    );
  }
}

class ContactDetails {
  String? phoneNumber;
  String? email;

  ContactDetails({this.phoneNumber, this.email});

  ContactDetails.fromJson(Map<String, dynamic> json) {
    phoneNumber = json['phoneNumber'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phoneNumber'] = phoneNumber;
    data['email'] = email;
    return data;
  }

  ContactDetails copyWith({
    String? phoneNumber,
    String? email,
  }) {
    return ContactDetails(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }
}

class ClinicDetails {
  String? clinicAddress;
  int? consultationFee;

  ClinicDetails({this.clinicAddress, this.consultationFee});

  ClinicDetails.fromJson(Map<String, dynamic> json) {
    clinicAddress = json['clinicAddress'];
    consultationFee = json['consultationFee'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clinicAddress'] = clinicAddress;
    data['consultationFee'] = consultationFee;
    return data;
  }

  ClinicDetails copyWith({
    String? clinicAddress,
    int? consultationFee,
  }) {
    return ClinicDetails(
      clinicAddress: clinicAddress ?? this.clinicAddress,
      consultationFee: consultationFee ?? this.consultationFee,
    );
  }
}

