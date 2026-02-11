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

  // 아이디 중복 확인
  Future<bool> checkIdAvailable(String id) async {
    final res = await _dio.get('/api/auth/check-id/', queryParameters: {"id": id});
    return (res.data["available"] as bool?) ?? false;
  }

  void setAccessToken(String accessToken) {
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }


  // 로그인
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await _dio.post('/api/auth/login/', data: {
      "username": username,
      "password": password,
    });

    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('로그인 응답 형식이 올바르지 않습니다.');
  }

  // 로그아웃
  Future<void> logout({
    required String refreshToken
  }) async {
    await _dio.post('/api/auth/logout/', data: {
      "refresh": refreshToken,
    });
  }

  // 비밀번호 변경
  Future<void> checkPassword({required String password}) async {
    final res = await _dio.post('/api/auth/check-pwd/', data: {
      "password": password,
    });

    if (res.data is Map<String, dynamic>) {
      final session = res.data['session'];

      final String access = session['access_token'];
      final String refresh = session['refresh_token'];
      setAccessToken(access);
    }
    throw Exception('로그인 응답 형식이 올바르지 않습니다.');
  }

  Future<void> changePassword({
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _dio.post('/api/auth/change-pwd/', data: {
      "new_password": newPassword,
      "new_password_confirm": newPasswordConfirm,
    });
  }

  // 회원 탈퇴
  Future<Map<String, dynamic>> withdraw() async {
    final res = await _dio.post('/api/auth/withdraw/');
    return (res.data as Map).cast<String, dynamic>();
  }


}


