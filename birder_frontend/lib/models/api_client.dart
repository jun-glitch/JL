import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          //토큰 꺼내서 Authorization 헤더에 자동 첨부
          final prefs = await SharedPreferences.getInstance();
          debugPrint('prefs keys=${prefs.getKeys()}');
          final token = prefs.getString('accessToken');
          debugPrint('prefs accessToken=${prefs.getString('accessToken')}');


          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // 토큰이 없으면 헤더 제거(혹시 남아있던 값 방지)
            options.headers.remove('Authorization');
          }

          debugPrint('➡️ ${options.method} ${options.uri}');
          debugPrint('➡️ Authorization: ${options.headers['Authorization']}');
          handler.next(options);
        },
        onError: (e, handler) {
          debugPrint('❌ status=${e.response?.statusCode}');
          debugPrint('❌ data=${e.response?.data}');
          handler.next(e);
        },
      ),
    );
  }
}