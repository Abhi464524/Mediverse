import 'package:flutter/foundation.dart';
import 'package:mediverse/common/model/auth_request_model.dart';
import 'package:mediverse/common/model/auth_response_model.dart';
import 'package:mediverse/common/model/signup_request_model.dart';
import 'package:mediverse/common/repo/auth_repo.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthRepo _authRepo = AuthRepo();

  final isLoading = false.obs;

  Future<AuthResponseModel?> login({
    String username = "",
    String phoneNumber = "",
    String password = "",
    String otp = "",
    String firebaseIdToken = "",
    required String role,
    String speciality = "",
  }) async {
    try {
      isLoading.value = true;
      final request = AuthRequestModel(
        username: username,
        phoneNumber: phoneNumber,
        password: password,
        otp: otp,
        firebaseIdToken: firebaseIdToken,
        role: role.toLowerCase(),
        speciality: speciality,
      );

      final response = firebaseIdToken.isNotEmpty
          ? await _authRepo.loginPhone(request)
          : await _authRepo.login(request);
      return response;
    } catch (e, stackTrace) {
      debugPrint('AuthController.login error: $e');
      debugPrint('$stackTrace');
      Get.snackbar("Error", "Login failed: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<AuthResponseModel?> signUp({
    required String username,
    required String phoneNumber,
    required String password,
    required String role,
    String speciality = "",
  }) async {
    try {
      isLoading.value = true;
      final normalizedRole = role.toLowerCase();
      final signUpRequest = normalizedRole == "doctor"
          ? SignUpRequestModel.forDoctor(
              username: username,
              phoneNumber: phoneNumber,
              password: password,
              speciality: speciality,
            )
          : SignUpRequestModel.forPatient(
              username: username,
              phoneNumber: phoneNumber,
              password: password,
            );

      final response = await _authRepo.signUp(signUpRequest);
      return response;
    } catch (e, stackTrace) {
      debugPrint('AuthController.signUp error: $e');
      debugPrint('$stackTrace');
      Get.snackbar("Error", "Sign up failed: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
