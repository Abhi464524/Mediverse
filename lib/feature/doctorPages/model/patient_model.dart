class PatientModel {
  final String id;
  final String name;
  final String age;
  final String gender;
  final String contact;
  final String email;
  final String address;
  final String bloodGroup;
  final String diagnosis;
  final String medicalHistory;
  final String currentMedications;
  final String allergies;
  final String lastVisit;
  final String symptoms;
  final String weight;
  final String height;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.email,
    required this.address,
    required this.bloodGroup,
    required this.diagnosis,
    required this.medicalHistory,
    required this.currentMedications,
    required this.allergies,
    required this.lastVisit,
    required this.symptoms,
    this.weight = "72 kg",
    this.height = "175 cm",
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? '',
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      medicalHistory: json['medicalHistory'] ?? '',
      currentMedications: json['currentMedications'] ?? '',
      allergies: json['allergies'] ?? '',
      lastVisit: json['lastVisit'] ?? '',
      symptoms: json['symptoms'] ?? '',
      weight: json['weight'] ?? '72 kg',
      height: json['height'] ?? '175 cm',
    );
  }
}
