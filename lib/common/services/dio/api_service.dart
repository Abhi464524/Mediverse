import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mediverse/common/services/dio/curl_logger_dio_interceptor.dart';

class DioClient {
  late final Dio _dio;

  DioClient({String? baseUrl}) {
    _dio = createDio();
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _dio.options.baseUrl = baseUrl;
    }
  }

  static Dio createDio() {
    var dio = Dio();
    dio.options.connectTimeout = const Duration(milliseconds: 50000);
    dio.options.receiveTimeout = const Duration(milliseconds: 50000);
    dio.interceptors.add(CurlInterceptor());
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  }



  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e, stackTrace) {
      _rethrowHandled(e, stackTrace);
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e, stackTrace) {
      _rethrowHandled(e, stackTrace);
    }
  }

  // PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e, stackTrace) {
      _rethrowHandled(e, stackTrace);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e, stackTrace) {
      _rethrowHandled(e, stackTrace);
    }
  }

  Never _rethrowHandled(DioException e, StackTrace stackTrace) {
    final userMessage = _handleError(e);
    _logDioException(e, userMessage, stackTrace);
    throw userMessage;
  }

  void _logDioException(
    DioException e,
    String userMessage,
    StackTrace stackTrace,
  ) {
    debugPrint('══ DioException ══');
    debugPrint('User message: $userMessage');
    debugPrint('URI: ${e.requestOptions.uri}');
    debugPrint('Method: ${e.requestOptions.method}');
    debugPrint('Dio type: ${e.type}');
    debugPrint('Dio message: ${e.message}');
    debugPrint('Underlying: ${e.error}');
    final response = e.response;
    if (response != null) {
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
    }
    debugPrint('Stack trace:\n$stackTrace');
    debugPrint('═══════════════════');
  }

  // Error Handling
  String _handleError(DioException e) {
    String message = "Something went wrong";
    if (e.type == DioExceptionType.connectionTimeout) {
      message = "Connection timeout";
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = "Receive timeout";
    } else if (e.type == DioExceptionType.badResponse) {
      final code = e.response?.statusCode;
      final detail = _httpErrorBodySummary(e.response?.data);
      message = detail.isNotEmpty
          ? 'HTTP $code: $detail'
          : 'Received invalid status code: $code';
    } else if (e.type == DioExceptionType.cancel) {
      message = "Request to API server was cancelled";
    } else if (e.type == DioExceptionType.connectionError) {
      final host = e.requestOptions.uri.host;
      final isLocalHost = host == 'localhost' || host == '127.0.0.1';
      final errStr = e.error?.toString() ?? '';
      if (isLocalHost && errStr.contains('Connection refused')) {
        message =
            "API base URL is localhost: on a real phone that means the phone, not your computer. "
            "Stop the app, then run: flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:3000/api "
            "(Mac: ipconfig getifaddr en0; phone and PC on same Wi-Fi; server must listen on 0.0.0.0). "
            "Android emulator only: use http://10.0.2.2:3000/api. "
            "Or use VS Code: \"Mediverse · physical device (API on Mac)\" after setting the IP in .vscode/launch.json.";
      } else if (errStr.isNotEmpty) {
        message = "Network error: $errStr";
      } else {
        message = "No internet connection";
      }
    }
    return message;
  }

  /// Short text from error JSON/HTML so snackbars and logs show why the server failed.
  String _httpErrorBodySummary(dynamic data, {int maxLen = 400}) {
    if (data == null) return '';
    if (data is String) {
      final t = data.trim();
      if (t.isEmpty) return '';
      return t.length > maxLen ? '${t.substring(0, maxLen)}…' : t;
    }
    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['msg'];
      if (msg != null) {
        final s = msg.toString();
        return s.length > maxLen ? '${s.substring(0, maxLen)}…' : s;
      }
      try {
        final s = jsonEncode(data);
        return s.length > maxLen ? '${s.substring(0, maxLen)}…' : s;
      } catch (_) {
        final s = data.toString();
        return s.length > maxLen ? '${s.substring(0, maxLen)}…' : s;
      }
    }
    final s = data.toString();
    return s.length > maxLen ? '${s.substring(0, maxLen)}…' : s;
  }
}
