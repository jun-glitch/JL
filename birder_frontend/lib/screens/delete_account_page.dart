import 'package:birder_frontend/screens/log_IN.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({
    super.key,
    required this.userId,
    required this.email,
    this.onDeleteAccount,
  });

  final String userId;
  final String email;

  /// TODO: 서버에서 DB 삭제되도록 탈퇴 API 연결
  /// (비밀번호 받아서 검증 후 회원 삭제)
  final Future<void> Function(String password)? onDeleteAccount;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _doDelete() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // 마지막 확인
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정말 탈퇴하시겠습니까?'),
        content: const Text('탈퇴하면 계정 정보가 삭제되며 복구할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );

    if (sure != true) return;

    if (_busy) return;
    setState(() => _busy = true);

    try {
      if (widget.onDeleteAccount == null) {
        throw Exception('탈퇴 API가 아직 연결되지 않았어요.');
      }

      // TODO: 서버에서 비밀번호 검증 + 회원 삭제(DB에서도 삭제)
      await widget.onDeleteAccount!.call(_pwCtrl.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴가 완료되었어요.')),
      );

      // 로그인 화면으로 (스택 제거)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('탈퇴 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const sky = Color(0xFFDCEBFF);

    InputDecoration fieldDeco(String hint) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          onPressed: () => Navigator.of(context).pop(),
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

          // 내용
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
                        '탈퇴하기',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 사용자 정보(참고용)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('아이디: ${widget.userId}',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('이메일: ${widget.email}',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 비밀번호 입력
                      TextFormField(
                        controller: _pwCtrl,
                        obscureText: true,
                        decoration: fieldDeco('비밀번호'),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return '비밀번호를 입력해 주세요.';
                          if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // 비밀번호 확인
                      TextFormField(
                        controller: _pw2Ctrl,
                        obscureText: true,
                        decoration: fieldDeco('비밀번호 확인'),
                        validator: (v) {
                          if ((v ?? '') != _pwCtrl.text) return '비밀번호가 일치하지 않습니다.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // 안내 문구
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '정말 탈퇴하시겠습니까?\n탈퇴하면 계정 정보가 삭제되며 복구할 수 없어요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 글씨 버튼 (탈퇴/취소)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _busy ? null : _doDelete,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[700],
                            ),
                            child: Text(_busy ? '처리중...' : '탈퇴하기'),
                          ),
                          const SizedBox(width: 8),
                          const Text('|', style: TextStyle(color: Colors.black54)),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _busy ? null : () => Navigator.of(context).pop(),
                            child: const Text('취소'),
                          ),
                        ],
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
