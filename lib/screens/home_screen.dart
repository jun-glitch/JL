import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// HomeScreen 위젯은 StatefulWidget을 상속받음
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // createState() 메서드를 구현하여 State 객체(_HomeScreenState)를 반환
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isNewSearchExpanded = false;

  void _toggleNewSearch() {
    setState(() {
      _isNewSearchExpanded = !_isNewSearchExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    final double big = screenSize.width * 0.65;
    final double mid = screenSize.width * 0.38;
    final double small = screenSize.width * 0.27;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF5FF),
      body: Stack(
        children: [
          Positioned(
            top: screenSize.height * 0.2,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Birder',
                style: GoogleFonts.lobster(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          _buildBubbleButton(
            top: screenSize.height * 0.35,
            left: screenSize.width * 0.10,
            size: mid,
            text: 'MY Log',
            onTap: () {},
          ),

          _buildBubbleButton(
            top: screenSize.height * 0.41,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            text: 'Birder\'s\nLog',
            onTap: () {},
          ),

          _buildBubbleButton(
            top: screenSize.height * 0.55,
            left: screenSize.width * 0.72,
            size: small,
            text: '설정',
            onTap: () {},
          ),

          _buildBubbleButton(
            top: screenSize.height * 0.53,
            left: screenSize.width * 0.07,
            size: big,
            text: '새 검색',
            onTap: _toggleNewSearch,
          ),

          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            bigSize: big,
            top: screenSize.height * 0.35,
            left: screenSize.width * 0.10,
            size: mid,
            text: '사진\n업로드',
            onTap: () {},
          ),

          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            bigSize: big,
            top: screenSize.height * 0.41,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            text: '촬영',
            onTap: () {},
          ),

          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            bigSize: big,
            top: screenSize.height * 0.55,
            left: screenSize.width * 0.72,
            size: small,
            text: 'cancel',
            onTap: _toggleNewSearch,
            backgroundColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
  Widget _buildBubbleButton({
    required double top,
    required double left,
    required double size,
    required String text,
    required VoidCallback onTap,
    Color? backgroundColor,
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
            color: backgroundColor ?? Colors.blue[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.jua(
                fontSize: size * 0.22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 버블 버튼을 위젯 헬퍼 함수 (정적 초기 메뉴용)
  Widget _buildAnimatedBubbleButton({
    required Size screenSize,
    required double bigSize,
    required double top,
    required double left,
    required double size,
    required String text,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    final double centerTop =
        screenSize.height * 0.53 + bigSize / 2;
    final double centerLeft =
        screenSize.width * 0.07 + bigSize / 2;

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
                color: backgroundColor ?? Colors.blue[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jua(
                    fontSize: size * 0.23,
                    fontWeight: FontWeight.bold,
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