import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:recycling_helper/services/api_service.dart';


final Color mainColor = const Color(0xFF5B8B4B);

class ReportErrorPage extends StatefulWidget {
  final String imagePath;
  final int? imageId;
  final String label;
  final String rule;

  const ReportErrorPage({
    super.key,
    required this.imagePath,
    this.imageId,
    required this.label,
    required this.rule,
  });

  @override
  State<ReportErrorPage> createState() => _ReportErrorPageState();
}

class _ReportErrorPageState extends State<ReportErrorPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> errorTypes = [
    '쓰레기 종류 오분류',
    '잘못된 주소 설정',
    '잘못된 배출방법',
    '실제와 다른 보상 내용',
    '앱 기능 오류',
    '기타 불편사항',
  ];

  String? selectedType;
  bool isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose(); // ✅ 메모리 누수 방지
    super.dispose();
  }

  void _submitReport() async {
    if (selectedType == null || _controller.text.trim().isEmpty) {
      print('❌ 오류 신고 실패: 오류 종류 또는 내용이 비어 있음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류 종류와 내용을 모두 입력해주세요.')),
      );
      return;
    }

    print('📤 오류 신고 전송 시작');
    print('🔸 오류 종류: $selectedType');
    print('🔸 메시지 내용: ${_controller.text.trim()}');
    print('🔸 이미지 ID: ${widget.imageId}');

    setState(() => isSubmitting = true);

    final success = await ApiService.uploadFeedback(
      message: _controller.text.trim(),
      type: selectedType!,
      imageId: widget.imageId,
    );

    setState(() => isSubmitting = false);

    if (success && context.mounted) {
      print('✅ 오류 신고 성공');
      context.pop(); // ✅ 메인메뉴가 아니라 이전 페이지로 복귀
    } else {
      print('❌ 오류 신고 실패');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류 신고 중 문제가 발생했습니다.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        title: const Text('오류 신고'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30), // ✅ 상단 여백
            const Text(
              '어떤 부분에서 미흡했나요?',
              style: TextStyle(
                fontSize: 28, // ✅ 폰트 크기 키움
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: errorTypes.map((type) {
                final isSelected = selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedType = type;
                    });
                  },
                  selectedColor: mainColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? mainColor : Colors.black,
                  ),
                  backgroundColor: const Color(0xFFEDEDED),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: 6, // ✅ 6줄 정도 입력 가능하도록 높이 설정
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '불편 사항을 적어주세요.',
              ),
            ),
            const Spacer(), // ✅ 남은 공간을 차지해서 버튼을 아래로 밀어줌
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitReport,
                child: const Text('오류 신고'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
