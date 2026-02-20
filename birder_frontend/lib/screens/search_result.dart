import 'dart:io';
import 'package:birder_frontend/screens/my_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// TODO: DB/서버에서 내려줄 후보 새 데이터 모델로 교체
class BirdCandidate {
  final String nameKo;
  final String nameSci;
  final String description;
  final String imageUrl; // 데모용 (추후 DB/서버 이미지로 변경)

  BirdCandidate({
    required this.nameKo,
    required this.nameSci,
    required this.description,
    required this.imageUrl,
  });
}

class IdentifyOverlayPage extends StatefulWidget {
  /// 카메라/갤러리에서 선택한 사진 1~2장
  final List<File> photos;
  final List<Map<String, dynamic>>? initialCandidates;

  const IdentifyOverlayPage({super.key, required this.photos, this.initialCandidates});

  @override
  State<IdentifyOverlayPage> createState() => _IdentifyOverlayPageState();
}

class _IdentifyOverlayPageState extends State<IdentifyOverlayPage> {
  // 사진 PageView
  final PageController _photoPc = PageController();
  int _photoIndex = 0;

  // 후보 새 PageView
  final PageController _candPc = PageController(viewportFraction: 1.0);
  int _candIndex = 0;

  List<BirdCandidate> _candidates = [];
  bool _loading = true;
  String? _errorText;

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',
      connectTimeout: const Duration(seconds: 80),
      receiveTimeout: const Duration(seconds: 80),
    ),
  );

  @override
  void initState() {
    super.initState();

    final init = widget.initialCandidates;
    if (init != null && init.isNotEmpty) {
      setState(() {
        _loading = false;
        _errorText = null;
        _candIndex = 0;
        _candidates = init.map((c) => BirdCandidate(
          nameKo: (c['common_name_ko'] ?? '').toString(),
          nameSci: (c['scientific_name'] ?? '').toString(),
          description: (c['short_description'] ?? '').toString(),
          imageUrl: '',
        )).toList();
      });
    } else {
      _requestIdentify(); // 기존 로직
    }

  }

  Future<void> _requestIdentify() async {
    try {
      setState(() {
        _loading = true;
        _errorText = null;
        _candidates = [];
        _candIndex = 0;
      });

      final file = widget.photos.first;

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: file.path
              .split('/')
              .last,
        ),
      });

      final res = await _dio.post(
        '/api/birds/identify/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = (res.data is Map) ? Map<String, dynamic>.from(res.data) : <
          String,
          dynamic>{};
      final list = (data['candidates'] as List?) ?? [];


      final candidates = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map((c) =>
          BirdCandidate(
            nameKo: (c['common_name_ko'] ?? '').toString(),
            nameSci: (c['scientific_name'] ?? '').toString(),
            description: (c['short_description'] ?? '').toString(),
            imageUrl: '', // 후보 이미지 url
          ))
          .toList();

      if (!mounted) return;
      setState(() {
        _candidates = candidates;
        _loading = false;
      });
    } on DioException catch (e) {
      debugPrint('identify 실패: ${e.response?.statusCode} ${e.response?.data}');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = '새 식별에 실패했어요. 빈 후보로 표시합니다.';
        _candidates = [];
      });
    } catch (e) {
      debugPrint('identify 예외: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = '새 식별 중 오류가 발생했어요.';
        _candidates = [];
      });
    }
  }

  @override
  void dispose() {
    _photoPc.dispose();
    _candPc.dispose();
    super.dispose();
  }

  Future<void> _onYes() async {
    final picked = _candidates[_candIndex];

    try {
      await _dio.post(
        '/api/birds/confirm',
        data: {
          'scientific_name': picked.nameSci
        },
      );

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _InfoDialog(
            message: "도감에 추가되었습니다",
            confirmText: "확인",
            onConfirm: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MyLogPage()), // 도감 화면
                    (route) => false,
              );
            },
          ),
    );
    } on DioException catch (e) {
      debugPrint('confirm 실패: ${e.response?.statusCode} ${e.response?.data}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('도감 추가에 실패했어요.')),
      );
    }
  }

  Future<void> _onNo() async {
    // TODO: 재촬영 유도 / 다른 분류 플로우로 이동
    // Navigator.push(... 정확도 안내 페이지);

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InfoDialog(
        message: "좀 더 정확한 사진으로\n다시 시도해주세요\n(ㅜㅜ)",
        confirmText: "확인",
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final hasMulti = photos.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1) 배경 (선택한 사진)
          Positioned.fill(
            child: PageView.builder(
              controller: _photoPc,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _photoIndex = i),
              itemBuilder: (_, i) {
                return Image.file(
                  photos[i],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),

          // 배경 어둡게
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
          ),


          // 2) 하단 카드 (후보 새)
          Positioned.fill(
            child: Column(
              children: [
                const Spacer(),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: _loading
                          ? const Center(
                        child: CircularProgressIndicator(),
                      )
                          : (_candidates.isEmpty
                          ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _errorText ?? '후보를 불러오지 못했어요.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                          : _BottomCandidateCard(
                        candidates: _candidates,
                        pageController: _candPc,
                        onChanged: (i) => setState(() => _candIndex = i),
                        onYes: _onYes,
                        onNo: _onNo,
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// 하단 라운드 화면
class _BottomCandidateCard extends StatelessWidget {
  final List<BirdCandidate> candidates;
  final PageController pageController;
  final ValueChanged<int> onChanged;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _BottomCandidateCard({
    required this.candidates,
    required this.pageController,
    required this.onChanged,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: candidates.length,
                    onPageChanged: onChanged,
                    itemBuilder: (_, i) {
                      final c = candidates[i];
                      return Column(
                        children: [
                          // 사진(정사각)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: (c.imageUrl.isNotEmpty)
                                  ? Image.network(
                                c.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.image_not_supported)),
                              )
                                  : Container(
                                color: Colors.white,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 이름
                          Text(
                            "${c.nameKo}(${c.nameSci})",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 설명 (남는 공간 스크롤)
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                c.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Paperlogy',
                                  fontSize: 13,
                                  height: 1.35,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "이 새가",
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _PillButton(text: "맞아요", onTap: onYes)),
                    const SizedBox(width: 10),
                    Expanded(child: _PillButton(text: "이 중에 없어요", onTap: onNo)),
                  ],
                ),
              ],
            ),
          ),

          // 좌/우 화살표 (그대로)
          Align(
            alignment: Alignment.centerLeft,
            child: _ArrowButton(
              icon: Icons.chevron_left,
              onTap: () {
                pageController.previousPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _ArrowButton(
              icon: Icons.chevron_right,
              onTap: () {
                pageController.nextPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Icon(icon, size: 34, color: Colors.black54),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD7E8FF),
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// 도감에 추가되었습니다, 다시 시도 팝업
class _InfoDialog extends StatelessWidget {
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;

  const _InfoDialog({
    required this.message,
    required this.confirmText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Paperlogy',
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7E8FF),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(
                      fontFamily: 'Paperlogy',
                      fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
