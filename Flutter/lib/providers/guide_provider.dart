import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/guide_service.dart';
import 'package:recycling_helper/services/api_service.dart';
import 'package:flutter/foundation.dart';
// import 'package:recycling_helper/services/guide_service.dart';

class GuideState {
  final String? summary; // 간단 요약
  final String? reward; // 보상·교환 규정
  final String? category;
  final String? vectorId;
  final String? source;
  final int? imageId;
  final String? label;
  final String? rule;
  final int? chat_id;
  final List<String> messages;

  const GuideState({
    this.summary,
    this.reward,
    this.category,
    this.vectorId,
    this.source,
    this.imageId,
    this.label,
    this.rule,
    this.chat_id,
    this.messages = const [],
  });

  // ✅ JSON 형태로 변환
  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'reward': reward,
      'category': category,
      'vectorId': vectorId,
      'source': source,
      'imageId': imageId,
      'label': label,
      'rule': rule,
      'chat_id': chat_id,
    };
  }

  // ✅ JSON으로부터 객체 생성
  factory GuideState.fromJson(Map<String, dynamic> json) {
    return GuideState(
      summary: json['summary'],
      reward: json['reward'],
      category: json['category'],
      vectorId: json['vectorId'],
      source: json['source'],
      imageId: json['imageId'] ?? json['image_id'],
      label: json['label'],
      rule: json['rule'],
      chat_id: json['chat_id'],
    );
  }

  // ✅ 복사본 생성
  GuideState copyWith({
    String? summary,
    String? reward,
    String? category,
    String? vectorId,
    String? source,
    int? imageId,
    String? label,
    String? rule,
    int? chat_Id,
    List<String>? messages,
  }) {
    return GuideState(
      summary: summary ?? this.summary,
      reward: reward ?? this.reward,
      category: category ?? this.category,
      vectorId: vectorId ?? this.vectorId,
      source: source ?? this.source,
      imageId: imageId ?? this.imageId,
      label: label ?? this.label,
      rule: rule ?? this.rule,
      chat_id: chat_id ?? this.chat_id,
      messages: messages ?? this.messages,
    );
  }
}

class GuideNotifier extends StateNotifier<GuideState> {
  final GuideService _service;

  GuideNotifier(this._service) : super(const GuideState());

  Future<void> fetchGuide(String imagePath) async {
    final result = await _service.queryGuide(imagePath);
    state = GuideState(
      summary: result.summary,
      reward: result.reward,
      category: result.category,
    );
  }

  void updateGuideFromApi(Map<String, dynamic> json) {
    print('📦 서버 응답 json: $json');
    final summaryText = json['summary'] ?? json['matched_policy'] ?? '요약 없음';
    final categoryText = json['category'] ?? '미분류';

    state = GuideState(
      summary: summaryText,
      reward: json['reward'] ?? '',
      category: categoryText,
      imageId: json['imageId'] ?? json['image_id'],
      label: json['label'],
      rule: json['rule'],
      chat_id: json['chat_id'],
      messages: state.messages,
    );
  }

  void updateGuideFromVectorMeta(Map<String, dynamic> meta) {
    final category = meta['category'] ?? '알 수 없음';
    final model = meta['model'] ?? 'unknown';
    final source = meta['source'] ?? 'unknown';

    state = GuideState(
      summary: '이 이미지는 [$category]로 분류되었습니다.',
      reward: '',
      category: category,
      source: source,
      messages: state.messages,
    );
  }

  void addMessage(String message) {
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }
}

final guideProvider = StateNotifierProvider<GuideNotifier, GuideState>((ref) {
  return GuideNotifier(ref.read(guideServiceProvider));
});
