import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/contact_model.dart';
import 'cloudinary_service.dart';
import 'user_service.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Send a text message between two users
  Future<void> sendTextMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      print('[DEBUG] MessageService: Sending text message...');
      print('[DEBUG] Sender: $senderId, Receiver: $receiverId');
      print('[DEBUG] Content: $content');

      final message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: 'text',
        timestamp: Timestamp.now(),
        isRead: false,
      );

      print('[DEBUG] MessageService: Adding text message to Firestore...');
      print('[DEBUG] Message data: ${message.toMap()}');

      // Add message to messages collection
      final docRef =
          await _firestore.collection('messages').add(message.toMap());
      print('[DEBUG] MessageService: Text message added with ID: ${docRef.id}');

      // Update both users' chat lists
      await _updateChatLists(senderId, receiverId, content, message.timestamp);

      print('[DEBUG] MessageService: Text message sent successfully');
    } catch (e) {
      print('[DEBUG] MessageService: Error sending text message: $e');
      print('[DEBUG] MessageService: Stack trace: ${StackTrace.current}');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send an image message between two users
  Future<void> sendImageMessage({
    required String senderId,
    required String receiverId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      print('[DEBUG] MessageService: Starting image upload...');
      print('[DEBUG] Image file path: ${imageFile.path}');
      print('[DEBUG] Image file exists: ${await imageFile.exists()}');

      // Upload image to Cloudinary in chat_images folder
      final imageUrl = await _cloudinaryService.uploadImage(imageFile,
          folder: 'xori_chat_images');

      print('[DEBUG] MessageService: Image upload result: $imageUrl');

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception(
            'Failed to upload image to Cloudinary - got null/empty URL');
      }

      final message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        content: caption ?? 'Image',
        type: 'image',
        timestamp: Timestamp.now(),
        isRead: false,
        mediaUrl: imageUrl,
      );

      print('[DEBUG] MessageService: Adding message to Firestore...');
      print('[DEBUG] Message data: ${message.toMap()}');

      // Add message to messages collection
      final docRef =
          await _firestore.collection('messages').add(message.toMap());
      print('[DEBUG] MessageService: Message added with ID: ${docRef.id}');

      // Update both users' chat lists
      await _updateChatLists(
          senderId, receiverId, '📷 Photo', message.timestamp);

      print('[DEBUG] MessageService: Image message sent successfully');
    } catch (e) {
      print('[DEBUG] MessageService: Error sending image message: $e');
      print('[DEBUG] MessageService: Stack trace: ${StackTrace.current}');
      throw Exception('Failed to send image: $e');
    }
  }

  /// Get messages stream between two users
  Stream<List<MessageModel>> getMessagesStream(
      String senderId, String receiverId) {
    try {
      // Create a composite query by fetching all messages and filtering client-side
      // This is necessary because Firestore doesn't support complex OR queries easily
      return _firestore
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        final allMessages = snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList();

        // Filter messages between the two users
        return allMessages
            .where((message) =>
                (message.senderId == senderId &&
                    message.receiverId == receiverId) ||
                (message.senderId == receiverId &&
                    message.receiverId == senderId))
            .toList();
      });
    } catch (e) {
      print('[DEBUG] MessageService: Error getting messages stream: $e');
      return Stream.value([]);
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    try {
      final unreadMessages = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: senderId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      print('[DEBUG] MessageService: Messages marked as read');
    } catch (e) {
      print('[DEBUG] MessageService: Error marking messages as read: $e');
    }
  }

  /// Update chat lists for both users
  Future<void> _updateChatLists(String senderId, String receiverId,
      String lastMessage, Timestamp timestamp) async {
    try {
      // Get user data for both users
      final senderData = await _firestoreService.getUser(senderId);
      final receiverData = await _firestoreService.getUser(receiverId);

      if (senderData == null || receiverData == null) {
        print('[DEBUG] MessageService: User data not found');
        return;
      }

      // Create contact models
      final senderContact = ContactModel(
        id: senderId,
        name: senderData.username,
        phoneNumber: '', // Phone number not available in UserModel
        email: senderData.email,
        profileImageUrl: senderData.profileImageUrl,
        createdAt: timestamp,
      );

      final receiverContact = ContactModel(
        id: receiverId,
        name: receiverData.username,
        phoneNumber: '', // Phone number not available in UserModel
        email: receiverData.email,
        profileImageUrl: receiverData.profileImageUrl,
        createdAt: timestamp,
      );

      // Add sender to receiver's chat list
      await _firestoreService.addContactToChatList(receiverId, senderContact);

      // Add receiver to sender's chat list
      await _firestoreService.addContactToChatList(senderId, receiverContact);

      // Update last message info in chat lists
      await _updateLastMessage(senderId, receiverId, lastMessage, timestamp);
      await _updateLastMessage(receiverId, senderId, lastMessage, timestamp);
    } catch (e) {
      print('[DEBUG] MessageService: Error updating chat lists: $e');
    }
  }

  /// Update last message in chat list
  Future<void> _updateLastMessage(String userId, String contactId,
      String lastMessage, Timestamp timestamp) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_list')
          .doc(contactId)
          .update({
        'lastMessage': lastMessage,
        'lastMessageTime': timestamp,
      });
    } catch (e) {
      print('[DEBUG] MessageService: Error updating last message: $e');
    }
  }

  /// Get chat list stream for a user
  Stream<List<ContactModel>> getChatListStream(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_list')
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ContactModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print('[DEBUG] MessageService: Error getting chat list stream: $e');
      return Stream.value([]);
    }
  }
}
