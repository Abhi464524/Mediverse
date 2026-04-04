class AuthResponseModel {
  final bool success;
  final String message;
  final String userId;
  final String username;
  final String phoneNumber;
  final String role;
  final String speciality;
  final String token;

  const AuthResponseModel({
    required this.success,
    required this.message,
    required this.userId,
    required this.username,
    required this.phoneNumber,
    required this.role,
    required this.speciality,
    required this.token,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userMap = json["user"] is Map<String, dynamic>
        ? json["user"] as Map<String, dynamic>
        : <String, dynamic>{};

    final parsedUsername =
        (json["username"] ??
                json["userName"] ??
                userMap["username"] ??
                userMap["userName"] ??
                "")
            .toString();
    final parsedToken = (json["token"] ?? "").toString();
    final hasPositiveSignal = parsedUsername.isNotEmpty ||
        parsedToken.isNotEmpty ||
        userMap.isNotEmpty;

    final explicit = json["success"];
    final success = explicit == false
        ? false
        : explicit == true || hasPositiveSignal;

    return AuthResponseModel(
      success: success,
      message: (json["message"] ?? "").toString(),
      userId: (json["user_id"] ?? json["userId"] ?? json["id"] ?? userMap["id"] ?? userMap["user_id"] ?? userMap["userId"] ?? userMap["_id"] ?? "").toString(),
      username: parsedUsername,
      phoneNumber: (json["phoneNumber"] ?? userMap["phoneNumber"] ?? "").toString(),
      role: (json["role"] ?? userMap["role"] ?? "").toString(),
      speciality:
          (json["speciality"] ?? userMap["speciality"] ?? "").toString(),
      token: parsedToken,
    );
  }
}
