import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recycling_helper/services/api_service.dart';

class GuideResult {
  final String summary;
  final String detail;
  final String reward;   // 보상·물품 교환 규정 (없으면 빈 문자열)
  final String category;

  GuideResult({
    required this.summary,
    required this.detail,
    required this.reward,
    required this.category,
  });
}

class GuideService {
  /// 실제 API 호출로 벡터 기반 가이드 반환
  Future<GuideResult> queryGuide(String imagePath) async {
    final vectorList = await ApiService.getVectors(); // 🔁 GET /api/vectors/

    if (vectorList.isEmpty) {
      return GuideResult(
        summary: '유사 벡터 정보를 불러오지 못했습니다.',
        detail: '서버에서 벡터 정보를 가져오는 데 실패했습니다.',
        reward: '',
        category: '분류 실패',
      );
    }

    // 가장 최근 항목 기준으로 정렬 후 가장 마지막 벡터 선택
    vectorList.sort((a, b) => b['created_at'].compareTo(a['created_at']));
    final latest = vectorList.first;

    final metadata = latest['metadata'] ?? {};

    final category = metadata['category'] ?? '알 수 없음';
    final model    = metadata['model'] ?? 'unknown';
    final source   = metadata['source'] ?? 'unknown';

    return GuideResult(
      summary: '이 이미지는 [$category]로 분류되었습니다.',
      detail: '모델: $model\n출처: $source',
      reward: '해당 분류 항목은 현재 보상 규정이 없습니다.',
      category: category,
    );
  }
}


final guideServiceProvider = Provider<GuideService>((_) => GuideService());
