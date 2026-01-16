import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:birder_frontend/screens/bird_tile.dart';
import 'package:birder_frontend/screens/bird_detail_page.dart';


class MyLogPage extends StatefulWidget {
  const MyLogPage({super.key});

  @override
  State<MyLogPage> createState() => _MyLogPageState();
}

class _MyLogPageState extends State<MyLogPage> {
  late List<Bird> birds;

  // 검색 상태
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();

    // 임시 DB
    birds = [
      Bird(id: 1, name: '가창오리'),
      Bird(id: 2, name: '흰뺨오리'),
      Bird(id: 3, name: '청둥오리'),
      ...List.generate(497, (i) {
        final idx = i + 4;
        return Bird(id: idx, name: '종 $idx');
      }),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Bird> filtered = _query.trim().isEmpty
        ? birds
        : birds.where((b) => b.name.contains(_query.trim())).toList();

    const sky = Color(0xFFDCEBFF); // 연한 하늘색

    return Scaffold(
      backgroundColor: sky, // 화면 배경색
      appBar: AppBar(
        backgroundColor: sky, // 앱바 색
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

      body: CustomScrollView(
        slivers: [
          // 검색 섹션
          SliverToBoxAdapter(child: _searchSection()),

          // 검색 결과가 없을 때 안내
          if (filtered.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '검색 결과가 없어요',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final bird = filtered[index];
                    return BirdTile(
                      bird: bird,
                      onOpenDetail: () => _openDetailIfEnabled(bird),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // 상단: 검색 섹션
  Widget _searchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 4),
              color: Color(0x1A000000),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.black45),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: '새명을 입력하세요',
                  hintStyle: TextStyle(color: Colors.black26),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _query = '');
                  FocusScope.of(context).unfocus();
                },
                child: const Icon(Icons.close, color: Colors.black38),
              ),
          ],
        ),
      ),
    );
  }

  // 발견된 경우에만 상세 이동
  void _openDetailIfEnabled(Bird bird) {
    final enabled = bird.discovered && (bird.imagePath?.isNotEmpty ?? false);

    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 발견하지 않았어요')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BirdDetailPage(bird: bird)),
    );
  }
}
class Bird {
  final int id;
  final String name;
  bool discovered;
  String? imagePath;

  Bird({
    required this.id,
    required this.name,
    this.discovered = false,
    this.imagePath,
  });
}
