class SignUpRequestModel {
  final String username;
  final String phoneNumber;
  final String password;
  final String role;
  final String speciality;

  const SignUpRequestModel({
    required this.username,
    required this.phoneNumber,
    required this.password,
    required this.role,
    this.speciality = "",
  });

  factory SignUpRequestModel.forDoctor({
    required String username,
    required String phoneNumber,
    required String password,
    required String speciality,
  }) {
    return SignUpRequestModel(
      username: username,
      phoneNumber: phoneNumber,
      password: password,
      role: "doctor",
      speciality: speciality,
    );
  }

  factory SignUpRequestModel.forPatient({
    required String username,
    required String phoneNumber,
    required String password,
  }) {
    return SignUpRequestModel(
      username: username,
      phoneNumber: phoneNumber,
      password: password,
      role: "patient",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userName": username,
      "phoneNumber": phoneNumber,
      "password": password,
      "role": role,
      "speciality": speciality,
    };
  }
}
