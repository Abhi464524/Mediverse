import 'package:dio/dio.dart';
import 'package:doctor_app/common/services/dio/curl_logger_dio_interceptor.dart';

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

    // dio.interceptors.add(LoggerInterceptor()); // TODO: Add dependency if needed
    dio.interceptors.add(CurlInterceptor());
    
    // // if (isDebugMode) {
    // dio.interceptors.add(ChuckerDioInterceptor()); // TODO: Add dependency if needed
    // }
    
    // Adding standard LogInterceptor as a fall-back for now
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
    } on DioException catch (e) {
      throw _handleError(e);
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
    } on DioException catch (e) {
      throw _handleError(e);
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
    } on DioException catch (e) {
      throw _handleError(e);
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
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handling
  String _handleError(DioException e) {
    String message = "Something went wrong";
    if (e.type == DioExceptionType.connectionTimeout) {
      message = "Connection timeout";
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = "Receive timeout";
    } else if (e.type == DioExceptionType.badResponse) {
      message = "Received invalid status code: ${e.response?.statusCode}";
    } else if (e.type == DioExceptionType.cancel) {
      message = "Request to API server was cancelled";
    } else if (e.type == DioExceptionType.connectionError) {
      message = "No internet connection";
    }
    return message;
  }
}
