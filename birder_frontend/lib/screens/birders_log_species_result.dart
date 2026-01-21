import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';


class BirdersLogSpeciesResult extends StatefulWidget {
  const BirdersLogSpeciesResult({super.key});

  @override
  State<BirdersLogSpeciesResult> createState() => _BirdersLogSpeciesResultState();
}

class _BirdersLogSpeciesResultState extends State<BirdersLogSpeciesResult> {
  final TextEditingController _searchCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // 이번 달 마지막 날

    _outlineFuture = _loadKoreaOutline();
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }

  String _resolveSpeciesName(BuildContext context) {

    // 이전 화면에서 arguments로 넘겨준 값 사용
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();

    // 임시 기본값
    return '도요새';
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
                style: GoogleFonts.jua(fontSize: 18, color: Colors.black87),
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
  bool _outlineLoaded = false;


  // 대한민국 범위(지도 밖으로 못 나가게 제한)
  final LatLngBounds _southKoreaBounds = LatLngBounds(
    const LatLng(33.0, 124.3), // 남서
    const LatLng(38.8, 131.1), // 북동
  );

  Future<List<LatLng>> _fetchObservationPoints({
    required String speciesName,
    required DateTime? start,
    required DateTime? end,
  }) async {
    // TODO: 백엔드 API로 교체

    // 임시 더미
    return [
      const LatLng(37.5665, 126.9780), // 서울
      const LatLng(35.1796, 129.0756), // 부산
    ];
  }

  Future<void> _loadKoreaOutline() async {
    final data = await rootBundle.loadString('assets/geo/korea_sido.geojson');
    _geoParser.parseGeoJsonAsString(data);
  }


  Widget _buildKoreaMap(List<LatLng> points) {
    final lines = _geoParser.polygons.expand((pg) {
      final pts = pg.points;
      if (pts.isEmpty) return <Polyline>[];
      return [
        Polyline(
          points: pts,
          strokeWidth: 1.2,
          color: const Color(0xFF7AA6F5),
        ),
      ];
    }).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(36.1, 127.6),
          initialZoom: 6.7,
          minZoom: 5,
          maxZoom: 18,
          // 대한민국 범위
          cameraConstraint: CameraConstraint.contain(bounds: _southKoreaBounds),
          backgroundColor: Colors.transparent,
        ),
        children: [
          //지도 아웃라인
          PolylineLayer(polylines: lines),

          // 로그 점 (위도/경도) 찍기
          MarkerLayer(
            markers: points.map((p) {
              return Marker(
                point: p,
                width: 15,
                height: 15,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1F66FF), // 점 색
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
                    style: GoogleFonts.jua(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // (종명) 지역별 누적 관측 기록
              Center(
                child: Text(
                  '${_resolveSpeciesName(context)} 지역별 누적 관측 기록',
                  style: GoogleFonts.jua(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
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
                        style: GoogleFonts.jua(
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
                          style: GoogleFonts.jua(fontSize: 16),
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

                    return FutureBuilder<List<LatLng>>(
                      future: _fetchObservationPoints(
                        speciesName: _resolveSpeciesName(context),
                        start: _startDate,
                        end: _endDate,
                      ),
                      builder: (context, pointSnap) {
                        if (pointSnap.hasError) {
                          return Center(child: Text('포인트 로드 에러: ${pointSnap.error}'));
                        }
                        if (!pointSnap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return _buildKoreaMap(pointSnap.data!);
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