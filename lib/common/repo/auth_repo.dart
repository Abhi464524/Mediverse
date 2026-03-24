import 'package:mediverse/common/model/auth_request_model.dart';
import 'package:mediverse/common/model/auth_response_model.dart';
import 'package:mediverse/common/model/signup_request_model.dart';
import 'package:mediverse/common/services/dio/api_service.dart';
import 'package:mediverse/endPoints.dart';

class AuthRepo {
  final DioClient _dioClient = DioClient();

  Future<AuthResponseModel> login(AuthRequestModel request) async {
    final response = await _dioClient.post(
      EndPoints.userLoginURL,
      data: request.toJson(),
    );

    final map = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    return AuthResponseModel.fromJson(map);
  }

  Future<AuthResponseModel> signUp(SignUpRequestModel request) async {
    final response = await _dioClient.post(
      EndPoints.userSignUpURL,
      data: request.toJson(),
    );

    final map = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    return AuthResponseModel.fromJson(map);
  }
}
