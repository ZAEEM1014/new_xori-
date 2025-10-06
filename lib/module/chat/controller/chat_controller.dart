import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/message_model.dart';
import '../../../services/message_service.dart';

class ChatController extends GetxController {
  final MessageService _messageService = MessageService();
  final ImagePicker _imagePicker = ImagePicker();

  // Message list observable
  final messages = <MessageModel>[].obs;

  // Current user typing status
  final isTyping = false.obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  // Chat participants
  final contactId = ''.obs;
  final contactName = ''.obs;
  final contactAvatar = ''.obs;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();

    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      contactId.value = args['contactId'] ?? '';
      contactName.value = args['name'] ?? '';
      contactAvatar.value = args['avatar'] ?? '';

      if (contactId.value.isNotEmpty) {
        loadMessages();
      }
    }
  }

  void loadMessages() {
    try {
      if (currentUserId.isEmpty || contactId.value.isEmpty) return;

      isLoading.value = true;

      // Listen to real-time messages
      _messageService.getMessagesStream(currentUserId, contactId.value).listen(
        (messageList) {
          try {
            // Remove temporary/optimistic messages when real messages arrive
            final tempMessages = messages
                .where((msg) =>
                    msg.id.startsWith('temp_') ||
                    msg.id.startsWith('temp_img_'))
                .toList();

            // Merge real messages with any remaining temp messages
            final realMessages = messageList
                .where((msg) =>
                    !msg.id.startsWith('temp_') &&
                    !msg.id.startsWith('temp_img_'))
                .toList();

            // Combine and sort by timestamp
            final allMessages = [...realMessages, ...tempMessages];
            allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

            messages.value = allMessages;
            isLoading.value = false;

            // Mark messages as read
            _messageService.markMessagesAsRead(currentUserId, contactId.value);
          } catch (e) {
            print('[DEBUG] ChatController: Error updating messages: $e');
            isLoading.value = false;
          }
        },
        onError: (error) {
          print('[DEBUG] ChatController: Error in messages stream: $error');
          isLoading.value = false;
        },
      );
    } catch (e) {
      print('[DEBUG] ChatController: Error loading messages: $e');
      isLoading.value = false;
    }
  }

  Future<void> sendTextMessage(String content) async {
    try {
      if (content.trim().isEmpty ||
          currentUserId.isEmpty ||
          contactId.value.isEmpty) {
        return;
      }

      isSending.value = true;

      // Create optimistic message for immediate UI update
      final optimisticMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUserId,
        receiverId: contactId.value,
        content: content.trim(),
        type: 'text',
        timestamp: Timestamp.now(),
        isRead: false,
      );

      // Add to local list immediately for optimistic UI
      messages.add(optimisticMessage);

      await _messageService.sendTextMessage(
        senderId: currentUserId,
        receiverId: contactId.value,
        content: content.trim(),
      );

      isSending.value = false;
    } catch (e) {
      print('[DEBUG] ChatController: Error sending text message: $e');

      // Remove optimistic message on failure
      messages.removeWhere((msg) => msg.id.startsWith('temp_'));

      isSending.value = false;
      Get.snackbar(
        'Error',
        'Failed to send message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendImageMessage() async {
    try {
      if (currentUserId.isEmpty || contactId.value.isEmpty) return;

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      isSending.value = true;

      // Create optimistic message for immediate UI update with loading state
      final optimisticMessage = MessageModel(
        id: 'temp_img_${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUserId,
        receiverId: contactId.value,
        content: 'Sending image...',
        type: 'image',
        timestamp: Timestamp.now(),
        isRead: false,
        mediaUrl: image.path, // Temporary local path for preview
      );

      // Add to local list immediately for optimistic UI
      messages.add(optimisticMessage);

      await _messageService.sendImageMessage(
        senderId: currentUserId,
        receiverId: contactId.value,
        imageFile: File(image.path),
      );

      isSending.value = false;
    } catch (e) {
      print('[DEBUG] ChatController: Error sending image message: $e');

      // Remove optimistic message on failure
      messages.removeWhere((msg) => msg.id.startsWith('temp_img_'));

      isSending.value = false;
      Get.snackbar(
        'Error',
        'Failed to send image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void startTyping() {
    isTyping.value = true;
  }

  void stopTyping() {
    isTyping.value = false;
  }

  String getTimeString(DateTime dateTime) {
    try {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  bool isSentMessage(MessageModel message) {
    return message.senderId == currentUserId;
  }
}
