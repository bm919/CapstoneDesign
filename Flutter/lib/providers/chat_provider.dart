import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<String>>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<List<String>> {
  ChatNotifier() : super([]);

  void addMessage(String message) {
    state = [...state, message];
  }

  void clearChat() {
    state = [];
  }
}
