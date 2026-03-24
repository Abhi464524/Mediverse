class AuthResponseModel {
  final bool success;
  final String message;
  final String username;
  final String role;
  final String speciality;
  final String token;

  const AuthResponseModel({
    required this.success,
    required this.message,
    required this.username,
    required this.role,
    required this.speciality,
    required this.token,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userMap = json["user"] is Map<String, dynamic>
        ? json["user"] as Map<String, dynamic>
        : <String, dynamic>{};

    final parsedUsername =
        (json["username"] ?? userMap["username"] ?? "").toString();
    final parsedToken = (json["token"] ?? "").toString();
    final hasPositiveSignal = parsedUsername.isNotEmpty || parsedToken.isNotEmpty;

    return AuthResponseModel(
      success: json["success"] == true || hasPositiveSignal,
      message: (json["message"] ?? "").toString(),
      username: parsedUsername,
      role: (json["role"] ?? userMap["role"] ?? "").toString(),
      speciality:
          (json["speciality"] ?? userMap["speciality"] ?? "").toString(),
      token: parsedToken,
    );
  }
}
