class PatientProfileData {
  final String fullName;
  final String age;
  final String gender;
  final String bloodGroup;
  final String weight;
  final String height;
  final String phone;
  final String email;
  final String address;
  final String medicalHistory;
  final String currentMedications;
  final String allergies;
  final String lastVisitDate;

  const PatientProfileData({
    this.fullName = '',
    this.age = '',
    this.gender = 'Male',
    this.bloodGroup = 'O+',
    this.weight = '',
    this.height = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.medicalHistory = '',
    this.currentMedications = '',
    this.allergies = '',
    this.lastVisitDate = '',
  });

  Map<String, String> toStorageMap() => {
        'fullName': fullName,
        'age': age,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'weight': weight,
        'height': height,
        'phone': phone,
        'email': email,
        'address': address,
        'medicalHistory': medicalHistory,
        'currentMedications': currentMedications,
        'allergies': allergies,
        'lastVisitDate': lastVisitDate,
      };

  factory PatientProfileData.fromStorageMap(Map<String, String> map) {
    return PatientProfileData(
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? '',
      gender: map['gender'] ?? 'Male',
      bloodGroup: map['bloodGroup'] ?? 'O+',
      weight: map['weight'] ?? '',
      height: map['height'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      medicalHistory: map['medicalHistory'] ?? '',
      currentMedications: map['currentMedications'] ?? '',
      allergies: map['allergies'] ?? '',
      lastVisitDate: map['lastVisitDate'] ?? '',
    );
  }
}

class PatientBooking {
  final String id;
  final String doctorName;
  final String doctorSpecialty;
  final String preferredDate;
  final String preferredTime;
  final String visitType;
  final String symptomsReason;
  final String status;
  final String submittedAt;
  final String patientName;
  final String patientPhone;
  final String patientEmail;

  const PatientBooking({
    this.id = '',
    this.doctorName = '',
    this.doctorSpecialty = '',
    this.preferredDate = '',
    this.preferredTime = '',
    this.visitType = '',
    this.symptomsReason = '',
    this.status = 'Pending',
    this.submittedAt = '',
    this.patientName = '',
    this.patientPhone = '',
    this.patientEmail = '',
  });

  Map<String, String> toStorageMap() => {
        'id': id,
        'doctorName': doctorName,
        'doctorSpecialty': doctorSpecialty,
        'preferredDate': preferredDate,
        'preferredTime': preferredTime,
        'visitType': visitType,
        'symptomsReason': symptomsReason,
        'status': status,
        'submittedAt': submittedAt,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'patientEmail': patientEmail,
      };

  factory PatientBooking.fromStorageMap(Map<String, String> map) {
    return PatientBooking(
      id: map['id'] ?? '',
      doctorName: map['doctorName'] ?? '',
      doctorSpecialty: map['doctorSpecialty'] ?? '',
      preferredDate: map['preferredDate'] ?? '',
      preferredTime: map['preferredTime'] ?? '',
      visitType: map['visitType'] ?? '',
      symptomsReason: map['symptomsReason'] ?? '',
      status: map['status'] ?? 'Pending',
      submittedAt: map['submittedAt'] ?? '',
      patientName: map['patientName'] ?? '',
      patientPhone: map['patientPhone'] ?? '',
      patientEmail: map['patientEmail'] ?? '',
    );
  }
}

class PatientHomeSummary {
  final int totalBookings;
  final int pendingCount;
  final PatientBooking? latestBooking;

  const PatientHomeSummary({
    required this.totalBookings,
    required this.pendingCount,
    this.latestBooking,
  });
}

class PatientSlot {
  final String label;
  final bool isBooked;

  const PatientSlot({
    required this.label,
    required this.isBooked,
  });
}

class PatientDoctor {
  final String id;
  final String name;
  final String specialty;
  final String experience;
  final String clinic;
  final String clinicPhone;
  final String rating;

  const PatientDoctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.clinic,
    required this.clinicPhone,
    required this.rating,
  });

  factory PatientDoctor.fromResponse(Map<String, dynamic> json) {
    return PatientDoctor(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      specialty: '${json['specialty'] ?? ''}',
      experience: '${json['experience'] ?? ''}',
      clinic: '${json['clinic'] ?? ''}',
      clinicPhone: '${json['clinicPhone'] ?? json['clinic_phone'] ?? ''}',
      rating: '${json['rating'] ?? ''}',
    );
  }

  Map<String, dynamic> toResponse() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'experience': experience,
        'clinic': clinic,
        'clinicPhone': clinicPhone,
        'rating': rating,
      };
}
