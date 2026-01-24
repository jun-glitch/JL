import 'package:birder_frontend/screens/birders_log_area_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BirdersLogArea extends StatefulWidget {
  const BirdersLogArea({super.key});

  @override
  State<BirdersLogArea> createState() => _BirdersLogAreaState();
}

class SpeciesCount {
  final String species;
  final int count;

  SpeciesCount({required this.species, required this.count});

  factory SpeciesCount.fromJson(Map<String, dynamic> json) {
    return SpeciesCount(
      species: json['species'] as String,
      count: (json['count'] as num).toInt(),
    );
  }
}


class _BirdersLogAreaState extends State<BirdersLogArea> {
  final TextEditingController _searchCtrl = TextEditingController();

  final Map<String, List<String>> regionMap = {
    '서울': ['강남구', '강동구', '강북구', '강서구', '관악구', '광진구', '구로구', '금천구', '노원구', '도봉구',
            '동대문구', '동작구', '마포구', '서대문구', '서초구', '성동구',  '성북구', '송파구', '양천구', '영등포구', '용산구', '은평구', '종로구', '중구', '중랑구'],
    '인천': ['강화군', '옹진군', '중구', '동구', '미추홀구', '연수구', '남동구', '부평구', '계양구', '서구'],
    '대전': ['동구', '중구', '서구', '유성구', '대덕구'],
    '대구': ['중구', '동구', '서구', '남구', '북구', '수성구', '달서구', '달성군', '군위군'],
    '광주': ['동구', '서구', '남구', '북구', '광산구'],
    '울산': ['중구', '남구', '동구', '북구', '울주군'],
    '부산': ['중구', '서구', '동구', '영도구', '부산진구', '동래구', '남구', '북구', '해운대구', '사하구', '금정구', '강서구', '연제구', '수영구', '사상구', '기장군'],
    '세종': ['세종특별자치시'],
    '강원': ['강릉시', '동해시', '삼척시', '속초시', '원주시', '춘천시', '태백시','고성군', '양구군', '양양군',
            '영월군', '인제군', '정선군', '철원군', '평창군', '홍천군', '화천군', '횡성군'],
    '경기': ['가평군', '고양특례시', '과천시', '광명시', '광주시', '구리시', '군포시','김포시', '남양주시', '동두천시',
            '부천시', '성남시', '수원특례시', '시흥시', '안산시', '안성시', '안양시', '양주시', '양평군', '여주시', '연천군', '오산시',
            '용인특례시', '의왕시', '의정부시', '이천시', '파주시', '평택시', '포천시', '하남시', '화성특례시'],
    '충남': ['천안시', '공주시', '보령시', '아산시', '서산시', '논산시', '계룡시', '당진시', '금산군', '부여군', '서천군', '청양군', '홍성군', '예산군', '태안군'],
    '충북': ['청주시', '충주시', '제천시', '보은군', '옥천군', '영동군', '증평군', '진천군', '괴산군', '음성군', '단양군'],
    '경북': ['포항시', '경주시', '김천시', '안동시', '구미시', '영주시', '영천시', '상주시', '문경시', '경산시', '의성군',
            '청송군', '영양군', '영덕군', '청도군', '고령군', '성주군', '칠곡군', '예천군', '봉화군', '울진군', '울릉군'],
    '경남': ['창원시', '진주시', '김해시', '양산시', '거제시', '통영시', '사천시', '밀양시', '의령군', '함안군', '창녕군',
            '고성군', '남해군', '하동군', '산청군', '함양군', '거창군', '합천군'],
    '전북': ['전주시', '군산시', '익산시', '정읍시', '남원시', '김제시', '완주군', '진안군', '무주군', '장수군', '임실군', '순창군', '고창군', '부안군'],
    '전남': ['목포시', '여수시', '순천시', '나주시', '광양시', '담양군', '곡성군', '구례군', '고흥군', '보성군', '화순군',
            '장흥군', '강진군', '해남군', '영암군', '무안군', '함평군', '영광군','장성군', '완도군', '진도군', '신안군'],
    '제주': ['제주시', '서귀포시'],
  };

  late String selectedRegion;
  String? selectedDistrict;

