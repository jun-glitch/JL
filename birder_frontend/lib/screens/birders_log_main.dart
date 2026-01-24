import 'package:birder_frontend/screens/birders_log_area.dart';
import 'package:birder_frontend/screens/birders_log_species.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class BirdersLogMain extends StatefulWidget {
  const BirdersLogMain({super.key});

  @override
  State<BirdersLogMain> createState() => _BirdersLogMainState();
}

class _BirdersLogMainState extends State<BirdersLogMain> {

  @override
  Widget build(BuildContext context) {

    const sky = Color(0xFFDCEBFF); // 연한 하늘색

    return Scaffold(
      backgroundColor: sky, // 화면 배경색
      appBar: AppBar(
        backgroundColor: sky,
        elevation: 0,
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Birder\'s Log',
              style: GoogleFonts.lobster(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 2.0, // 줄간격
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '다른 Birder들이 관측한 기록 로그',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 250),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _MenuCardButton(
                    label: '지역별로 보기',
                    onTap: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BirdersLogArea())
                      );
                    },
                    iconWidget: Image.asset(
                      'assets/images/location.png',
                      width: 115,
                      height: 115,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _MenuCardButton(
                    label: '종별로 보기',
                    onTap: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BirdersLogSpecies())
                      );
                    },
                    iconWidget: Image.asset(
                      'assets/images/Birder_logo_bird.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }
}

class _MenuCardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget iconWidget;

  const _MenuCardButton({
    required this.label,
    required this.onTap,
    required this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 240,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 150,
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w500,
                fontSize: 25,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}