import 'package:get/get.dart';

class ChatController extends GetxController {
  // Message list observable
  final messages = [].obs;

  // Current user typing status
  final isTyping = false.obs;

  // Selected chat/conversation
  final selectedChat = {}.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize chat data
    loadMessages();
  }

  void loadMessages() {
    // TODO: Load messages from API/database
    messages.value = [];
  }

  void sendMessage(String message) {
    if (message.trim().isEmpty) return;

    // TODO: Implement send message logic
    messages.add({
      'text': message,
      'isSent': true,
      'timestamp': DateTime.now(),
    });
  }

  void startTyping() {
    isTyping.value = true;
  }

  void stopTyping() {
    isTyping.value = false;
  }
}
