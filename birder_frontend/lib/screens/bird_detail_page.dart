import 'package:flutter/material.dart';

import 'my_log.dart';

class BirdDetailPage extends StatelessWidget {
  const BirdDetailPage({super.key, required this.bird});

  final Bird bird;

  @override
  Widget build(BuildContext context) {
    // 최소한
    // TODO: DB 연결 후 개발 필요
    return Scaffold(
      appBar: AppBar(title: Text(bird.name)),
      body: Center(
        child: Text('Bird detail for: ${bird.name} (id: ${bird.id})'),
      ),
    );
  }
}
