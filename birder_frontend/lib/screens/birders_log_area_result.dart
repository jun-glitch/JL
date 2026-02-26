import 'package:birder_frontend/models/api_client.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class BirdersLogAreaResult extends StatefulWidget {
  const BirdersLogAreaResult({super.key});

  @override
  State<BirdersLogAreaResult> createState() => _BirdersLogAreaResultState();
}

class _BirdersLogAreaResultState extends State<BirdersLogAreaResult> {

  Map<String, dynamic> _args(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) return args;
    return {};
  }

  String _titleAreaLine(BuildContext context) {
    final a = _args(context);
    final region = (a['region'] ?? '').toString();
    final district = (a['district'] ?? '').toString();
    final s = '$region $district'.trim();
    return s.isEmpty ? '지역' : s;
  }

  String _titleSpeciesLine(BuildContext context) {
    final a = _args(context);
    final speciesName = (a['species_name'] ?? '').toString().trim();
    return speciesName.isEmpty ? '상세 관측 기록' : '$speciesName 상세 관측 기록';
  }

  bool _loadingLogs = false;
  String? _logError;
  List<ObservationLog> _logs = [];

  Future<void> _fetchLogs() async {
    final ctx = context;
    final a = _args(ctx);

    final region = (a['region'] ?? '').toString();
    final district = (a['district'] ?? '').toString();
    final speciesCode = (a['species_code'] ?? '').toString();


    if (region.isEmpty || district.isEmpty || speciesCode.isEmpty) {
      setState(() => _logError = '필수 파라미터가 비어있습니다.');
      return;
    }

    setState(() {
      _loadingLogs = true;
      _logError = null;
      _logs = [];
    });

    try {
      final dio = ApiClient().dio;

      final qp = <String, dynamic>{
        'region': region,
        'district': district,
        'species_code': speciesCode,
      };
      
      if (_startDate != null) qp['start'] = _startDate!.toIso8601String();
      if (_endDate != null) qp['end'] = _endDate!.toIso8601String();

      final res = await dio.get(
          '/api/birds/areas/logs/', 
          queryParameters: qp);

      final data = Map<String, dynamic>.from(res.data);
      final records = (data['records'] as List?) ?? [];

      final logs = records
          .map((e) => ObservationLog.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      logs.sort((a, b) {
        final ad = a.obsDate ?? a.regDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.obsDate ?? b.regDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() => _logs = logs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _logError = '상세 기록을 불러오지 못했어요: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loadingLogs = false);
    }
  }

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

  String _fmtDateTimeOrDash(DateTime? dt) {
    if (dt == null) return '-';
    return '${_fmtDate(dt)} ${_fmtTime(dt)}';
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }

  DateTime? _startDate;
  DateTime? _endDate;


  @override
  void initState() {
    super.initState();

   // final now = DateTime.now();
    _startDate = null; //DateTime(2000, 1, 1);
    _endDate = null; //DateTime(now.year, now.month + 1, 0); // 이번 달 마지막 날
    
    WidgetsBinding.instance.addPostFrameCallback((_){
      _fetchLogs();
    });
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
    _fetchLogs();
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

  void _openLogPopup(ObservationLog log) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _LogPopupFromObservation(log: log),
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
                child: Column(
                  children: [
                    Text(
                      _titleAreaLine(context), // 서울 서대문구
                      style: const TextStyle(
                        fontFamily: 'Paperlogy',
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _titleSpeciesLine(context), //큰부리까마귀
                      style: const TextStyle(
                        fontFamily: 'Paperlogy',
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                  ],
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

                    return InkWell(
                      onTap: () => _openLogPopup(log),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                log.location,
                                style: const TextStyle(
                                  fontFamily: 'Paperlogy',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),

                          Expanded(
                            child: Center(
                              child: Text(
                                _fmtDateTimeOrDash(log.displayDate),
                                style: const TextStyle(
                                  fontFamily: 'Paperlogy',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
  final int? logId;
  final String? sFileNum;
  final DateTime? obsDate;
  final DateTime? regDate;
  final String location;
  final double? latitude;
  final double? longitude;

  ObservationLog({
    this.logId,
    this.sFileNum,
    this.obsDate,
    this.regDate,
    required this.location,
    this.latitude,
    this.longitude,
  });

  DateTime? get displayDate => obsDate ?? regDate;

  factory ObservationLog.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    double? _parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return ObservationLog(
      logId: _parseInt(json['log_num']),
      sFileNum: (json['s_filenum'] ?? '').toString().trim(),
      obsDate: _parseDate(json['obs_date']),
      regDate: _parseDate(json['reg_date']),
      location: (json['location'] ?? '').toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }
}
class _LogPopupFromObservation extends StatelessWidget {
  final ObservationLog log;
  const _LogPopupFromObservation({required this.log});

  String _fmtDateTimeOrDash(DateTime? dt) {
    if (dt == null) return '-';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y.$m.$d  $hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final loc = (log.location).toString().trim();
    final area = loc.isEmpty ? '위치 정보 없음' : loc;

    final when = log.obsDate ?? log.regDate;
    final whenText = _fmtDateTimeOrDash(when);

    final url = (log.sFileNum ?? '').trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  area,
                  style: const TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  whenText,
                  style: const TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url.isEmpty
                      ? const SizedBox(
                    height: 350,
                    child: Center(child: Text('사진 URL이 없습니다')),
                  )
                      : Image.network(
                    url,
                    height: 350,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 350,
                      child: Center(child: Text('사진을 불러올 수 없습니다')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}