import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final Color mainColor = const Color(0xFF5B8B4B);

class ReportDetailPage extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {

    final Map<String, String> statusLabels = {
      '접수 전': '접수 전',
      '오류확인중': '처리 중',
      '처리 중': '처리 중',
      '처리 완료': '처리 완료',
      // 서버에서 영문으로 넘긴다면 예시
      'pending': '접수 전',
      'checking': '처리 중',
      'in_progress': '처리 중',
      'completed': '처리 완료',
    };

    print('📦 신고 상세 report: $report');

    final String type = report['type'] ?? '오류 종류 없음';
    final String content = report['message'] ?? '';
    final int? imageId = report['image'];
    final String imageUrl = report['image_url'] ?? '';

    final String date = report['date'] ?? '';
    final DateTime parsedDate = DateTime.tryParse(date) ?? DateTime.now();
    final String formattedDate = '${parsedDate.year}년 ${parsedDate.month.toString().padLeft(2, '0')}월 ${parsedDate.day.toString().padLeft(2, '0')}일';

    final String status = report['status'] ?? '접수 전';
    final String? adminMessage = report['adminMessage'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        title: Text(
          type,
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 사용자 신고 내용 말풍선
            Container(
              height: 100, // ✅ 4줄 정도 공간 확보
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mainColor),
              ),
              child: Scrollbar( // ✅ 스크롤바도 표시
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),


            const SizedBox(height: 16),

            /// 이미지
            if (report['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Text('이미지를 불러올 수 없습니다.'),
                ),
              ),
            const SizedBox(height: 12),

            /// 날짜 및 상태 (색상 변경)
            Row(
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 13, color: mainColor),
                ),
                const SizedBox(width: 8),
                Text(
                  '· 현재 상태: $status',
                  style: TextStyle(fontSize: 13, color: mainColor),
                ),
              ],
            ),


            const SizedBox(height: 16),

            /// 관리자 메시지 (이미지 아래로, 테두리 적용)
            if (adminMessage != null && status == '처리 완료') ...[
              Container(
                height: 100, // ✅ 4줄 정도 공간 확보
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mainColor),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Text(
                      '💬 관리자 메시지: $adminMessage',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
