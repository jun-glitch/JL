import 'package:dio/dio.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(String baseUrl)
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<void> register({
    required String id,
    required String email,
    required String password,
    required String name,
    required bool agreeTerms,
    required bool agreePrivacy,
  }) async {
    await _dio.post('/api/auth/register/', data: {
      "id": id,
      "email": email,
      "password": password,
      "name": name,
      "agreeTerms": agreeTerms,
      "agreePrivacy": agreePrivacy,
    });
  }

  // (선택) 아이디 중복 확인
  Future<bool> checkIdAvailable(String id) async {
    final res = await _dio.get('/api/auth/check-id/', queryParameters: {"id": id});
    return (res.data["available"] as bool?) ?? false;
  }
}
