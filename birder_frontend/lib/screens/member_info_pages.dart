import 'package:birder_frontend/screens/change_password.dart';
import 'package:birder_frontend/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemberInfoPage extends StatelessWidget {
  const MemberInfoPage({
    super.key,
    required this.username,
    required this.email,
    required this.name,
    required this.onLogout,
    required this.onDeleteAccount,
    this.onChangePassword,
  });

  final String username;
  final String email;
  final String name;

  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final VoidCallback? onChangePassword;

  @override
  Widget build(BuildContext context) {
    const sky = Color(0xFFDCEBFF);

    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
        backgroundColor: sky,
        elevation: 0,
        title: Text(
          'Birder',
          style: GoogleFonts.lobster(
            fontSize: 35,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '회원 정보',
                style: GoogleFonts.jua(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),

              // 정보 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: '이름', value: name),
                    const SizedBox(height: 15),
                    _InfoRow(label: '아이디', value: username),
                    const SizedBox(height: 15),
                    _InfoRow(label: '이메일', value: email),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 비밀번호 변경 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA1C4FD),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onChangePassword ?? () {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VerifyPasswordPage()),
                  );
                  },
                  child: Text(
                    '비밀번호 변경',
                    style: GoogleFonts.jua(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', false);
                      await prefs.remove('username');
                      await prefs.remove('email');
                      await prefs.remove('name');
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (_) => false,
                      );
                    },
                    child: Text(
                      '로그아웃',
                      style: GoogleFonts.jua(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: Colors.black54)),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      await onDeleteAccount();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '회원탈퇴',
                      style: GoogleFonts.jua(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.jua(fontSize: 16, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.jua(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}