import 'package:birder_frontend/screens/my_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';


class MyLogMap extends StatefulWidget {
  const MyLogMap({super.key});

  @override
  State<MyLogMap> createState() => _MyLogMapState();
}

class PhotoMarkerData {
  final LatLng point;

  final String? imageUrl;  // 서버 URL

  const PhotoMarkerData({
    required this.point,
    this.imageUrl,
  });
}
class _PhotoMarkerThumb extends StatelessWidget {
  final PhotoMarkerData item;
  const _PhotoMarkerThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    Widget img;

    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      img = Image.network(
        item.imageUrl!,
        fit: BoxFit.cover,

        // 로딩/에러 처리
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image));
        },
      );
    } else {
      img = const Center(child: Icon(Icons.image_not_supported));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(0, 3),
              color: Colors.black26,
            ),
          ],
        ),
        child: img,
      ),
    );
  }
}

class _MyLogMapState extends State<MyLogMap> {

  @override
  void initState() {
    super.initState();
    _outlineFuture = _loadKoreaOutline();
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

  Future<List<PhotoMarkerData>> _fetchObservationPhotoMarkers({
    required String speciesName,
    required DateTime? start,
    required DateTime? end,
  }) async {
    // TODO: 도감/백엔드 연결 (사용자가 업로드한 사진 리스트 + 위도/경도 + imageUrl)

    // 임시 더미
    return const [
      PhotoMarkerData(
        point: LatLng(37.5665, 126.9780),
        imageUrl: '',
      ),
      PhotoMarkerData(
        point: LatLng(36.3504, 127.3845),
        imageUrl: '',
      ),
      PhotoMarkerData(
        point: LatLng(35.1796, 129.0756),
        imageUrl: '',
      ),
    ];
  }


  Future<void> _loadKoreaOutline() async {
    final data = await rootBundle.loadString('assets/geo/korea_sido.geojson');
    _geoParser.parseGeoJsonAsString(data);
  }

  Widget _buildKoreaMap(List<PhotoMarkerData> items) {
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

          MarkerLayer(
            markers: items.map((item) {
              return Marker(
                point: item.point,
                width: 70,
                height: 70,
                child: _PhotoMarkerThumb(item: item),
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
            icon: const Icon(Icons.book),
            iconSize: 36,
            color: const Color(0xFF7FAFFF),
            onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyLogPage())
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: FutureBuilder<void>(
          future: _outlineFuture,
          builder: (context, outlineSnap) {
            if (outlineSnap.hasError) {
              return Center(child: Text('아웃라인 로드 에러: ${outlineSnap.error}'));
            }
            if (outlineSnap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<List<PhotoMarkerData>>(
              future: _fetchObservationPhotoMarkers(
                speciesName: 'ALL',
                start: null,
                end: null,
              ),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('포인트 로드 에러: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildKoreaMap(snap.data!);
              },
            );

          },
        ),
      ),


    );
  }

}