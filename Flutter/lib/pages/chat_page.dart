import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/guide_provider.dart';
import 'package:recycling_helper/services/api_service.dart';
import 'package:recycling_helper/models/favorite_chat.dart';
import 'package:recycling_helper/providers/favorites_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String imagePath;
  final String label;
  final String rule;
  const ChatPage({
    super.key,
    required this.imagePath,
    required this.label,
    required this.rule,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  bool _loading = false;
  bool _showButtons = true;
  int? imageId;
  bool isFavorited = false;

  @override
  void initState() {
    super.initState();
    _loading = true;
    _loadGuide();
    //_fetchEmbedding();
  }

  Future<void> _loadGuide() async {
    print("✅ ChatPage에서 _loadGuide() 실행됨");

    final guide = ref.read(guideProvider);

    if (guide.imageId != null) {
      imageId = guide.imageId!;
      print('📥 ChatPage에서 받은 이미지 ID (provider 통해): $imageId');
    }

    String updatedSummary = '';
    if (guide.category != null) {
      print('🌐 정책 요청 시작: ${guide.category}');
      final policyResult = await ApiService.queryPolicy(
        label: guide.category!,
        imageId: imageId!,
      );
      updatedSummary = policyResult?['matched_policy'] ?? '정책 정보를 불러오지 못했습니다.';
      final chatId = policyResult?['chat_id']; // ✅ chat_id 받아오기
      print('📩 정책 응답 요약: $updatedSummary');

      ref.read(guideProvider.notifier).updateGuideFromApi({
        ...guide.toJson(),
        'summary': updatedSummary,
        'chat_id': chatId, // ✅ 저장
      });

      if (updatedSummary.isNotEmpty &&
          !guide.messages.contains(updatedSummary)) {
        ref.read(guideProvider.notifier).addMessage(updatedSummary);
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _loadReward() async {
    final guide = ref.read(guideProvider);
    if (guide.chat_id == null) {
      print('❗ chat_id 없음. 보상 정보 요청 불가');
      return;
    }
    String rewardInfo = '';
    try {
      final rewardResult = await ApiService.queryReward(
        label: guide.category ?? widget.label,
        chatId: guide.chat_id!,
      );
      // ✅ 응답 파싱
      if (rewardResult == null) {
        rewardInfo = '보상 정보를 불러오는 중 오류가 발생했습니다.';
      } else if (rewardResult.containsKey('message') &&
          rewardResult['message'] == '해당사항이 없습니다.') {
        rewardInfo = '아직 보상 제도가 없는 항목입니다.';
      } else {
        rewardInfo = rewardResult['matched_reward'] ??
            '보상 정보를 불러오지 못했습니다.';
      }
      print('🎁 보상 안내 응답: $rewardInfo');
      // ✅ guide.messages에 보상 메시지 추가
      if (rewardInfo.isNotEmpty && !guide.messages.contains(rewardInfo)) {
        ref.read(guideProvider.notifier).addMessage(rewardInfo);
      }
    } catch (e) {
      print('❌ 보상 정보 요청 실패: $e');
      rewardInfo = '보상 정보를 불러오는 중 오류가 발생했습니다.';
      ref.read(guideProvider.notifier).addMessage(rewardInfo);
    }
    setState(() {});
  }

  void _toggleFavorite() async {
    final guide = ref.read(guideProvider);
    final chatId = guide.chat_id;
    print('🟡 현재 guide.chatId: $chatId');

    if (chatId == null) {
      // ❗ chatId가 없을 경우 처리
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('chat_id 정보가 없어 즐겨찾기를 저장할 수 없습니다.')),
      );
      return;
    }

    final now = DateTime.now();
    final formatted = '${now.year}년 ${now.month}월 ${now.day}일 ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final messages = guide.messages.map((msg) => Message(
      sender: 'system',
      text: msg,
    )).toList();

    final favorite = FavoriteChat(
      id: 0,
      title: widget.label,
      summary: guide.summary ?? '',
      imagePath: widget.imagePath,
      dateTime: formatted,
      messages: messages,
      imageId: imageId ?? 0,
      chatId: guide.chat_id ?? 0,
    );
    final favoriteProvider = StateNotifierProvider<FavoritesNotifier, List<FavoriteChat>>(
          (ref) => FavoritesNotifier(),
    );
    final exists = ref.read(favoriteProvider).any((c) => c.chatId == favorite.chatId);

    final success = await ApiService.toggleFavorite(
      chatId: chatId,
      isAdding: !exists, // ⭐ exists 여부에 따라 추가/제거 결정
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신에 실패했습니다.')),
      );
      return;
    }

    if (exists) {
      ref.read(favoriteProvider.notifier).remove(favorite);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기에서 제거되었습니다.')),
      );
    } else {
      ref.read(favoriteProvider.notifier).add(favorite);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기에 추가되었습니다.')),
      );
    }

    setState(() => isFavorited = !exists);
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BouncingIcon(),
          const SizedBox(height: 20),
          const Text(
            '쓰레기 감별사가 감별 중...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(guideProvider);
    final seedColor = const Color(0xFF5B8B4B);
    final now = DateTime.now();

    final formattedDate =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day
        .toString().padLeft(2, '0')}';
    final date = DateTime.tryParse(formattedDate);
    final displayDate = date != null
        ? '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일'
        : formattedDate;

    if (_loading) {
      return Scaffold(
        body: _buildLoadingScreen(), // ✅ AppBar 없이 로딩 화면만 표시
      );
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
            if (!isFavorited) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('즐겨찾기에 추가하시겠습니까?'),
                  content: const Text(
                    '지금 나가면 이 분리배출 가이드는 저장되지 않습니다.',
                    style: TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                              (states) => states.contains(MaterialState.pressed)
                              ? Colors.grey[300]
                              : null,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _toggleFavorite();
                      },
                      child: const Text('즐겨찾기 추가하기'),
                    ),
                    TextButton(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                              (states) => states.contains(MaterialState.pressed)
                              ? Colors.grey[300]
                              : null,
                        ),
                      ),
                      onPressed: () {
                        context.go('/main');
                      },
                      child: const Text('나가기'),
                    ),
                  ],
                ),
              );
            } else {
              context.go('/main');
            }
          },
        ),
        title: Text(
          guide.category ?? '분류 없음',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.star : Icons.star_border,
              color: const Color(0xFF5B8B4B),
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingScreen()
          : Stack(
        children: [
          /// ✅ 전체 내용 스크롤 가능
          Positioned.fill(
            top: 0,
            bottom: 100, // 하단 버튼 영역 높이
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      displayDate,
                      style: const TextStyle(color: Color(0xFF5B8B4B)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: const Color(0xFFE9E9E9),
                        child: Image.file(
                          File(widget.imagePath),
                          height: 180,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...guide.messages
                      .map((msg) => msg.replaceAll('end', '').trim())
                      .where((msg) =>
                  msg.isNotEmpty &&
                      !msg.startsWith('[Disposal]') &&
                      msg != 'end')
                      .map((raw) {
                    String content = raw;
                    bool isCategory = false;
                    bool isSubcategory = false;
                    bool isReward = false;

                    if (content.startsWith('[Category]')) {
                      isCategory = true;
                      content = content.replaceFirst('[Category]', '').trim();
                    } else if (content.startsWith('[Subcategory]')) {
                      isSubcategory = true;
                      content = content.replaceFirst('[Subcategory]', '').trim();
                    } else if (content.contains('보상') || content.contains('포인트') || content.contains('리워드')) {
                      // 보상 메시지임을 단순 텍스트 기반으로 추정
                      isReward = true;
                    }

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B8B4B).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          content,
                          style: TextStyle(
                            fontSize: isCategory || isSubcategory || isReward ? 22 : 18,
                            fontWeight: isCategory || isSubcategory || isReward
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
          /// ✅ 하단 고정 버튼 영역
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showButtons) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: _ButtonGrid(
                      seedColor: seedColor,
                      isFavorited: isFavorited,
                      onReward: _loadReward,
                      onReport: () {
                        context.push('/report-error', extra: {
                          'imagePath': widget.imagePath,
                          'imageId': imageId,
                          'label': widget.label,
                          'rule': widget.rule,
                        });
                      },
                    ),
                  ),
                ],

                // ✅ 항상 보이게 만들기: 버튼 토글용
                Container(
                  color: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      _showButtons ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: seedColor,
                    ),
                    onPressed: () {
                      setState(() => _showButtons = !_showButtons);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

        void _showSnack(BuildContext context) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('준비 중인 기능입니다.')),
        );
      }
    }

class _ButtonGrid extends StatelessWidget {
  final VoidCallback?
      onReward,
      onReport;
  final Color seedColor; // 추가
  final bool isFavorited;

  const _ButtonGrid({
    required this.seedColor, // required
    this.onReward,
    this.onReport,
    required this.isFavorited,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _GButton(icon: Icons.card_giftcard, label: '보상 안내', onTap: onReward, seedColor: seedColor),
      _GButton(icon: Icons.bug_report, label: '오류 신고', onTap: onReport, seedColor: seedColor),
    ];

    return Row(children: buttons);
  }
}

class _GButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color seedColor; // 추가

  const _GButton({
    required this.icon,
    required this.label,
    this.onTap,
    required this.seedColor, // required
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: seedColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: seedColor),
            ),
            elevation: 1,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
class _BouncingIcon extends StatefulWidget {
  const _BouncingIcon({Key? key}) : super(key: key);

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -0.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Icon(Icons.recycling, size: 72, color: Color(0xFF5B8B4B)),
    );
  }
}