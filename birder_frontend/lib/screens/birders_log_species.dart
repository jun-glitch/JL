import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BirdersLogSpecies extends StatefulWidget {
  const BirdersLogSpecies({super.key});

  @override
  State<BirdersLogSpecies> createState() => _BirdersLogSpeciesState();
}

class _BirdersLogSpeciesState extends State<BirdersLogSpecies> {

  @override
  Widget build(BuildContext context) {

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
              style: GoogleFonts.jua(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),

      body: Column(

      ),
    );
  }
}
