import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CurlInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _printCurl(options);
    }
    super.onRequest(options, handler);
  }

  void _printCurl(RequestOptions options) {
    List<String> components = ['curl -i'];

    // Method
    components.add('-X ${options.method}');

    // Headers
    options.headers.forEach((k, v) {
      if (k != 'cookie') {
        components.add('-H "$k: $v"');
      }
    });

    // Data
    if (options.data != null) {
      try {
        if (options.data is Map || options.data is List) {
          final data = json.encode(options.data);
          components.add("-d '$data'");
        } else if (options.data is FormData) {
          final formData = options.data as FormData;
          for (var element in formData.fields) {
            components.add("-F '${element.key}=${element.value}'");
          }
          for (var element in formData.files) {
            components.add("-F '${element.key}=@${element.value.filename}'");
          }
        } else {
          components.add("-d '${options.data.toString()}'");
        }
      } catch (e) {
        debugPrint('Error parsing data for CURL: $e');
      }
    }

    // URL
    final uri = options.uri;
    components.add('"${uri.toString()}"');

    final curl = components.join(' \\\n  ');
    debugPrint('--- CURL REQUEST ---');
    debugPrint(curl);
    debugPrint('--------------------');
  }
}
