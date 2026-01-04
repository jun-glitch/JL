import 'package:flutter/material.dart';
import 'package:birder_frontend/screens/home_screen.dart';

void main() {
  runApp(const BirderApp());
}

class BirderApp extends StatelessWidget {
  const BirderApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}