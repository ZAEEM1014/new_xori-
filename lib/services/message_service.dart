import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/contact_model.dart';
import 'cloudinary_service.dart';
import 'firestore_service.dart';

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
      final message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: 'text',
        timestamp: Timestamp.now(),
        isRead: false,
      );

      // Add message to messages collection
      await _firestore.collection('messages').add(message.toMap());
      
      // Update both users' chat lists
      await _updateChatLists(senderId, receiverId, content, message.timestamp);
      
      print('[DEBUG] MessageService: Text message sent successfully');
    } catch (e) {
      print('[DEBUG] MessageService: Error sending text message: $e');
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
      // Upload image to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(imageFile);
      
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

      // Add message to messages collection
      await _firestore.collection('messages').add(message.toMap());
      
      // Update both users' chat lists
      await _updateChatLists(senderId, receiverId, 'Image', message.timestamp);
      
      print('[DEBUG] MessageService: Image message sent successfully');
    } catch (e) {
      print('[DEBUG] MessageService: Error sending image message: $e');
      throw Exception('Failed to send image: $e');
    }
  }

  /// Get messages stream between two users
  Stream<List<MessageModel>> getMessagesStream(String senderId, String receiverId) {
    try {
      return _firestore
          .collection('messages')
          .where('senderId', whereIn: [senderId, receiverId])
          .where('receiverId', whereIn: [senderId, receiverId])
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .where((message) => 
                (message.senderId == senderId && message.receiverId == receiverId) ||
                (message.senderId == receiverId && message.receiverId == senderId))
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
  Future<void> _updateChatLists(String senderId, String receiverId, String lastMessage, Timestamp timestamp) async {
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
  Future<void> _updateLastMessage(String userId, String contactId, String lastMessage, Timestamp timestamp) async {
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
