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
    required String username,
    required String password,
    required String role,
    String speciality = "",
  }) async {
    try {
      isLoading.value = true;
      final response = await _authRepo.login(
        AuthRequestModel(
          username: username,
          password: password,
          role: role.toLowerCase(),
          speciality: speciality,
        ),
      );
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
              password: password,
              speciality: speciality,
            )
          : SignUpRequestModel.forPatient(
              username: username,
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
