import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/message_model.dart';
import '../../../services/message_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../utils/chat_debug_helper.dart';
import '../../../utils/standalone_cloudinary_uploader.dart';

class ChatController extends GetxController {
  final MessageService _messageService = MessageService();
  final ImagePicker _imagePicker = ImagePicker();

  // Message list observable
  final messages = <MessageModel>[].obs;

  // Current user typing status
  final isTyping = false.obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  // Image selection
  final selectedImage = Rxn<File>();
  final imageCaption = ''.obs;

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
            // Get current temporary messages
            final tempMessages = messages
                .where((msg) =>
                    msg.id.startsWith('temp_') ||
                    msg.id.startsWith('temp_img_'))
                .toList();

            // Get real messages from Firestore
            final realMessages = messageList
                .where((msg) =>
                    !msg.id.startsWith('temp_') &&
                    !msg.id.startsWith('temp_img_'))
                .toList();

            // Remove temp messages that have corresponding real messages
            // (based on content, type, and approximate timestamp)
            final filteredTempMessages = tempMessages.where((tempMsg) {
              return !realMessages.any((realMsg) =>
                  realMsg.senderId == tempMsg.senderId &&
                  realMsg.type == tempMsg.type &&
                  (realMsg.content == tempMsg.content ||
                      (tempMsg.content == 'Sending image...' &&
                          realMsg.type == 'image')) &&
                  (realMsg.timestamp.millisecondsSinceEpoch -
                              tempMsg.timestamp.millisecondsSinceEpoch)
                          .abs() <
                      10000); // 10 second tolerance
            }).toList();

            // Combine real messages with remaining temp messages
            final allMessages = [...realMessages, ...filteredTempMessages];
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

  /// Select an image from gallery
  Future<void> selectImage() async {
    try {
      print('[DEBUG] ChatController: Selecting image...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) {
        print('[DEBUG] ChatController: No image selected');
        return;
      }

      print('[DEBUG] ChatController: Image selected: ${image.path}');
      selectedImage.value = File(image.path);
      imageCaption.value = '';
    } catch (e) {
      print('[DEBUG] ChatController: Error selecting image: $e');
      Get.snackbar(
        'Error',
        'Failed to select image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Send the selected image with caption
  Future<void> sendImageMessage({String? caption}) async {
    try {
      if (selectedImage.value == null) {
        print('[DEBUG] ChatController: No image selected');
        return;
      }

      if (currentUserId.isEmpty || contactId.value.isEmpty) {
        print('[DEBUG] ChatController: Missing user IDs, aborting');
        return;
      }

      print('[DEBUG] ChatController: Starting sendImageMessage...');
      print('[DEBUG] Current user ID: $currentUserId');
      print('[DEBUG] Contact ID: ${contactId.value}');

      isSending.value = true;

      // Create optimistic message for immediate UI update
      final optimisticMessage = MessageModel(
        id: 'temp_img_${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUserId,
        receiverId: contactId.value,
        content: caption ?? imageCaption.value,
        type: 'image',
        timestamp: Timestamp.now(),
        isRead: false,
        mediaUrl: selectedImage.value!.path, // Temporary local path for preview
      );

      print('[DEBUG] ChatController: Adding optimistic message');
      // Add to local list immediately for optimistic UI
      messages.add(optimisticMessage);

      print(
          '[DEBUG] ChatController: Calling MessageService.sendImageMessage...');
      await _messageService.sendImageMessage(
        senderId: currentUserId,
        receiverId: contactId.value,
        imageFile: selectedImage.value!,
        caption: caption ?? imageCaption.value,
      );

      print('[DEBUG] ChatController: Image message sent successfully');

      // Clear selected image after sending
      selectedImage.value = null;
      imageCaption.value = '';

      isSending.value = false;
    } catch (e) {
      print('[DEBUG] ChatController: Error sending image message: $e');
      print('[DEBUG] ChatController: Stack trace: ${StackTrace.current}');

      // Remove optimistic message on failure
      messages.removeWhere((msg) => msg.id.startsWith('temp_img_'));

      isSending.value = false;
      Get.snackbar(
        'Error',
        'Failed to send image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Clear selected image
  void clearSelectedImage() {
    selectedImage.value = null;
    imageCaption.value = '';
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

  /// Debug method to test all chat functionality
  Future<void> runDebugTests() async {
    print('[DEBUG] ChatController: Running debug tests...');
    await ChatDebugHelper.runAllTests(contactId.value, null);
  }

  /// Test Cloudinary upload directly
  Future<void> testCloudinaryDirectly() async {
    try {
      print('[DEBUG] Testing Cloudinary upload directly...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) {
        print('[DEBUG] No image selected');
        return;
      }

      print('[DEBUG] Image selected: ${image.path}');
      final imageFile = File(image.path);

      // Get cloudinary service
      final cloudinaryService = Get.find<CloudinaryService>();

      final url = await cloudinaryService.uploadImage(imageFile,
          folder: 'test_direct_upload');

      if (url != null) {
        print('[DEBUG] SUCCESS: Image uploaded to: $url');
        Get.snackbar(
          'Success',
          'Image uploaded successfully!\n$url',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 10),
        );
      } else {
        print('[DEBUG] FAILED: Upload returned null');
        Get.snackbar(
          'Failed',
          'Upload returned null - check logs',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('[DEBUG] Exception in testCloudinaryDirectly: $e');
      Get.snackbar(
        'Error',
        'Exception: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Test standalone Cloudinary upload (bypassing service)
  Future<void> testStandaloneCloudinary() async {
    try {
      print('[DEBUG] Testing standalone Cloudinary upload...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) {
        print('[DEBUG] No image selected');
        return;
      }

      print('[DEBUG] Image selected: ${image.path}');
      final imageFile = File(image.path);

      final url =
          await StandaloneCloudinaryUploader.uploadImageDirect(imageFile);

      if (url != null) {
        print('[DEBUG] STANDALONE SUCCESS: Image uploaded to: $url');
        Get.snackbar(
          'Standalone Success',
          'Image uploaded successfully!\n$url',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 10),
        );
      } else {
        print('[DEBUG] STANDALONE FAILED: Upload returned null');
        Get.snackbar(
          'Standalone Failed',
          'Upload returned null - check logs',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('[DEBUG] Exception in testStandaloneCloudinary: $e');
      Get.snackbar(
        'Standalone Error',
        'Exception: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
