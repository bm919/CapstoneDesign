import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 예시: 임시 분리배출 요약을 담아두는 Provider
final dummyResultProvider = Provider<String>((_) =>
'플라스틱 컵입니다.\n뚜껑·빨대는 일반 플라스틱, 컵은 투명 플라스틱으로 분리 배출하세요.');
