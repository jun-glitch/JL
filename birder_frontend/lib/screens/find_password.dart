import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FindPasswordPage extends StatefulWidget {
  const FindPasswordPage({super.key});

  @override
  State<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends State<FindPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController();     // 아이디
  final _emailCtrl = TextEditingController();  // 이메일(인증번호 받을 주소)
  final _codeCtrl = TextEditingController();

  final _newPwCtrl = TextEditingController();
  final _newPwConfirmCtrl = TextEditingController();

  bool _codeSent = false;
  bool _verified = false;

  Timer? _timer;
  int _remainSec = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPwCtrl.dispose();
    _newPwConfirmCtrl.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _timer?.cancel();
    setState(() => _remainSec = seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainSec <= 1) {
        t.cancel();
        setState(() => _remainSec = 0);
      } else {
        setState(() => _remainSec -= 1);
      }
    });
  }

  String? _validateId(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return '아이디를 입력해 주세요.';
    if (value.length < 4) return '아이디는 4자 이상 입력해 주세요.'; // 필요시 팀 규칙으로 변경
    return null;
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return '이메일을 입력해 주세요.';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return '이메일 형식이 올바르지 않습니다.';
    return null;
  }

  Future<void> _sendVerificationCode() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // TODO: 서버 호출 (id + email로 사용자 확인 후, email로 인증번호 발송)
    // await api.sendResetPwCode(id: _idCtrl.text.trim(), email: _emailCtrl.text.trim());

    setState(() {
      _codeSent = true;
      _verified = false;
    });

    _startCooldown(60);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증번호를 이메일로 전송했어요.')),
    );
  }

  Future<void> _verifyCode() async {
    if (!_codeSent) return;

    final code = _codeCtrl.text.trim();

    // TODO: 서버 호출 (id + email + code 검증)
    // final ok = await api.verifyResetPwCode(
    //   id: _idCtrl.text.trim(),
    //   email: _emailCtrl.text.trim(),
    //   code: code,
    // );

    final ok = RegExp(r'^\d{6}$').hasMatch(code); // 임시: 6자리 숫자면 통과

    setState(() => _verified = ok);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '인증이 완료됐어요.' : '인증번호가 올바르지 않아요.')),
    );
  }

  Future<void> _resetPassword() async {
    if (!_verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증을 먼저 완료해 주세요.')),
      );
      return;
    }

    final newPw = _newPwCtrl.text;
    final newPw2 = _newPwConfirmCtrl.text;

    if (newPw.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 8자 이상이어야 합니다.')),
      );
      return;
    }
    if (newPw != newPw2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    // TODO: 서버 호출 (비밀번호 재설정)
    // await api.resetPassword(
    //   id: _idCtrl.text.trim(),
    //   email: _emailCtrl.text.trim(),
    //   code: _codeCtrl.text.trim(),
    //   newPassword: newPw,
    // );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호가 재설정되었어요. 로그인해 주세요.')),
    );

    Navigator.of(context).pop(); // 로그인 화면으로
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const sky = Color(0xFFDCEBFF);
    const btnColor = Color(0xFFA1C4FD);

    InputDecoration _fieldDeco(String hint, {Widget? suffix}) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffix,
      );
    }

    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
        backgroundColor: sky,
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
          // Birder 로고 고정
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

          // 폼 영역
          Positioned(
            top: screenSize.height * 0.28,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '비밀번호 찾기',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // 아이디
                      TextFormField(
                        controller: _idCtrl,
                        decoration: _fieldDeco('아이디'),
                        validator: _validateId,
                      ),
                      const SizedBox(height: 12),

                      // 이메일
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _fieldDeco('이메일'),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),

                      // 인증번호 발송
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
                          onPressed: _remainSec > 0 ? null : _sendVerificationCode,
                          child: Text(
                            _remainSec > 0 ? '인증번호 재발송 ($_remainSec초)' : '인증번호 발송',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 인증번호 입력 (발송 후)
                      if (_codeSent) ...[
                        TextFormField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDeco(
                            '인증번호 (6자리)',
                            suffix: TextButton(
                              onPressed: _verifyCode,
                              child: const Text('확인'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          _verified ? '✅ 인증 완료' : '인증이 필요해요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _verified ? Colors.green[800] : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 새 비밀번호/확인 (인증 완료 후)
                      if (_verified) ...[
                        TextFormField(
                          controller: _newPwCtrl,
                          obscureText: true,
                          decoration: _fieldDeco('새 비밀번호 (8자 이상)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPwConfirmCtrl,
                          obscureText: true,
                          decoration: _fieldDeco('새 비밀번호 확인'),
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
                            onPressed: _resetPassword,
                            child: const Text(
                              '비밀번호 재설정',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],

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
