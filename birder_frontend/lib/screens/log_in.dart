import 'package:birder_frontend/screens/find_id.dart';
import 'package:birder_frontend/screens/find_password.dart';
import 'package:birder_frontend/screens/home_screen.dart';
import 'package:birder_frontend/services/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sign_up.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const sky = Color(0xFFDCEBFF); // 배경색
    const loginBtnColor = Color(0xFFA1C4FD);

    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
        backgroundColor: sky, // 앱바 색
        elevation: 0,
        leading: IconButton(
          iconSize: 28,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // 'Birder' 로고
          Positioned(
            top: screenSize.height * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Birder',
                style: GoogleFonts.lobster(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // 로그인 폼
          Positioned(
            top: screenSize.height * 0.28,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 아이디
                    TextField(
                      controller: _idCtrl,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: '아이디',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 비밀번호
                    TextField(
                      controller: _pwCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '비밀번호',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 로그인 버튼
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: loginBtnColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                            final id = _idCtrl.text.trim();
                            final pw = _pwCtrl.text;

                            if (id.isEmpty || pw.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('아이디/비밀번호를 입력해 주세요.')),
                              );
                              return;
                            }

                            try {
                              final auth = AuthApi('http://10.0.2.2:8000');

                              final data = await auth.login(username: id, password: pw);

                              final access = data['access_token']?.toString();
                              final refresh = data['refresh_token']?.toString();

                              if (access == null || access.isEmpty) {
                                throw Exception('토큰이 없습니다. 서버 응답을 확인해 주세요.');
                              }

                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('isLoggedIn', true);
                              await prefs.setString('accessToken', access);

                              if (refresh != null && refresh.isNotEmpty) {
                                await prefs.setString('refreshToken', refresh);
                              }

                              await prefs.setString('username', id);

                              if (!context.mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            } on DioException catch (e) {
                              final msg = e.response?.data is Map
                                  ? ((e.response?.data['detail'] ??
                                  e.response?.data['message'] ??
                                  '로그인에 실패했습니다.')
                                  .toString())
                                  : '로그인에 실패했습니다.';
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                        },
                        child: const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 아이디 찾기, 비밀번호 찾기
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FindIdPage()),
                            );
                          },
                          child: const Text('아이디 찾기'),
                        ),
                        const SizedBox(width: 8),
                        const Text('|', style: TextStyle(color: Colors.black54)),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FindPasswordPage()),
                            );
                          },
                          child: const Text('비밀번호 찾기'),
                        ),
                      ],
                    ),

                    // 회원가입
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignupStepperPage()),
                          );
                        },
                        child: const Text(
                          '회원가입',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
