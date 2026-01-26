import 'package:birder_frontend/screens/birders_log_species_result.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BirdersLogSpecies extends StatefulWidget {
  const BirdersLogSpecies({super.key});

  @override
  State<BirdersLogSpecies> createState() => _BirdersLogSpeciesState();
}

class _BirdersLogSpeciesState extends State<BirdersLogSpecies> {
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
    const sky = Color(0xFFDCEBFF);

    // 검색 결과 필터링
    final results = _allSpecies
        .where((s) => s.toLowerCase().contains(_query.trim().toLowerCase()))
        .toList();



    return Scaffold(
      backgroundColor: sky,
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
                height: 2.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '다른 Birder들이 관측한 기록 로그',
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.w700,
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
              // 1) 종별로 보기
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Image.asset(
                      'assets/images/Birder_logo_bird.png',
                      width: 45,
                      height: 45,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '종별로 보기',
                    style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(), // 임시 버튼 (DB + 로그 연결 후 삭제)
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BirdersLogSpeciesResult()),
                        );
                      },
                      child: Text(
                        '임시',
                        style: TextStyle(
                            fontFamily: 'Paperlogy',
                            fontWeight: FontWeight.w400,
                            fontSize: 16
                        ),
                      ),
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
                          hintText: '새명을 입력하세요',
                          hintStyle: TextStyle(
                            fontFamily: 'Paperlogy',
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                            color: const Color(0xFFA1C4FD),
                          ),
                        ),
                        style: TextStyle(
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
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3) 결과 영역
              Expanded(
                child: Builder(
                  builder: (context) {
                    final hasQuery = _query.trim().isNotEmpty;
                    final hasResults = results.isNotEmpty;

                    // 1) 기본 화면 (계절별 새 목록, 이번주 관측 순위(FE고정))
                    if (!hasQuery) {
                      return Scaffold(
                        backgroundColor: sky,
                        body: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '이번 주 관측 순위',
                                      style: TextStyle(
                                          fontFamily: 'Paperlogy',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 24,
                                          color: Colors.black
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.emoji_events_outlined, size: 24, color: Colors.black),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                _RankRow(rank: 1, text: '흰뺨검둥오리 (Anas zonorhyncha)'),
                                _Line(),
                                _RankRow(rank: 2, text: '까치 (Pica serica)'),
                                _Line(),
                                _RankRow(rank: 3, text: '쇠백로 (Egretta garzetta)'),
                                _Line(),

                                const SizedBox(height: 50),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    // 제목
                                    Text(
                                      '여름철에 볼 수 있는 새',
                                      style: TextStyle(
                                          fontFamily: 'Paperlogy',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 24,
                                          color: Colors.black
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 3 x 2 그리드
                                    GridView.count(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 15,
                                      mainAxisSpacing: 15,
                                      childAspectRatio: 0.72,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: const [
                                        _SeasonBirdCard(label: '물총새', imagePath: 'assets/images/birds/Alcedo atthis.webp'),
                                        _SeasonBirdCard(label: '쇠물닭', imagePath: 'assets/images/birds/Gallinula chloropus.jpg'),
                                        _SeasonBirdCard(label: '검은딱새', imagePath: 'assets/images/birds/Saxicola.webp'),
                                        _SeasonBirdCard(label: '동고비', imagePath: 'assets/images/birds/Sitta europaea.jpg'),
                                        _SeasonBirdCard(label: '황조롱이', imagePath: 'assets/images/birds/Falco tinnunculus.webp'),
                                        _SeasonBirdCard(label: '물수리', imagePath: 'assets/images/birds/Pandion haliaetus.webp'),
                                      ],
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                        ),
                      );

                    }

                    // 3) 검색 결과 없음
                    if (!hasResults) {
                      return Center(
                        child: Text(
                          '검색 결과 없음',
                          style: TextStyle(
                            fontFamily: 'Paperlogy',
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    // 2) 검색 결과 있음
                    // TODO: 검색 결과 UI
                    return const SizedBox.shrink();

                  }
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

}
class _RankRow extends StatelessWidget {
  final int rank;
  final String text;

  const _RankRow({required this.rank, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(width: 2, color: Colors.black),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                  color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.0,
      width: double.infinity,
      color: const Color(0xFF8CB6FF),
    );
  }
}

class _SeasonBirdCard extends StatelessWidget {
  final String label;
  final String imagePath;

  const _SeasonBirdCard({
    required this.label,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          label,
          style: TextStyle(
            fontFamily: 'Paperlogy',
            fontWeight: FontWeight.w400,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
