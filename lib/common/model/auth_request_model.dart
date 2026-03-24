class AuthRequestModel {
  final String username;
  final String password;
  final String role;
  final String speciality;

  const AuthRequestModel({
    required this.username,
    required this.password,
    required this.role,
    this.speciality = "",
  });

  Map<String, dynamic> toJson() {
    return {
      "userName": username,
      "password": password,
      "role": role,
      "speciality": speciality,
    };
  }
}
