import 'package:birder_frontend/screens/my_log_details.dart';
import 'package:birder_frontend/screens/my_log_map.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:birder_frontend/screens/bird_tile.dart';
import 'package:birder_frontend/models/bird.dart';

class MyLogPage extends StatefulWidget {
  const MyLogPage({super.key});

  @override
  State<MyLogPage> createState() => _MyLogPageState();
}

class _MyLogPageState extends State<MyLogPage> {
  late List<Bird> birds;
  late List<BirdOrder> orders;

  // 검색 상태
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();

    // 임시 DB
    orders = [
      BirdOrder(
        name: '기러기목',
        birds: [
          Bird(id: 1, name: '가창오리', discovered: true, imagePath: '...'),
          Bird(id: 2, name: '흰뺨오리'),
          Bird(id: 3, name: '청둥오리', discovered: true, imagePath: '...'),
          Bird(id: 4, name: '황오리'),
          Bird(id: 5, name: '기러기'),
          Bird(id: 6, name: '원앙'),
          Bird(id: 7, name: '고니'),
          Bird(id: 8, name: '큰기러기'),
        ],
      ),
      BirdOrder(
        name: '파랑새목',
        birds: [
          Bird(id: 101, name: '물총새', discovered: true, imagePath: '...'),
          Bird(id: 102, name: '???'),
          Bird(id: 103, name: '???'),
          Bird(id: 104, name: '파랑새'),
        ],
      ),
      BirdOrder(
        name: '어쩌고목',
        birds: [
          Bird(id: 201, name: '물총새', discovered: true, imagePath: '...'),
          Bird(id: 202, name: '???'),
          Bird(id: 203, name: '???'),
          Bird(id: 204, name: '파랑새'),
          Bird(id: 205, name: '???'),
          Bird(id: 206, name: '파랑새'),
          Bird(id: 207, name: '???'),
          Bird(id: 208, name: '파랑새'),
        ],
      ),
    ];

    birds = orders.expand((o) => o.birds).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sky = Color(0xFFDCEBFF);

    final bool searching = _query.trim().isNotEmpty;

    final List<Bird> filtered = !searching
        ? const []
        : birds.where((b) => b.name.contains(_query.trim())).toList();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            iconSize: 36,
            color: const Color(0xFF7FAFFF),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyLogMap()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _searchSection()),

          if (searching) ...[
            if (filtered.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('검색 결과가 없어요',
                        style: TextStyle(fontSize: 16, color: Colors.black54)),
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
                    childAspectRatio: 0.75,
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
          ] else ...[
            // 검색 아닐 때: 목 섹션들
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final order = orders[index];
                    return _OrderSection(
                      title: order.name,
                      birds: order.birds,
                      onTapBird: (b) => _openDetailIfEnabled(b),
                    );
                  },
                  childCount: orders.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 상단: 검색 섹션
  Widget _searchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: 28,
              color: Color(0xFFA1C4FD),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '새명을 입력하세요',
                  hintStyle: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xFFA1C4FD),
                  ),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontFamily: 'Paperlogy',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black45),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                  FocusScope.of(context).unfocus();
                },
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
      MaterialPageRoute(builder: (_) => MyLogDetails(bird: bird)),
    );
  }
}


class BirdOrder {
  final String name;
  final List<Bird> birds;
  const BirdOrder({
    required this.name,
    required this.birds
    });
}

class _OrderSection extends StatefulWidget {
  const _OrderSection({
    required this.title,
    required this.birds,
    required this.onTapBird,
  });

  final String title;
  final List<Bird> birds;
  final void Function(Bird bird) onTapBird;

  @override
  State<_OrderSection> createState() => _OrderSectionState();
}

class _OrderSectionState extends State<_OrderSection> {
  final ScrollController _hCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  double _calcScrollContentWidth({
    required int itemCount,
    required double tileW,
    required double gap,
  }) {

    final columns = (itemCount / 2).ceil();
    if (columns <= 0) return 0;

    return columns * tileW + (columns - 1) * gap;
  }

  @override
  Widget build(BuildContext context) {
    const double paddingH = 12;
    const double gap = 12;

    final double screenW = MediaQuery.of(context).size.width;
    final double tileW = (screenW - paddingH * 2 - gap * 2) / 3;
    final double tileH = tileW / 0.75;
    final double gridH = tileH * 2 + gap;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${widget.title}]',
            style: const TextStyle(
              fontFamily: 'Paperlogy',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: gridH + 16,
            child: RawScrollbar(
              controller: _hCtrl,
              thumbVisibility: true,
              thickness: 4,
              radius: const Radius.circular(10),
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GridView.builder(
                  controller: _hCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: widget.birds.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    mainAxisExtent: tileW,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final bird = widget.birds[index];
                    return BirdTile(
                      bird: bird,
                      onOpenDetail: () => widget.onTapBird(bird),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
