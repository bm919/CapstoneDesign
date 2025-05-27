import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recycling_helper/services/api_service.dart';

final Color mainColor = const Color(0xFF5B8B4B);

class ReportListPage extends ConsumerWidget {
  const ReportListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        title: const Text('신고 목록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ApiService.fetchUserFeedbackList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('아직 신고한 내역이 없습니다.'));
            }

            final reports = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final report = reports[index];
                return ListTile(
                  title: Text(report['type'] ?? ''),
                  subtitle: Text(
                    '${_formatDate(report['date'])} · ${report['status'] ?? ''}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  leading: Icon(Icons.chat, color: mainColor), // ✅ 기존 아이콘 유지
                  onTap: () {
                    context.push('/report-detail', extra: report);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    return '${dt.year}년 ${dt.month.toString().padLeft(2, '0')}월 ${dt.day.toString().padLeft(2, '0')}일 '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
