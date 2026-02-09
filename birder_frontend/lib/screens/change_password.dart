import 'package:birder_frontend/services/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';


import 'package:birder_frontend/screens/log_in.dart';

// 1) 현재 비밀번호 확인 화면
class VerifyPasswordPage extends StatefulWidget {
  const VerifyPasswordPage({super.key});

  @override
  State<VerifyPasswordPage> createState() => _VerifyPasswordPageState();
}

class _VerifyPasswordPageState extends State<VerifyPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    super.dispose();
  }

  Future<bool> _verifyCurrentPassword(String pw) async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('accessToken');

    if (access == null || access.isEmpty) {
      throw Exception('로그인이 필요합니다. (토큰 없음)');
    }

    final api = AuthApi('http://10.0.2.2:8000');
    api.setAccessToken(access);

    try {
      await api.checkPassword(password: pw.trim());
      return true; // 200 → OK
    } on DioException {
      return false; // 401 등 → 틀림
    }
  }

  Future<void> _submit() async {
    final okForm = _formKey.currentState?.validate() ?? false;
    if (!okForm) return;

    final pw = _currentPwCtrl.text;

    setState(() => _loading = true);
    try {
      final ok = await _verifyCurrentPassword(pw);

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 비밀번호가 올바르지 않습니다.')),
        );
        return;
      }

      // 확인 후 변경 화면으로 (현재 비밀번호 전달)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangePasswordPage(currentPassword: pw.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const sky = Color(0xFFDCEBFF);
    const btnColor = Color(0xFFA1C4FD);

    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
        backgroundColor: sky,
        elevation: 0,
        leading: IconButton(
          iconSize: 28,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
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
          Positioned(
            top: screenSize.height * 0.28,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '비밀번호 변경',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '보안을 위해 현재 비밀번호를 먼저 확인합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 현재 비밀번호
                      TextFormField(
                        controller: _currentPwCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: '현재 비밀번호',
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
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return '현재 비밀번호를 입력해 주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            '확인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2) 새 비밀번호 입력 화면
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.currentPassword});
  final String currentPassword;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _newPwCtrl = TextEditingController();
  final _newPwConfirmCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _newPwCtrl.dispose();
    _newPwConfirmCtrl.dispose();
    super.dispose();
  }

  bool _isStrongEnough(String pw) {
    if (pw.length < 8) return false;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(pw);
    final hasDigit = RegExp(r'\d').hasMatch(pw);
    return hasLetter && hasDigit;
  }


  Future<void> _changePassword() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('accessToken');

    if (access == null || access.isEmpty) {
      throw Exception('로그인이 필요합니다. (토큰 없음)');
    }

    final api = AuthApi('http://10.0.2.2:8000');
    api.setAccessToken(access);

    await api.changePassword(
      newPassword: _newPwCtrl.text.trim(),
      newPasswordConfirm: _newPwConfirmCtrl.text.trim(),
    );

    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('name');
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      await _changePassword();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경되었습니다. 다시 로그인해주세요.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? ((e.response?.data['message'] ??
          e.response?.data['detail'] ??
          '비밀번호 변경에 실패했습니다.')
          .toString())
          : '비밀번호 변경에 실패했습니다.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const sky = Color(0xFFDCEBFF);
    const btnColor = Color(0xFFA1C4FD);

    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
        backgroundColor: sky,
        elevation: 0,
        leading: IconButton(
          iconSize: 28,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
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
          Positioned(
            top: screenSize.height * 0.28,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '새 비밀번호 설정',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '영문 + 숫자 포함 8자리 이상으로 설정하십시오.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 새 비밀번호
                      TextFormField(
                        controller: _newPwCtrl,
                        obscureText: _obscure1,
                        decoration: InputDecoration(
                          hintText: '새 비밀번호',
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
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure1 = !_obscure1),
                            icon: Icon(_obscure1
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (v) {
                          final pw = (v ?? '').trim();
                          if (pw.isEmpty) return '새 비밀번호를 입력해 주세요.';
                          if (!_isStrongEnough(pw)) {
                            return '비밀번호는 영문+숫자 포함 8자리 이상으로 설정해 주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // 새 비밀번호 확인
                      TextFormField(
                        controller: _newPwConfirmCtrl,
                        obscureText: _obscure2,
                        decoration: InputDecoration(
                          hintText: '새 비밀번호 확인',
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
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure2 = !_obscure2),
                            icon: Icon(_obscure2
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: (v) {
                          final confirm = (v ?? '').trim();
                          if (confirm.isEmpty) return '새 비밀번호 확인을 입력해 주세요.';
                          if (confirm != _newPwCtrl.text.trim()) {
                            return '비밀번호가 일치하지 않아요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text(
                            '비밀번호 변경',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}