import 'package:birder_frontend/models/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';


class BirdersLogSpeciesResult extends StatefulWidget {
  final String speciesCode;
  final String speciesName;

  const BirdersLogSpeciesResult({
    super.key,
    required this.speciesCode,
    required this.speciesName,
  });

  @override
  State<BirdersLogSpeciesResult> createState() => _BirdersLogSpeciesResultState();
}

class _BirdersLogSpeciesResultState extends State<BirdersLogSpeciesResult> {

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    _outlineFuture = _loadKoreaOutline();
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
  String _fmtDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y.$m.$d  $hh:$mm:$ss';
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
                    fontWeight: FontWeight.w400,
                    fontSize: 18, color: Colors.black87),
              ),
            ),
            const Icon(Icons.calendar_month_outlined, size: 24),
          ],
        ),
      ),
    );
  }

  late final Future<void> _outlineFuture;

  final GeoJsonParser _geoParser = GeoJsonParser(
    // 지도 아웃라인 선
    defaultPolygonFillColor: Colors.transparent,
    defaultPolygonIsFilled: false,
    defaultPolygonBorderColor: const Color(0xFFA1C4FD),
    defaultPolygonBorderStroke: 1.2,

    defaultPolylineColor: const Color(0xFFA1C4FD),
    defaultPolylineStroke: 1.2,
  );


  // 대한민국 범위(지도 밖으로 못 나가게 제한)
  final LatLngBounds _southKoreaBounds = LatLngBounds(
    const LatLng(33.0, 124.3), // 남서
    const LatLng(38.8, 131.1), // 북동
  );

  void _openLogPopup(SpeciesMapRecord r) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _LogPopup(record: r),
    );
  }

  void _openRecordPopup(SpeciesMapRecord r) {
    final when = r.obsDate ?? r.regDate;
    final whenText = when == null ? '-' : _fmtDateTime(when);

    final url = (r.sFileNum ?? '').trim();
    final hasUrl = url.isNotEmpty;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('관측 기록'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasUrl)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 160,
                    child: Center(child: Text('사진을 불러올 수 없습니다')),
                  ),
                ),
              )
            else
              const SizedBox(
                height: 160,
                child: Center(child: Text('사진 URL이 없습니다')),
              ),

            const SizedBox(height: 10),

            Text('위치: ${r.location?.isNotEmpty == true ? r.location : '-'}'),

            const SizedBox(height: 6),

            Text('일시: $whenText'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }


    Future<List<SpeciesMapRecord>> _fetchRecords() async {
    final dio = ApiClient().dio;

    final qp = <String, dynamic>{
      'species_code': widget.speciesCode,
    };

    if (_startDate != null) qp['start'] = _fmt(_startDate!);
    if (_endDate != null) qp['end'] = _fmt(_endDate!);

    final res = await dio.get('/api/birds/species/map/', queryParameters: qp);

    final data = res.data;
    if (data is! Map) return const [];

    final raw = data['records'];
    final list = (raw is List) ? raw : const [];

    return list
        .whereType<Map>()
        .map((e) => SpeciesMapRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }


  Future<void> _loadKoreaOutline() async {
    final data = await rootBundle.loadString('assets/geo/korea_sido.geojson');
    _geoParser.parseGeoJsonAsString(data);
  }

  void _onMarkerTap(SpeciesMapRecord r) {
    _openLogPopup(r);
  }

  Widget _buildKoreaMap(List<SpeciesMapRecord> records) {

    final lines = _geoParser.polygons.expand((pg) {
      final pts = pg.points;
      if (pts.isEmpty) return <Polyline>[];
      return [
        Polyline(points: pts, strokeWidth: 1.2, color: const Color(0xFF7AA6F5)),
        ];
       }).toList();


    final markers = records
        .where((r) => r.latitude != null && r.longitude != null)
        .map(
          (r) => Marker(
        point: LatLng(r.latitude!, r.longitude!),
        width: 18,
        height: 18,
        child: GestureDetector(
          onTap: () => _onMarkerTap(r),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F66FF),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  blurRadius: 6,
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(36.1, 127.6),
          initialZoom: 6.7,
          minZoom: 5,
          maxZoom: 18,
          cameraConstraint: CameraConstraint.contain(bounds: _southKoreaBounds),
          backgroundColor: Colors.transparent,
        ),
        children: [

          PolylineLayer(polylines: lines),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }


  Widget _buildKoreaMapWithOverlay({
    required List<SpeciesMapRecord> records,
    String? overlayMessage,
    bool showLoading = false,
  }) {
    return Stack(
      children: [
        _buildKoreaMap(records), // 아웃라인 + 마커(탭 가능)

        if (showLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),

        if (overlayMessage != null && overlayMessage.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9CB9F9), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      overlayMessage,
                      style: const TextStyle(
                        fontFamily: 'Paperlogy',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const sky = Color(0xFFDCEBFF);

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
              // 종별로 보기
              Row(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
              const SizedBox(height: 14),
              // (종명) 지역별 누적 관측 기록
              Center(
                child: Text(
                  '${widget.speciesName} 지역별 누적 관측 기록',
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w400,
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 날짜 선택 달력칸
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF9CB9F9),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '검색 기간',
                        style: TextStyle(
                          fontFamily: 'Paperlogy',
                          fontWeight: FontWeight.w400,
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
              const SizedBox(height: 16),

              Expanded(
                child: FutureBuilder<void>(
                  future: _outlineFuture,
                  builder: (context, outlineSnap) {
                    if (outlineSnap.hasError) {
                      return Center(child: Text('아웃라인 로드 에러: ${outlineSnap.error}'));
                    }
                    if (outlineSnap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return FutureBuilder<List<SpeciesMapRecord>>(
                      future: _fetchRecords(),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return _buildKoreaMapWithOverlay(records: const [], showLoading: true);
                        }
                        if (snap.hasError) {
                          return _buildKoreaMapWithOverlay(
                            records: const [],
                            overlayMessage: '포인트 로드 에러: ${snap.error}',
                          );
                        }

                        final records = snap.data ?? const <SpeciesMapRecord>[];

                        if (records.isEmpty) {
                          return _buildKoreaMapWithOverlay(
                            records: const [],
                            overlayMessage: '조건에 맞는 관측 기록이 없습니다.',
                          );
                        }

                        return _buildKoreaMapWithOverlay(records: records);
                      },
                    );
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


class SpeciesMapRecord {
  final int? logId;
  final String? sFileNum;
  final DateTime? obsDate;
  final DateTime? regDate;
  final String? location;
  final double? latitude;
  final double? longitude;

  SpeciesMapRecord({
    this.logId,
    this.sFileNum,
    this.obsDate,
    this.regDate,
    this.location,
    this.latitude,
    this.longitude,
  });

  factory SpeciesMapRecord.fromJson(Map<String, dynamic> json) {
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

    return SpeciesMapRecord(
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

class _LogPopup extends StatelessWidget {
  final SpeciesMapRecord record;
  const _LogPopup({required this.record});

  String _fmtDateTime(dynamic v) {
    try {
      DateTime dt;
      if (v is DateTime) {
        dt = v;
      } else {
        dt = DateTime.parse(v.toString()).toLocal();
      }

      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return '$y.$m.$d  $hh:$mm:$ss';
    } catch (_) {
      return v?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = (record.location ?? '').trim();
    final area = loc.isEmpty ? '위치 정보 없음' : loc;

    final when = record.obsDate ?? record.regDate;
    final whenText = when == null ? '' : _fmtDateTime(when);

    final url = (record.sFileNum ?? '').trim();

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
                  child: AspectRatio(
                    aspectRatio: 1.2, // 원하는 비율로 조절
                    child: (url == null || url.isEmpty)
                        ? Container(
                      color: Colors.black12,
                      child: const Center(
                        child: Text(
                          '사진 없음',
                          style: TextStyle(fontFamily: 'Paperlogy'),
                        ),
                      ),
                    )
                        : Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        child: const Center(
                          child: Text(
                            '이미지 로드 실패',
                            style: TextStyle(fontFamily: 'Paperlogy'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽 위 X 버튼
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}