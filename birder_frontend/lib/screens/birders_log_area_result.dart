import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class BirdersLogAreaResult extends StatefulWidget {
  const BirdersLogAreaResult({super.key});

  @override
  State<BirdersLogAreaResult> createState() => _BirdersLogAreaResultState();
}

class _BirdersLogAreaResultState extends State<BirdersLogAreaResult> {

  String _fmtDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}.$m.$d';
  }

  String _fmtTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }


  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // 이번 달 마지막 날

  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }


  String _resolveAreaName(BuildContext context) {

    // 이전 화면에서 arguments로 넘겨준 값 사용
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();

    // 임시 기본값
    return '대구광역시';
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    setState(() {
      _startDate = picked;
      // 시작일이 끝일보다 뒤면 끝일도 시작일로 맞춤
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    setState(() {
      final start = _startDate;
      // 끝일이 시작일보다 앞이면 시작일로 맞춤
      _endDate = (start != null && picked.isBefore(start)) ? start : picked;
    });
  }

  Widget _dateField({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87
                ),
              ),
            ),
            const Icon(Icons.calendar_month_outlined, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const sky = Color(0xFFDCEBFF);

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -3),
                    child: Image.asset(
                      'assets/images/location.png',
                      width: 27,
                      height: 27,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(width: 13),
                  Text(
                    '지역별로 보기',
                    style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontWeight: FontWeight.w600,
                      fontSize: 27,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // (종명) 지역별 누적 관측 기록
              Center(
                child: Text(
                  '${_resolveAreaName(context)} 상세 관측 기록',
                    style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w500,
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 날짜 선택 달력칸
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF9CB9F9),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '검색 기간',
                        style: TextStyle(
                          fontFamily: 'Paperlogy',
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _dateField(
                            text: _startDate == null
                                ? '시작일'
                                : _fmt(_startDate!),
                            onTap: _pickStartDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '~',
                          style: TextStyle(
                              fontFamily: 'Paperlogy',
                              fontWeight: FontWeight.w400,
                              fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateField(
                            text: _endDate == null ? '종료일' : _fmt(_endDate!),
                            onTap: _pickEndDate,
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildLogTable(),

            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLogTable({double height = 420}) {
    if (_loadingLogs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_logError != null) {
      return Text(
        _logError!,
        style: const TextStyle(
          fontFamily: 'Paperlogy',
          fontWeight: FontWeight.w400,
          fontSize: 15,
          color: Colors.redAccent,
        ),
      );
    }

    if (_logs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: const [
                    Expanded(
                      child: Center(
                        child: Text(
                          '관측 위치',
                          style: TextStyle(
                            fontFamily: 'Paperlogy',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '관측/등록 일자',
                          style: TextStyle(
                            fontFamily: 'Paperlogy',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 헤더 아래 굵은 라인(사진처럼)
              const Divider(height: 1, thickness: 1.2, color: Colors.black54),

              // 본문(스크롤)
              SizedBox(
                height: height,
                child: ListView.separated(
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final log = _logs[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                log.location,
                                style: const TextStyle(
                                  fontFamily: 'Paperlogy',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _fmtDate(log.observedAt),
                                    style: const TextStyle(
                                      fontFamily: 'Paperlogy',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _fmtTime(log.observedAt),
                                    style: const TextStyle(
                                      fontFamily: 'Paperlogy',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }

}
class ObservationLog {
  final String location;    // 위도 경도
  final DateTime observedAt;

  ObservationLog({
    required this.location,
    required this.observedAt,
  });

  factory ObservationLog.fromJson(Map<String, dynamic> json) {
    return ObservationLog(
      location: json['location'] as String,
      observedAt: DateTime.parse(json['observed_at'] as String),
    );
  }
}

bool _loadingLogs = false;
String? _logError;
List<ObservationLog> _logs = [
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10, 17, 16, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10, 17, 11, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10, 16,  9, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10, 14, 15, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10, 14, 10, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10, 11, 12, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10, 10,  7, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10,  6, 22, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10,  6, 18, 34, 23)),
  ObservationLog(location: '35°N 128°E', observedAt: DateTime(2025, 10,  3, 10, 34, 23)),
];