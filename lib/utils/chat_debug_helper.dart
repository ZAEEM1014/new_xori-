import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';
import '../services/message_service.dart';

class ChatDebugHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CloudinaryService _cloudinaryService = CloudinaryService();
  static final MessageService _messageService = MessageService();

  /// Test Firestore write permissions
  static Future<bool> testFirestoreWrite() async {
    try {
      print('[DEBUG] Testing Firestore write permissions...');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[DEBUG] No authenticated user');
        return false;
      }

      // Try to write a test message
      final testMessage = {
        'senderId': user.uid,
        'receiverId': 'test_receiver',
        'content': 'Test message',
        'type': 'text',
        'timestamp': Timestamp.now(),
        'isRead': false,
      };

      final docRef = await _firestore.collection('messages').add(testMessage);
      print('[DEBUG] Test message written successfully with ID: ${docRef.id}');

      // Clean up - delete the test message
      await docRef.delete();
      print('[DEBUG] Test message cleaned up');

      return true;
    } catch (e) {
      print('[DEBUG] Firestore write test failed: $e');
      return false;
    }
  }

  /// Test Cloudinary upload
  static Future<bool> testCloudinaryUpload(File imageFile) async {
    try {
      print('[DEBUG] Testing Cloudinary upload...');

      final url = await _cloudinaryService.uploadImage(imageFile,
          folder: 'xori_test_upload');

      if (url != null) {
        print('[DEBUG] Cloudinary upload test successful: $url');
        return true;
      } else {
        print('[DEBUG] Cloudinary upload test failed - null URL returned');
        return false;
      }
    } catch (e) {
      print('[DEBUG] Cloudinary upload test failed: $e');
      return false;
    }
  }

  /// Test end-to-end message sending
  static Future<bool> testMessageSending(
      String receiverId, String content) async {
    try {
      print('[DEBUG] Testing end-to-end text message sending...');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[DEBUG] No authenticated user');
        return false;
      }

      await _messageService.sendTextMessage(
        senderId: user.uid,
        receiverId: receiverId,
        content: content,
      );

      print('[DEBUG] End-to-end text message test successful');
      return true;
    } catch (e) {
      print('[DEBUG] End-to-end text message test failed: $e');
      return false;
    }
  }

  /// Test end-to-end image message sending
  static Future<bool> testImageMessageSending(
      String receiverId, File imageFile) async {
    try {
      print('[DEBUG] Testing end-to-end image message sending...');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[DEBUG] No authenticated user');
        return false;
      }

      await _messageService.sendImageMessage(
        senderId: user.uid,
        receiverId: receiverId,
        imageFile: imageFile,
        caption: 'Test image message',
      );

      print('[DEBUG] End-to-end image message test successful');
      return true;
    } catch (e) {
      print('[DEBUG] End-to-end image message test failed: $e');
      return false;
    }
  }

  /// Run all tests
  static Future<void> runAllTests(
      String receiverId, File? testImageFile) async {
    print('[DEBUG] ========== CHAT DEBUG TESTS ==========');

    // Test Firestore permissions
    final firestoreOk = await testFirestoreWrite();
    print('[DEBUG] Firestore write test: ${firestoreOk ? 'PASS' : 'FAIL'}');

    // Test Cloudinary upload if image provided
    if (testImageFile != null) {
      final cloudinaryOk = await testCloudinaryUpload(testImageFile);
      print(
          '[DEBUG] Cloudinary upload test: ${cloudinaryOk ? 'PASS' : 'FAIL'}');
    }

    // Test text message sending
    final textMsgOk =
        await testMessageSending(receiverId, 'Debug test message');
    print('[DEBUG] Text message test: ${textMsgOk ? 'PASS' : 'FAIL'}');

    // Test image message sending if image provided
    if (testImageFile != null) {
      final imageMsgOk =
          await testImageMessageSending(receiverId, testImageFile);
      print('[DEBUG] Image message test: ${imageMsgOk ? 'PASS' : 'FAIL'}');
    }

    print('[DEBUG] ========== DEBUG TESTS COMPLETE ==========');
  }
}
