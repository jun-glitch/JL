import 'package:birder_frontend/models/bird.dart';
import 'package:birder_frontend/models/observation.dart';
import 'package:birder_frontend/screens/my_log_map.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class MyLogDetails extends StatefulWidget {
  final Bird bird;

  const MyLogDetails({super.key, required this.bird});

  @override
  State<MyLogDetails> createState() => _MyLogDetailsState();
}

class _MyLogDetailsState extends State<MyLogDetails> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchDetail(widget.bird.id);

  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ✅ TODO: 서버 DB 연결 후 수정 필요
  Future<_DetailData> _fetchDetail(int birdId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // 서버에서 받아온다고 가정: 사진 URL/기록 리스트
    return _DetailData(
      photos: const [
        // 서버 URL이면 NetworkImage로 렌더됨
        'https://picsum.photos/800/800?1',
        'https://picsum.photos/800/800?2',
        'https://picsum.photos/800/800?3',
      ],
      observations: [
        Observation(
          locationText: '서울특별시 송파구',
          coordText: '15°N 135°W',
          observedAt: DateTime(2025, 9, 29, 16, 12, 11),
        ),
        Observation(
          locationText: '대구광역시 수성구',
          coordText: '17°N 130°W',
          observedAt: DateTime(2025, 9, 26, 14, 27, 56),
        ),
      ],
      scientificName: 'Alcedo atthis',
    );
  }

  @override
  Widget build(BuildContext context) {

    const sky = Color(0xFFDCEBFF);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            iconSize: 36,
            color: const Color(0xFF7FAFFF),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyLogMap())
              );},
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: SafeArea(
        top: false,
        child: FutureBuilder<_DetailData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return const Center(child: Text('데이터를 불러오지 못했어요'));
            }

            final data = snap.data!;
            final photos = data.photos;
            final obs = data.observations;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  // 1) 사진
                  _PhotoPager(
                    photos: photos,
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                  ),
                  const SizedBox(height: 20),

                  // 2) 이름(학명)
                  Text(
                    '${widget.bird.name} (${data.scientificName})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Paperlogy',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3) 로그 표
                  _ObservationTable(observations: obs),
                ],
              ),
            );
          },
        ),
      ),

    );
  }
}

class _PhotoPager extends StatelessWidget {
  const _PhotoPager({
    required this.photos,
    required this.controller,
    required this.onPageChanged,
  });

  final List<String> photos;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: PageView.builder(
          controller: controller,
          itemCount: photos.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            final url = photos[index];

            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey.shade300),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return Container(
          width: active ? 10 : 7,
          height: active ? 10 : 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.black87 : Colors.black26,
          ),
        );
      }),
    );
  }
}

// 로그 표
class _ObservationTable extends StatelessWidget {
  const _ObservationTable({required this.observations});
  final List<Observation> observations;

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('yyyy.MM.dd');
    final fmtTime = DateFormat('HH:mm:ss');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: const [
                Expanded(
                  child: Center(
                    child: Text(
                      '관측 위치',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '관측 일자',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 바디
          ...observations.map((o) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          o.coordText,
                          style: const TextStyle(
                            fontFamily: 'Paperlogy',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          o.locationText,
                          style: const TextStyle(
                            fontFamily: 'Paperlogy',
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          fmtDate.format(o.observedAt),
                          style: const TextStyle(
                            fontFamily: 'Paperlogy',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmtTime.format(o.observedAt),
                          style: const TextStyle(
                            fontFamily: 'Paperlogy',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _DetailData {
  final List<String> photos; // 사진 URL들
  final List<Observation> observations;
  final String scientificName;

  const _DetailData({
    required this.photos,
    required this.observations,
    required this.scientificName,
  });
}