import 'package:birder_frontend/screens/log_IN.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class LogoutPage extends StatefulWidget {
  const LogoutPage({
    super.key,
    this.onLogout,
  });

  /// TODO: 토큰 삭제/세션 만료/API 호출 등을 외부에서 연결
  final Future<void> Function()? onLogout;

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  bool _busy = false;

  Future<void> _doLogout() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      // TODO: 실제 로그아웃 처리
      if (widget.onLogout != null) {
        await widget.onLogout!.call();
      }

      if (!mounted) return;

      // 로그인 화면으로 (스택 제거)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const sky = Color(0xFFDCEBFF);

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '로그아웃',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '정말 로그아웃 하시겠어요?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 글씨 버튼 (아이디찾기/비번찾기 스타일)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _busy ? null : _doLogout,
                          child: Text(_busy ? '처리중...' : '로그아웃하기'),
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
        ],
      ),
    );
  }
}
