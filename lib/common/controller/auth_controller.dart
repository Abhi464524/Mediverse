import 'package:mediverse/common/model/auth_request_model.dart';
import 'package:mediverse/common/model/auth_response_model.dart';
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
    } catch (e) {
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
      final response = await _authRepo.signUp(
        AuthRequestModel(
          username: username,
          password: password,
          role: role.toLowerCase(),
          speciality: speciality,
        ),
      );
      return response;
    } catch (e) {
      Get.snackbar("Error", "Sign up failed: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
