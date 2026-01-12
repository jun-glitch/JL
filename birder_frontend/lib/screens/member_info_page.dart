import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class MemberInfoPage extends StatefulWidget {
  const MemberInfoPage({
    super.key,
    required this.userId,
    required this.email,
    required this.name,
    this.onLogout,
    this.onDeleteAccount,
  });

  final String userId;
  final String email;
  final String name;

  /// 실제 로그아웃 로직(토큰 삭제/세션 만료/API 호출 등)을 여기 연결
  final Future<void> Function()? onLogout;

  /// 실제 탈퇴 로직(API 호출 등)을 여기 연결
  final Future<void> Function()? onDeleteAccount;

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

class _MemberInfoPageState extends State<MemberInfoPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleLogout() async {
    await _run(() async {
      // TODO: 로그아웃 처리
      if (widget.onLogout != null) {
        await widget.onLogout!.call();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 되었어요.')),
      );

      // TODO: 로그인 화면으로 이동은 프로젝트 구조에 맞게 처리
      // 예) Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (_) => const LoginPage()),
      //   (_) => false,
      // );
    });
  }

  Future<void> _handleDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정말 탈퇴할까요?'),
        content: const Text('탈퇴하면 계정 정보가 삭제될 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _run(() async {
      // TODO: 탈퇴 처리
      if (widget.onDeleteAccount != null) {
        await widget.onDeleteAccount!.call();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴 처리 완료.')),
      );

      // TODO: 로그인 화면으로 이동은 프로젝트 구조에 맞게 처리
    });
  }

  Widget _infoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const sky = Color(0xFFDCEBFF);
    const cardBg = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
        backgroundColor: sky,
        elevation: 0,
        automaticallyImplyLeading: false, // 필요하면 back 버튼 켜도 됨
      ),
      body: Stack(
        children: [
          // 상단 로고 고정
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

          // 내용 영역
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
                    Text(
                      '회원 정보',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 정보 카드
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _infoRow(label: '이름', value: widget.name),
                          const Divider(height: 1),
                          _infoRow(label: '아이디', value: widget.userId),
                          const Divider(height: 1),
                          _infoRow(label: '이메일', value: widget.email),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 로그아웃 / 탈퇴하기 (글씨 버튼)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _busy ? null : _handleLogout,
                          child: Text(_busy ? '처리중...' : '로그아웃'),
                        ),
                        const SizedBox(width: 8),
                        const Text('|', style: TextStyle(color: Colors.black54)),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _busy ? null : _handleDeleteAccount,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[700],
                          ),
                          child: const Text('탈퇴하기'),
                        ),
                      ],
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
