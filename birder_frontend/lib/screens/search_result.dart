import 'dart:io';
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

  const IdentifyOverlayPage({super.key, required this.photos});

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

  late final List<BirdCandidate> _candidates;

  @override
  void initState() {
    super.initState();

    // TODO: (1) 사진 업로드/추론 요청 -> (2) 후보 리스트를 서버/DB에서 받아오기
    // 지금은 더미 데이터
    _candidates = [
      BirdCandidate(
        nameKo: "세가락도요",
        nameSci: "Calidris alba",
        description:
        "물가의 18~20cm 정도의 작은 도요새이다.\n머리칼은 적갈색이고, 겨울철은 밝은회색이며\n어깨 부분에 조금만 검은 반점이 있다.",
        imageUrl:
        "https://images.unsplash.com/photo-1526336024174-e58f5cdd8e13?auto=format&fit=crop&w=600&q=80",
      ),
      BirdCandidate(
        nameKo: "청다리도요사촌",
        nameSci: "Tringa guttifer",
        description:
        "물가의 30cm 정도의 중형 도요새이다.\n굵은 부리로 지면의 작은생물들을 노리며\n위로 살짝 굽은 부리를 가지고 있다.",
        imageUrl:
        "https://images.unsplash.com/photo-1501706362039-c6e13d85b07f?auto=format&fit=crop&w=600&q=80",
      ),
    ];
  }

  @override
  void dispose() {
    _photoPc.dispose();
    _candPc.dispose();
    super.dispose();
  }

  Future<void> _onYes() async {
    final picked = _candidates[_candIndex];

    // TODO: "도감에 추가" 서버/DB 저장 호출
    // await MyApi.addToCollection(birdId: picked.id, photo: ...);

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InfoDialog(
        message: "도감에 추가되었습니다",
        confirmText: "확인",
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
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
        onConfirm: () => Navigator.of(context).pop(),
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
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.55),
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
                      child: _BottomCandidateCard(
                        candidates: _candidates,
                        pageController: _candPc,
                        onChanged: (i) => setState(() => _candIndex = i),
                        onYes: _onYes,
                        onNo: _onNo,
                      ),
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
                              child: Image.network(
                                c.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white,
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported),
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
                fontWeight: FontWeight.w800,
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
                  style: const TextStyle(fontFamily: 'Paperlogy', fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
