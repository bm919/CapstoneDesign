import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recycling_helper/models/favorite_chat.dart';
import 'package:recycling_helper/services/api_service.dart';

class FavoriteDetailPage extends ConsumerStatefulWidget {
  final int favoriteId;
  const FavoriteDetailPage({super.key, required this.favoriteId});

  @override
  ConsumerState<FavoriteDetailPage> createState() => _FavoriteDetailPageState();
}

class _FavoriteDetailPageState extends ConsumerState<FavoriteDetailPage> {
  FavoriteChat? chat;
  bool isFavorited = true;
  final Color seedColor = const Color(0xFF5B8B4B);

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    final result = await ApiService.fetchFavoriteChatDetail(widget.favoriteId);
    if (mounted && result != null) {
      // ✅ 보상 텍스트 가공
      String? reward = result.rewardText?.trim();
      if (reward != null && reward.isNotEmpty) {
        if (reward == '해당사항이 없습니다.') {
          reward = '아직 보상 제도가 없는 항목입니다.';
        }
        result.messages.add(
          Message(sender: 'system', text: reward),
        );
      }
      print('🧪 받아온 chatId: ${result.chatId}');
      setState(() => chat = result);
    }
  }

  Future<void> _confirmUnfavoriteAndExit() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('즐겨찾기에서 삭제하시겠습니까?'),
        content: const Text('이 대화는 즐겨찾기 목록에서 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: seedColor,
            ),
            child: const Text('삭제하기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      print('🗑️ 즐겨찾기 삭제 시도: chatId = ${chat!.chatId}');
      final success = await ApiService.toggleFavorite(
          chatId: chat!.chatId,
          isAdding: false,
          favoriteId: chat!.id,
      );
      if (success && mounted) {
        Navigator.pop(context, true); // ✅ true 값을 반환하며 pop
      }
    }
  }

  Widget _buildImageOrPlaceholder() {
    return Image.network(
      chat!.imagePath,
      height: 180,
      width: 160,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 180,
        width: 160,
        color: Colors.grey[300],
        alignment: Alignment.center,
        child: const Text(
          '이미지를\n불러올 수 없습니다',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (chat == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final date = DateTime.tryParse(chat!.dateTime);
    final formattedDate = date != null
        ? '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일'
        : chat!.dateTime;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        title: const Text(
          '대화 내용',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.star : Icons.star_border,
              color: seedColor,
            ),
            onPressed: () async {
              if (isFavorited) {
                await _confirmUnfavoriteAndExit();
              }
              setState(() => isFavorited = false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                formattedDate,
                style: TextStyle(color: seedColor),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: const Color(0xFFE9E9E9),
                  child: _buildImageOrPlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...chat!.messages.map((msg) {
              final isUser = msg.sender == 'user';
              String content = msg.text.trim();

              if (!isUser && (content == 'end' || content.startsWith('[Disposal]'))) {
                return const SizedBox.shrink();
              }

              bool isCategory = false;
              bool isSubcategory = false;
              bool isReward = false;

              if (!isUser && content.startsWith('[Category]')) {
                isCategory = true;
                content = content.replaceFirst('[Category]', '').trim();
              } else if (!isUser && content.startsWith('[Subcategory]')) {
                isSubcategory = true;
                content = content.replaceFirst('[Subcategory]', '').trim();
              } else if (!isUser &&
                  (content.contains('보상') || content.contains('포인트') || content.contains('리워드'))) {
                isReward = true;
              }

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.grey[300]
                        : const Color(0xFF5B8B4B).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    content,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isUser ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}