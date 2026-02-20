import 'package:flutter/material.dart';
import 'package:birder_frontend/models/bird.dart';

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
    final canOpen = bird.discovered; // observed
    final hasImage = (bird.imageUrl != null && bird.imageUrl!.isNotEmpty);

    return Column(
      children: [
        InkWell(
          onTap: canOpen ? onOpenDetail : null,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.grey.shade300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 이미지 표시
                    if (hasImage)
                      Image.network(
                        bird.imageUrl!,
                        fit: BoxFit.cover,
                        // 로딩 중
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        // 에러나면 기본 아이콘
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 28),
                          );
                        },
                      )
                    else
                    // 이미지 없으면 빈 아이콘
                      const Center(
                        child: Icon(Icons.question_mark, size: 28),
                      ),

                    // 발견한 새 체크
                    if (canOpen)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xFF7FAFFF),
                          ),
                        ),
                      ),

                    // 발견 안 한 새 반투명
                    if (!canOpen)
                      Container(
                        color: Colors.white.withOpacity(0.55),
                      ),
                  ],
                ),
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
              fontFamily: 'Paperlogy',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: canOpen ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}