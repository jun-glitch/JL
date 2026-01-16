import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BirdersLogArea extends StatefulWidget {
  const BirdersLogArea({super.key});

  @override
  State<BirdersLogArea> createState() => _BirdersLogAreaState();
}

class _BirdersLogAreaState extends State<BirdersLogArea> {
  final TextEditingController _searchCtrl = TextEditingController();

  // 임시 리스트
  final List<String> _allSpecies = const [
    '참새',
    '까치',
    '비둘기',
    '직박구리',
    '까마귀',
  ];

  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    const sky = Color(0xFFDCEBFF); // 연한 하늘색

    // 검색 결과 필터링
    final results = _allSpecies
        .where((s) => s.toLowerCase().contains(_query.trim().toLowerCase()))
        .toList();

    final bool hasQuery = _query.trim().isNotEmpty;
    final bool hasResults = results.isNotEmpty;

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
              style: GoogleFonts.jua(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/location.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),

              const SizedBox(width: 10),
              Text(
                '지역별로 보기',
                style: GoogleFonts.jua(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),

              const SizedBox(height: 14),

              // 2) 검색바
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 28, color: const Color(0xFFA1C4FD)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '지역명을 입력하세요 (시, 군, 구)',
                          hintStyle: GoogleFonts.jua(
                            fontSize: 18,
                            color: const Color(0xFFA1C4FD),
                          ),
                        ),
                        style: GoogleFonts.jua(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: 현재 위치 가져오기
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFA1C4FD),
                          shape: const StadiumBorder(), // 모양
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text(
                          '현재 위치',
                          style: GoogleFonts.jua(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black45),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3) 결과 영역
              Expanded(
                child: Builder(
                  builder: (context) {
                    final hasQuery = _query.trim().isNotEmpty;
                    final hasResults = results.isNotEmpty;

                    // 1) 기본 화면 (인기 검색어, 계절별 새 목록)
                    if (!hasQuery) {
                      // TODO: 검색 전 기본 화면 UI
                      return const SizedBox.shrink();
                    }

                    // 3) 검색 결과 없음
                    if (!hasResults) {
                      return Center(
                        child: Text(
                          '검색 결과 없음',
                          style: GoogleFonts.jua(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    // 2) 검색 결과 있음
                    // TODO: 검색 결과 UI
                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
