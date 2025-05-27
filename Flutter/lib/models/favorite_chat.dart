class Message {
  final String sender; // 'user' 또는 'system'
  final String text;

  Message({required this.sender, required this.text});
}

class FavoriteChat {
  final int id;
  final String title;
  final String summary;
  final String imagePath;
  final String dateTime;// 저장한 시간 문자열
  final List<Message> messages;
  final int imageId;       // 이미지 ID (선택)
  final int chatId;
  final String? label;
  final String? rewardText;
  final bool? rewardChecked;

  FavoriteChat({
    required this.id,
    required this.title,
    required this.summary,
    required this.imagePath,
    required this.dateTime,
    required this.messages,
    required this.imageId,
    required this.chatId,
    this.label,
    this.rewardText,
    this.rewardChecked,
  });
  factory FavoriteChat.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? reward}) {
    String raw = (json['response_text'] as String?)?.trim() ?? '';
    if (raw.endsWith('end')) {
      raw = raw.substring(0, raw.length - 3).trim();
    }
    return FavoriteChat(
      id: json['id'],
      title: '제목 없음',
      summary: json['response_text']?.split('\n').first ?? '',
      imagePath: 'http://158.179.174.13:8000${json['image_url'] ?? ''}',
      dateTime: json['created_at'] ?? '',
      messages: [
        if (raw.isNotEmpty)
          Message(sender: 'system', text: raw),
      ],
      imageId: json['image'] ?? -1,
      chatId: json['chat_id'] ?? json['chat'] ?? -1,
      label: json['label'],
      rewardText: reward?['reward_text'],
      rewardChecked: reward?['checked'],
    );
  }

  factory FavoriteChat.fromListJson(Map<String, dynamic> json) {
    return FavoriteChat(
      id: json['id'],
      title: '제목 없음',
      summary: json['response_text']?.split('\n').first ?? '',
      imagePath: 'http://158.179.174.13:8000${json['image_url'] ?? ''}',
      dateTime: json['created_at'] ?? '',
      messages: [],
      imageId: json['image'] ?? -1,
      chatId: json['chat_id'] ?? json['chat'] ?? -1,
      label: json['label'],
      rewardText: null,
      rewardChecked: null,
    );
  }

}