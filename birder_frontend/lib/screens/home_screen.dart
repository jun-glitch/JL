import 'dart:io';

import 'package:birder_frontend/models/api_client.dart';
import 'package:birder_frontend/screens/birders_log_main.dart';
import 'package:birder_frontend/screens/log_in.dart';
import 'package:birder_frontend/screens/member_info_pages.dart';
import 'package:birder_frontend/screens/my_log.dart';
import 'package:birder_frontend/screens/search_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart'  as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'saved_image_page.dart' as pages;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';


// 임시 이미지 파일
Future<File> _assetToTempFile(String assetPath, String fileName) async {
  final ByteData bd = await rootBundle.load(assetPath);
  final Uint8List bytes = bd.buffer.asUint8List();

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  return file.writeAsBytes(bytes, flush: true);
}

Future<List<File>> _buildMockPhotos() async {
  final f1 = await _assetToTempFile('assets/images/bird_photo1.webp', 'bird_photo1.webp');

  return [f1]; // 1장만이면 [f1]
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  bool _isNewSearchExpanded = false; // 새 검색 버튼 확장 여부

  void _toggleNewSearch() {
    setState(() {
      _isNewSearchExpanded = !_isNewSearchExpanded;
    });
  }

  final ImagePicker _picker = ImagePicker();

  // 위치 정보
  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showInfoPopup('위치 서비스가 꺼져있어요.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      _showInfoPopup('위치 권한이 필요합니다.');
      return null;
    }
    if (permission == LocationPermission.deniedForever) {
      _showInfoPopup('설정에서 위치 권한을 허용해 주세요.');
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }


  // 카메라 열고 사진 로컬 저장
  Future<void> _openCameraAndUpload() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    try {
      final file = File(photo.path);
      final pos = await _getCurrentPosition();
      final result = await _uploadBirdPhoto(
        file,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      final photoNum = result['photo_num']?.toString() ?? '';
      final candidates = (result['candidates'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _showInfoPopup(
        photoNum.isEmpty ? '업로드가 완료되었습니다.' : '업로드가 완료되었습니다.\nphoto_num: $photoNum',
        onConfirm: () {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IdentifyOverlayPage(
                  photos: [file],
                  initialCandidates: candidates,),
            ),
          );
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (data is Map && data['detail'] != null)
          ? data['detail'].toString()
          : '업로드에 실패했습니다.';
      _showInfoPopup(msg);
    } catch (e) {
      _showInfoPopup('업로드에 실패했습니다.\n$e');
    }
  }

  // 갤러리에서 저장 + 서버 업로드
  Future<void> _pickFromGalleryAndSave() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final file = File(picked.path);
      final pos = await _getCurrentPosition();
      final result = await _uploadBirdPhoto(
        file,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );


      final photoNum = result['photo_num']?.toString();
      final candidates = (result['candidates'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _showInfoPopup('업로드가 완료되었습니다.\nphoto_num: $photoNum',
        onConfirm: () {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IdentifyOverlayPage(
                  photos: [file],
                  initialCandidates: candidates,
              ),
            ),
          );
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (data is Map && data['detail'] != null)
            ? data['detail'].toString()
            : '업로드에 실패했습니다.';

      _showInfoPopup(msg);
    } catch (e) {
      _showInfoPopup('업로드에 실패했습니다.\n$e');
    }
  }
  void _showInfoPopup(String msg, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _UploadResultDialog(
          message: msg,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            onConfirm?.call();
          }),
    );
  }


  // 사진 업로드 연결
  Future<Map<String, dynamic>> _uploadBirdPhoto(
      File file, {
        double? latitude,
        double? longitude,
  }) async {
    final dio = ApiClient().dio;

    // 전송 객체
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        file.path,
        filename: p.basename(file.path),
      ),
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    });


    final res = await dio.post(
      '/api/birds/test/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }
    return {'detail': 'unexpected response'};
  }

  // 로그인 확인
  Future<bool> _ensureLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) return true;
    if (!mounted) return false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _LoginRequiredDialog(
          message: '로그인이 필요합니다',
          onClose: () => Navigator.of(context).pop(),
          onLogin: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
      ),
    );

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // 버튼 크기 비율 계산
    final double big = screenSize.width * 0.65;
    final double mid = screenSize.width * 0.38;
    final double small = screenSize.width * 0.27;

    const sky = Color(0xFFDCEBFF);

    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
        backgroundColor: sky, // 앱바색
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 'Birder' 로고
          Positioned(
            top: screenSize.height * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Birder',
                style: GoogleFonts.lobster(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // ✅ 임시 버튼 오버레이 (나중에 이 블록만 삭제하면 됨)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, // 상태바 아래
            right: 12,
            child: SizedBox(
              height: 34,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final photos = await _buildMockPhotos();
                  if (!context.mounted) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IdentifyOverlayPage(photos: photos),
                    ),
                  );
                },
                child: const Text(
                  '임시',
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // MY Log
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.25,
            left: screenSize.width * 0.10,
            size: mid,
            backgroundColor: const Color(0xFFB0CEFF),
            text: 'MY Log',
            onTap: () async {
              if (!await _ensureLoggedIn()) return;
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyLogPage())
              );
            },
          ),

          // Birder's Log
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.31,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            backgroundColor: const Color(0xFF98BFFF),
            text: 'Birder\'s \n Log',
            textHeight: 1.17,
            yOffset: 3.5,
            onTap: () async {
              if (!await _ensureLoggedIn()) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BirdersLogMain())
              );
            },
          ),

          // 계정
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.45,
            left: screenSize.width * 0.705,
            size: small,
            backgroundColor: const Color(0xFF7FAFFF),
            text: '계정',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

              if (!context.mounted) return;

              if (!isLoggedIn) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
              else{
                final username = (prefs.getString('username') ?? '').trim();
                final email = (prefs.getString('email') ?? '').trim();
                final name = (prefs.getString('name') ?? '').trim();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MemberInfoPage(),
                  ),
                );
              }
            },
          ),

          // 새 검색 (메인 버튼)
          _buildBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.43,
            left: screenSize.width * 0.04,
            size: big,
            backgroundColor: const Color(0xFFC5DBFF),
            text: '새 검색',
            onTap: _toggleNewSearch,
          ),

          // 새 검색 서브 메뉴 (확장 시)
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.25,
            left: screenSize.width * 0.10,
            size: mid,
            backgroundColor: const Color(0xFFB0CEFF),
            text: '촬영',
            onTap: () async {
              if (!await _ensureLoggedIn()) return;
              await _openCameraAndUpload();
            },
          ),
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.31,
            left: screenSize.width * 0.50,
            size: mid * 0.85,
            backgroundColor: const Color(0xFF98BFFF),
            text: '사진 \n 업로드',
            onTap: () async {
              if (!await _ensureLoggedIn()) return;
              await _pickFromGalleryAndSave();
            },
          ),
          _buildAnimatedBubbleButton(
            screenSize: screenSize,
            top: screenSize.height * 0.45,
            left: screenSize.width * 0.705,
            size: small,
            text: 'cancel',
            onTap: _toggleNewSearch,
            backgroundColor: Colors.grey[350],
            textColor: Colors.black,
          ),
        ],
      ),
    );
  }

  // 정적 버튼
  Widget _buildBubbleButton({
    required Size screenSize,
    required double top,
    required double left,
    required double size,
    required String text,
    required VoidCallback onTap,
    double? textHeight,
    Color? backgroundColor,
    Color textColor = Colors.black,
    double yOffset = 0,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFA1C4FD),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Transform.translate(offset: Offset(0, yOffset),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontWeight: FontWeight.w600,
                fontSize: size * 0.23,
                color: textColor,
                height: textHeight, //
              ),
            ),
            ),
          ),

        ),
      ),
    );
  }

  // 애니메이션 버튼 (서브 메뉴)
  Widget _buildAnimatedBubbleButton({
    required Size screenSize,
    required double top,
    required double left,
    required double size,
    required String text,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color textColor = Colors.black,
  }) {
    final double centerTop = screenSize.height * 0.53 + size / 2;
    final double centerLeft = screenSize.width * 0.07 + size / 2;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      top: _isNewSearchExpanded ? top : centerTop - size / 2,
      left: _isNewSearchExpanded ? left : centerLeft - size / 2,
      width: size,
      height: size,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _isNewSearchExpanded ? 1.0 : 0.0,
        child: AnimatedScale(
          scale: _isNewSearchExpanded ? 1.0 : 0.2,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? const Color(0xFFA1C4FD),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.23,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _LoginRequiredDialog extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  final VoidCallback onLogin;

  const _LoginRequiredDialog({
    required this.message,
    required this.onClose,
    required this.onLogin,
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

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7E8FF),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '닫기',
                        style: TextStyle(
                          fontFamily: 'Paperlogy',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7E8FF),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontFamily: 'Paperlogy',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _UploadResultDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onConfirm;

  const _UploadResultDialog({
    required this.message,
    this.onConfirm,
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
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7E8FF),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontWeight: FontWeight.w800,
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
