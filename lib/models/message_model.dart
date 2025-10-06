import 'package:cloud_firestore/cloud_firestore.dart';

/// A professional and simple message model for Firestore chat/messages
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String type; // e.g. 'text', 'image', 'video', 'file'
  final Timestamp timestamp;
  final bool isRead;
  final String? replyToMessageId;
  final String? mediaUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.replyToMessageId,
    this.mediaUrl,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
      replyToMessageId: map['replyToMessageId'],
      mediaUrl: map['mediaUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'timestamp': timestamp,
      'isRead': isRead,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };
  }
}
