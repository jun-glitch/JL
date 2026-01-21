import 'package:flutter/material.dart';

// my_log.dart에 Bird 클래스가 정의되어 있다고 가정
import '../screens/my_log.dart';
class BirdTile extends StatelessWidget {
  const BirdTile({
    super.key,
    required this.bird,
    required this.onOpenDetail,
  });

  final Bird bird;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    // 아직 이미지 연결 X
    final canOpen = bird.discovered; // 필요 없으면 false로

    return Column(
      children: [
        InkWell(
          onTap: canOpen ? onOpenDetail : null, // 발견된 경우만 이동
          child: AspectRatio(
            aspectRatio: 1, // 정사각형
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.grey.shade300, // 회색 상자
                alignment: Alignment.center,
                child: canOpen
                    ? const Icon(Icons.check_circle_outline) // 발견 표시(선택)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: canOpen ? onOpenDetail : null,
          child: Text(
            bird.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: canOpen ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
