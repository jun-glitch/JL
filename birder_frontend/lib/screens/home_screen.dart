import 'dart:io';

import 'package:birder_frontend/screens/birders_log_main.dart';
import 'package:birder_frontend/screens/log_in.dart';
import 'package:birder_frontend/screens/member_info_pages.dart';
import 'package:birder_frontend/screens/my_log.dart';
import 'package:birder_frontend/screens/search_result.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart'  as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'saved_image_page.dart' as pages;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;


// 임시 이미지 파일
Future<File> _assetToTempFile(String assetPath, String fileName) async {
  final ByteData bd = await rootBundle.load(assetPath);
  final Uint8List bytes = bd.buffer.asUint8List();

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  return file.writeAsBytes(bytes, flush: true);
}

Future<List<File>> _buildMockPhotos() async {
  final f1 = await _assetToTempFile('assets/images/bird_photo1.webp', 'bird_photo1.webp');

  return [f1]; // 1장만이면 [f1]
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  bool _isNewSearchExpanded = false; // 새 검색 버튼 확장 여부

  void _toggleNewSearch() {
    setState(() {
      _isNewSearchExpanded = !_isNewSearchExpanded;
    });
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _openCameraAndSave() async {
  final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
  if (photo == null) return;

  final dir = await getApplicationDocumentsDirectory();

  final ext0 = p.extension(photo.path);
  final ext = ext0.isNotEmpty ? ext0 : '.jpg';

  final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}$ext';
  final savedPath = p.join(dir.path, fileName);


  final savedFile = await File(photo.path).copy(savedPath);

  if (!mounted) return;

  Navigator.of(context).push(
  MaterialPageRoute(
  builder: (_) => pages.SavedImagePage(imagePath: savedFile.path),
  ),
  );
  }
  Future<void> _pickFromGalleryAndSave() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();

    final ext0 = p.extension(picked.path);
    final ext = ext0.isNotEmpty ? ext0 : '.jpg';

    final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedPath = p.join(dir.path, fileName);

    final savedFile = await File(picked.path).copy(savedPath);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => pages.SavedImagePage(imagePath: savedFile.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // 버튼 크기 비율 계산
    final double big = screenSize.width * 0.65;
    final double mid = screenSize.width * 0.38;
    final double small = screenSize.width * 0.27;

    const sky = Color(0xFFDCEBFF);

    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
        backgroundColor: sky, // 앱바색
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
          ),
        ],
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

          // ✅ 임시 버튼 오버레이 (나중에 이 블록만 삭제하면 됨)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, // 상태바 아래
            right: 12,
            child: SizedBox(
              height: 34,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final photos = await _buildMockPhotos();
                  if (!context.mounted) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IdentifyOverlayPage(photos: photos),
                    ),
                  );
                },
                child: const Text(
                  '임시',
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // MY Log
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.25,
            left: screenSize.width * 0.10,
            size: mid,
            backgroundColor: const Color(0xFFB0CEFF),
            text: 'MY Log',
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyLogPage())
              );
            },
          ),

          // Birder's Log
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.31,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            backgroundColor: const Color(0xFF98BFFF),
            text: 'Birder\'s \n Log',
            textHeight: 1.17,
            yOffset: 3.5,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BirdersLogMain())
              );
            },
          ),

          // 계정
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.45,
            left: screenSize.width * 0.705,
            size: small,
            backgroundColor: const Color(0xFF7FAFFF),
            text: '계정',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

              if (!context.mounted) return;

              if (!isLoggedIn) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
              else{
                final username = (prefs.getString('username') ?? '').trim();
                final email = (prefs.getString('email') ?? '').trim();
                final name = (prefs.getString('name') ?? '').trim();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MemberInfoPage(
                      username: username,
                      email: email,
                      name: name,
                      onLogout: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', false);
                        await prefs.remove('username');
                        await prefs.remove('email');
                        await prefs.remove('name');
                      },
                      onDeleteAccount: () async {
                        // TODO: 탈퇴 API 호출
                      },
                    ),
                  ),
                );
              }
            },
          ),

          // 새 검색 (메인 버튼)
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.43,
            left: screenSize.width * 0.04,
            size: big,
            backgroundColor: const Color(0xFFC5DBFF),
            text: '새 검색',
            onTap: _toggleNewSearch,
          ),

          // 새 검색 서브 메뉴 (확장 시)
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.25,
            left: screenSize.width * 0.10,
            size: mid,
            backgroundColor: const Color(0xFFB0CEFF),
            text: '촬영',
            onTap: () => _openCameraAndSave(),
          ),
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.31,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            backgroundColor: const Color(0xFF98BFFF),
            text: '사진 \n 업로드',
            onTap: () => _pickFromGalleryAndSave(),
          ),
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.45,
            left: screenSize.width * 0.705,
            size: small,
            text: 'cancel',
            onTap: _toggleNewSearch,
            backgroundColor: Colors.grey[350],
            textColor: Colors.black,
          ),
        ],
      ),
    );
  }

  // 정적 버튼
  Widget _buildBubbleButton({
    required Size screenSize,
    required double top,
    required double left,
    required double size,
    required String text,
    required VoidCallback onTap,
    double? textHeight,
    Color? backgroundColor,
    Color textColor = Colors.black,
    double yOffset = 0,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFA1C4FD),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Transform.translate(offset: Offset(0, yOffset),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.w600,
                fontSize: size * 0.23,
                color: textColor,
                height: textHeight, //
              ),
            ),
            ),
          ),

        ),
      ),
    );
  }

  // 애니메이션 버튼 (서브 메뉴)
  Widget _buildAnimatedBubbleButton({
    required Size screenSize,
    required double top,
    required double left,
    required double size,
    required String text,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color textColor = Colors.black,
  }) {
    final double centerTop = screenSize.height * 0.53 + size / 2;
    final double centerLeft = screenSize.width * 0.07 + size / 2;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      top: _isNewSearchExpanded ? top : centerTop - size / 2,
      left: _isNewSearchExpanded ? left : centerLeft - size / 2,
      width: size,
      height: size,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _isNewSearchExpanded ? 1.0 : 0.0,
        child: AnimatedScale(
          scale: _isNewSearchExpanded ? 1.0 : 0.2,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? const Color(0xFFA1C4FD),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.23,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
