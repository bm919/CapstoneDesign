import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recycling_helper/services/api_service.dart';
import 'package:image/image.dart' as img;
import 'package:recycling_helper/providers/guide_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class GalleryPage extends ConsumerWidget {
  final String imagePath;
  const GalleryPage({Key? key, required this.imagePath}) : super(key: key);

  PopupMenuItem<String> _buildMenuItem(BuildContext context, String label) {
    return PopupMenuItem<String>(
      value: label,
      child: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          final current = snapshot.data?.getString('image_quality') ?? '일반 화질';
          final isSelected = current == label;

          return Container(
            color: isSelected ? Colors.grey[200] : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF5B8B4B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 저장 버튼을 누르면 화질 선택
    Future<void> _onSave() async {
      final prefs = await SharedPreferences.getInstance();
      final selectedQuality = prefs.getString('image_quality') ?? '일반 화질';

      final quality = {
        '저화질': 30,
        '일반 화질': 50,
        '고화질': 75,
      }[selectedQuality]!;

      final originalBytes = await File(imagePath).readAsBytes();
      final decodedImage = img.decodeImage(originalBytes);

      if (decodedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 디코딩에 실패했습니다.')),
        );
        return;
      }

      final compressedBytes = img.encodeJpg(decodedImage, quality: quality);
      final tempDir = Directory.systemTemp;
      final compressedFile = await File('${tempDir.path}/compressed.jpg').writeAsBytes(compressedBytes);

      print("-----------서버 이미지 업로드 시작-------");
      final result = await ApiService.uploadImage(ref, compressedFile.path); // ✅ 변수 이름 바꿈
      print("-----------서버 이미지 업로드 결과 : $result-------");

      if (result != null) {
        ref.read(guideProvider.notifier).updateGuideFromApi({
          ...result,
          'summary': '요약 불러오는 중...',
          'category': result['label'] ?? '미분류',
        });

        context.push('/chat', extra: {
          'imagePath': imagePath,
          'label': result['label'],
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 업로드에 실패했습니다.')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.pushReplacement('/camera');
          },
        ),
        title: const Text(
          '미리보기 & 저장',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            color: Colors.white,
            onSelected: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('image_quality', value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$value로 저장 화질이 설정되었습니다.')),
              );
            },
            itemBuilder: (context) => [
              _buildMenuItem(context, '저화질'),
              _buildMenuItem(context, '일반 화질'),
              _buildMenuItem(context, '고화질'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.file(File(imagePath)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.pushReplacement('/camera'); // ← 교체
                    },
                    child: const Text('다시 찍기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSave,
                    child: const Text('저장하기'),
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