import 'dart:io';
import 'package:flutter/material.dart';

class SavedImagePage extends StatelessWidget {
  final String imagePath;
  const SavedImagePage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    return Scaffold(
      appBar: AppBar(title: const Text('촬영 결과')),
      body: Center(
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.contain)
            : const Text('이미지를 찾을 수 없습니다.'),
      ),
    );
  }
}
