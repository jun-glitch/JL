import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// HomeScreen 위젯은 StatefulWidget을 상속받음
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// _HomeScreenState 클래스는 HomeScreen 위젯의 상태를 관리
class _HomeScreenState extends State<HomeScreen> {
  bool _isNewSearchExpanded = false; // 새 검색 버튼 확장 여부

  void _toggleNewSearch() {
    setState(() {
      _isNewSearchExpanded = !_isNewSearchExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // 버튼 크기 비율 계산
    final double big = screenSize.width * 0.65;
    final double mid = screenSize.width * 0.38;
    final double small = screenSize.width * 0.27;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF5FF),
      body: Stack(
        children: [
          // 'Birder' 로고
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
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // 'MY Log'
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.35,
            left: screenSize.width * 0.10,
            size: mid,
            text: 'MY Log',
            onTap: () => print('MY Log 클릭!'),
          ),

          // 'Birder\'s Log'
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.41,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            text: 'Birder\'s \n Log',
            onTap: () => print('Birder\'s Log 클릭!'),
          ),

          // '설정'
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.55,
            left: screenSize.width * 0.72,
            size: small,
            text: '설정',
            onTap: () => print('설정 클릭!'),
          ),

          // '새 검색' (가장 큰 버튼)
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.53,
            left: screenSize.width * 0.07,
            size: big,
            text: '새 검색',
            onTap: _toggleNewSearch,
            backgroundColor: _isNewSearchExpanded ? Colors.blue[200] : Colors.blue[200],
          ),

          // 새 검색 서브 메뉴 (확장 시)
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.35,
            left: screenSize.width * 0.10,
            size: mid,
            text: '사진 \n 업로드',
            onTap: () => print('사진 업로드 클릭!'),
          ),
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.41,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            text: '촬영',
            onTap: () => print('촬영 클릭!'),
          ),
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.55,
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
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 애니메이션 버튼 (새 검색 서브 메뉴용)
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
