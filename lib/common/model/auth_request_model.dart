class AuthRequestModel {
  final String username;
  final String phoneNumber;
  final String password;
  final String otp;
  final String firebaseIdToken;
  final String role;
  final String speciality;

  const AuthRequestModel({
    this.username = "",
    this.phoneNumber = "",
    this.password = "",
    this.otp = "",
    this.firebaseIdToken = "",
    this.role = "",
    this.speciality = "",
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (username.isNotEmpty) map["userName"] = username;
    if (phoneNumber.isNotEmpty) map["phoneNumber"] = phoneNumber;
    if (role.isNotEmpty) map["role"] = role;
    if (speciality.isNotEmpty) map["speciality"] = speciality;

    if (password.isNotEmpty) {
      map["password"] = password;
    }
    if (otp.isNotEmpty) {
      map["otp"] = otp;
    }
    if (firebaseIdToken.isNotEmpty) {
      map["firebaseIdToken"] = firebaseIdToken;
    }

    return map;
  }
}
