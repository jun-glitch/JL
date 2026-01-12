import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:const Color(0xFF7499D0),
        ), // 여기 바꾸면 Stepper 색도 같이 바뀜
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
