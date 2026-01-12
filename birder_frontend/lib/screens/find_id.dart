import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FindIdPage extends StatefulWidget {
  const FindIdPage({super.key});

  @override
  State<FindIdPage> createState() => _FindIdPageState();
}

class _FindIdPageState extends State<FindIdPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _codeSent = false;
  bool _verified = false;

  Timer? _timer;
  int _remainSec = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
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

  Future<void> _sendVerificationCode() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    // TODO: 서버 호출 (이메일로 인증번호 발송)
    // await api.sendFindIdCode(name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim());

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

    // TODO: 서버 호출 (인증번호 검증)
    // final ok = await api.verifyFindIdCode(email: _emailCtrl.text.trim(), code: code);

    final ok = RegExp(r'^\d{6}$').hasMatch(code); // 임시: 6자리 숫자면 통과

    setState(() => _verified = ok);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '이메일 인증이 완료됐어요.' : '인증번호가 올바르지 않아요.')),
    );
  }

  Future<void> _sendIdToEmail() async {
    if (!_verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증을 먼저 완료해 주세요.')),
      );
      return;
    }

    // TODO: 서버 호출 (해당 이메일로 아이디 전송)
    // await api.sendUserIdToEmail(name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('아이디를 이메일로 전송했어요.')),
    );

    // 필요하면 이전 화면으로
    Navigator.of(context).pop();
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
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Birder 로고 (고정)
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
                        '아이디 찾기',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // 이름
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: '이름',
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
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return '이름을 입력해 주세요.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // 이메일
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: '이메일',
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
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return '이메일을 입력해 주세요.';
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(value)) return '이메일 형식이 올바르지 않습니다.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // 인증번호 발송 버튼
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

                      // 인증번호 입력 (발송 후에만 노출)
                      if (_codeSent) ...[
                        TextFormField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '인증번호 (6자리)',
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
                            suffixIcon: TextButton(
                              onPressed: _verifyCode,
                              child: const Text('확인'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 인증 상태 안내
                        Text(
                          _verified ? '✅ 이메일 인증 완료' : '이메일 인증이 필요해요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _verified ? Colors.green[800] : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 아이디 전송 버튼
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
                            onPressed: _verified ? _sendIdToEmail : null,
                            child: const Text(
                              '아이디 이메일로 받기',
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
