import 'package:birder_frontend/screens/change_password.dart';
import 'package:birder_frontend/screens/home_screen.dart';
import 'package:birder_frontend/services/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemberInfoPage extends StatefulWidget {
  const MemberInfoPage({
    super.key,
    this.onChangePassword,
  });

  final VoidCallback? onChangePassword;

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

class _MemberInfoPageState extends State<MemberInfoPage> {
  String username = '';
  String email = '';
  String name = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
      name = prefs.getString('name') ?? '';
      email = prefs.getString('email') ?? '';
      loading = false;
    });
  }

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
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontWeight: FontWeight.w400,
                  fontSize: 26,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),

              // 회원 정보
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
                    _InfoRow(label: '이름', value: name.isEmpty ? '-' : name),
                    _InfoRow(label: '아이디', value: username.isEmpty ? '-' : username),
                    _InfoRow(label: '이메일', value: email.isEmpty ? '-' : email),
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
                  onPressed: widget.onChangePassword ?? () {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VerifyPasswordPage()),
                  );
                  },
                  child: Text(
                    '비밀번호 변경',
                    style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontWeight: FontWeight.w400,
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

                      final refresh = prefs.getString('refreshToken');
                      final access = prefs.getString('accessToken');

                      final auth = AuthApi('http://10.0.2.2:8000');

                      try {
                        if (access != null && access.isNotEmpty) {
                          auth.setAccessToken(access);
                        }

                        if (refresh != null && refresh.isNotEmpty) {
                          await auth.logout(refreshToken: refresh);
                        }
                      } catch (_) {

                      }

                      await prefs.setBool('isLoggedIn', false);
                      await prefs.remove('username');
                      await prefs.remove('email');
                      await prefs.remove('name');
                      await prefs.remove('accessToken');
                      await prefs.remove('refreshToken');

                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (_) => false,
                      );
                    },
                    child:
                    Text( '로그아웃',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        fontWeight: FontWeight.w400,
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
                      // 탈퇴 확인
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('회원탈퇴'),
                          content: const Text(
                            '정말 탈퇴하시겠어요?\n'
                                '탈퇴 후에는 다시 로그인해야 합니다.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                '탈퇴',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (ok != true) return; // 취소했으면 종료

                      try {

                        final prefs = await SharedPreferences.getInstance();
                        final access = prefs.getString('accessToken');

                        if (access == null || access.isEmpty) {
                          throw Exception('로그인이 필요합니다.');
                        }

                        // 탈퇴 API 호출
                        final auth = AuthApi('http://10.0.2.2:8000');
                        auth.setAccessToken(access);
                        await auth.withdraw();

                        // 로컬 로그인 정보 삭제
                        await prefs.setBool('isLoggedIn', false);
                        await prefs.remove('accessToken');
                        await prefs.remove('refreshToken');
                        await prefs.remove('username');
                        await prefs.remove('email');
                        await prefs.remove('name');

                        if (!context.mounted) return;

                        // 완료
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                        );

                        // 홈 화면으로 이동
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (_) => false,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    child: Text(
                      '회원탈퇴',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        fontWeight: FontWeight.w400,
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
            style: TextStyle(
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.w400,
                fontSize: 16, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Paperlogy',
              fontWeight: FontWeight.w400,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}