  final ScrollController _leftCtrl = ScrollController();
  final ScrollController _rightCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedRegion = regionMap.keys.first;
  }

  @override
  void dispose() {
    _leftCtrl.dispose();
    _rightCtrl.dispose();
    super.dispose();
  }

  // 임시 리스트
  final List<String> _allSpecies = const [
    '참새',
    '까치',
    '비둘기',
    '직박구리',
    '까마귀',
  ];

  @override
  Widget build(BuildContext context) {

    final leftItems = regionMap.keys.toList();
    final rightItems = regionMap[selectedRegion] ?? [];

    const sky = Color(0xFFDCEBFF); // 연한 하늘색

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
            mainAxisSize: MainAxisSize.max,
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
                  fontWeight: FontWeight.w500,
                  fontSize: 27,
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
                      MaterialPageRoute(builder: (_) => const BirdersLogAreaResult()),
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


              const SizedBox(height: 12),

          // 지역명 선택 스크롤 박스
          Container(
            height: 340,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Scrollbar(
                    controller: _leftCtrl,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _leftCtrl,
                      itemCount: leftItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (context, i) {
                        final item = leftItems[i];
                        final isSelected = item == selectedRegion;

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              selectedRegion = item;
                              selectedDistrict = null;

                              _summary = [];
                              _summaryError = null;
                            });
                            if (_rightCtrl.hasClients) _rightCtrl.jumpTo(0);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.0),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.black87 : Colors.blueGrey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: VerticalDivider(thickness: 1, width: 1),
                ),

                Expanded(
                  child: Scrollbar(
                    controller: _rightCtrl,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _rightCtrl,
                      itemCount: rightItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (context, i) {
                        final district = rightItems[i];
                        final isSelectedDistrict = (selectedDistrict == district);

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() => selectedDistrict = district);
                            debugPrint('선택: $selectedRegion > $district');

                            _fetchSummary();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelectedDistrict
                                  ? Colors.white.withOpacity(0.90)
                                  : Colors.white.withOpacity(0.0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              district,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                fontWeight: isSelectedDistrict ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),

                        );
                      },
                    ),
                  ),
                ),
                ],
              ),
            ),
              const SizedBox(height: 30),

              Text(
                selectedDistrict == null
                    ? '누적 관측 요약'
                    : '$selectedRegion $selectedDistrict 누적 관측',
                style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w400,
                    fontSize: 23,
                    color: Colors.black87),
              ),

              const SizedBox(height: 10),

              _buildSummaryTable(),

            ],
        ),
      ),
    ),
    );
  }
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8000', // 에뮬레이터면 10.0.2.2
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));

  bool _loadingSummary = false;
  String? _summaryError;
  List<SpeciesCount> _summary = [];

  Future<void> _fetchSummary() async {
    if (selectedDistrict == null) return;

    setState(() {
      _loadingSummary = true;
      _summaryError = null;
      _summary = [];
    });

    try {
      final res = await _dio.get(
        '/api/observations/summary',
        queryParameters: {
          'region': selectedRegion,
          'district': selectedDistrict,
        },
      );

      final list = (res.data as List)
          .map((e) => SpeciesCount.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // 정렬
      list.sort((a, b) => b.count.compareTo(a.count));

      if (!mounted) return;
      setState(() => _summary = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _summaryError = '데이터를 불러오지 못했어요: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loadingSummary = false);
    }
  }

  Widget _buildSummaryTable() {
    // 하위 지역 선택 전
    if (selectedDistrict == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '오른쪽에서 지역을 선택하면 누적 관측 표가 보여요.',
          style: TextStyle(
              fontFamily: 'Paperlogy',
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: Colors.black87),
        ),
      );
    }

    if (_loadingSummary) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ));
    }

    if (_summaryError != null) {
      return Text(
        _summaryError!,
        style: TextStyle(
            fontFamily: 'Paperlogy',
            fontWeight: FontWeight.w400,
            fontSize: 15,
            color: Colors.redAccent),
      );
    }

    if (_summary.isEmpty) {
      return const SizedBox.shrink(); // 공백
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: TextStyle(
            fontFamily: 'Paperlogy',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black87,
          ),
          dataTextStyle: TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 14,
            color: Colors.black87,
          ),
          columns: const [
            DataColumn(label: Text('종(학술명)')),
            DataColumn(label: Text('누적 관측 횟수'), numeric: true),
          ],
          rows: _summary.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(e.species)),
                DataCell(Text('${e.count}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

}
