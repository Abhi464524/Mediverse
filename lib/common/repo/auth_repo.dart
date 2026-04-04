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

    if (response.data is Map<String, dynamic>) {
      return AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    // Tunnels / proxies sometimes return HTML or plain text even when the
    // HTTP status is 200. Surface that body to the UI.
    final bodyText = response.data.toString();
    return AuthResponseModel(
      success: false,
      message: bodyText,
      userId: '',
      username: '',
      phoneNumber: request.phoneNumber,
      role: request.role,
      speciality: request.speciality,
      token: '',
    );
  }

  Future<AuthResponseModel> loginPhone(AuthRequestModel request) async {
    final response = await _dioClient.post(
      EndPoints.userPhoneLoginURL,
      data: request.toJson(),
    );

    if (response.data is Map<String, dynamic>) {
      return AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    // Tunnels / proxies sometimes return HTML or plain text even when the
    // HTTP status is 200. Surface that body to the UI.
    final bodyText = response.data.toString();
    return AuthResponseModel(
      success: false,
      message: bodyText,
      userId: '',
      username: '',
      phoneNumber: request.phoneNumber,
      role: request.role,
      speciality: request.speciality,
      token: '',
    );
  }

  Future<AuthResponseModel> signUp(SignUpRequestModel request) async {
    final response = await _dioClient.post(
      EndPoints.userSignUpURL,
      data: request.toJson(),
    );

    if (response.data is Map<String, dynamic>) {
      return AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    final bodyText = response.data.toString();
    return AuthResponseModel(
      success: false,
      message: bodyText,
      userId: '',
      username: request.username,
      phoneNumber: request.phoneNumber,
      role: request.role,
      speciality: request.speciality,
      token: '',
    );
  }
}
