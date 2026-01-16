import 'dart:io';

import 'package:birder_frontend/screens/birders_log_main.dart';
import 'package:birder_frontend/screens/log_in.dart';
import 'package:birder_frontend/screens/my_log.dart';
import 'package:birder_frontend/screens/sign_up.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart'  as p;
import 'package:path_provider/path_provider.dart';
import 'saved_image_page.dart' as pages;

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
            child: IconButton(
              iconSize: 30,
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage())
                );
              },
            ),
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

          // MY Log
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.25,
            left: screenSize.width * 0.10,
            size: mid,
            text: 'MY Log',
            textHeight: 1.0,
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
            text: 'Birder\'s \n Log',
            textHeight: 0.9,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BirdersLogMain())
              );
            },
          ),


          // 설정
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.45,
            left: screenSize.width * 0.72,
            size: small,
            text: '설정',
            textHeight: 1.0,
            onTap: () => print('설정 클릭!'),
          ),

          // 새 검색 (메인 버튼)
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.43,
            left: screenSize.width * 0.07,
            size: big,
            text: '새 검색',
            textHeight: 1.0,
            onTap: _toggleNewSearch,
            backgroundColor: _isNewSearchExpanded ? const Color(0xFFA1C4FD) : const Color(0xFFA1C4FD),
          ),

          // 새 검색 서브 메뉴 (확장 시)
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.25,
            left: screenSize.width * 0.10,
            size: mid,
            text: '촬영',
            onTap: () => _openCameraAndSave(),
          ),
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.31,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            text: '사진 \n 업로드',
            onTap: () => _pickFromGalleryAndSave(),
          ),
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.45,
            left: screenSize.width * 0.72,
            size: small,
            text: 'cancel',
            onTap: _toggleNewSearch,
            backgroundColor: Colors.grey[300],
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
    required double textHeight,
    Color? backgroundColor,
    Color textColor = Colors.black,
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
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.jua(
                fontSize: size * 0.23,
                color: textColor,
                height: 1.15, //
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
                  style: GoogleFonts.jua(
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
