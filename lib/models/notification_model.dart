import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  comment,
  follow,
  message,
}

class NotificationModel {
  final String id;
  final String userId; // User who receives the notification
  final String senderUserId; // User who triggered the notification
  final String senderUsername;
  final String senderProfileImageUrl;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? postId; // For like/comment notifications
  final String? chatId; // For message notifications
  final bool isFollowBack; // For follow notifications to show "Follow" button

  NotificationModel({
    required this.id,
    required this.userId,
    required this.senderUserId,
    required this.senderUsername,
    required this.senderProfileImageUrl,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.postId,
    this.chatId,
    this.isFollowBack = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      senderUserId: map['senderUserId'] ?? '',
      senderUsername: map['senderUsername'] ?? '',
      senderProfileImageUrl: map['senderProfileImageUrl'] ?? '',
      type: _typeFromString(map['type'] ?? ''),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      postId: map['postId'],
      chatId: map['chatId'],
      isFollowBack: map['isFollowBack'] ?? false,
    );
  }

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'senderUserId': senderUserId,
      'senderUsername': senderUsername,
      'senderProfileImageUrl': senderProfileImageUrl,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'postId': postId,
      'chatId': chatId,
      'isFollowBack': isFollowBack,
    };
  }

  static NotificationType _typeFromString(String typeString) {
    switch (typeString) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.like;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '1 week ago';
    }
  }

  String get iconAsset {
    switch (type) {
      case NotificationType.like:
        return 'assets/icons/heart.svg';
      case NotificationType.comment:
        return 'assets/icons/comment.svg';
      case NotificationType.follow:
        return 'assets/icons/add.svg';
      case NotificationType.message:
        return 'assets/icons/send.svg';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? senderUserId,
    String? senderUsername,
    String? senderProfileImageUrl,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? postId,
    String? chatId,
    bool? isFollowBack,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderUserId: senderUserId ?? this.senderUserId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderProfileImageUrl:
          senderProfileImageUrl ?? this.senderProfileImageUrl,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      postId: postId ?? this.postId,
      chatId: chatId ?? this.chatId,
      isFollowBack: isFollowBack ?? this.isFollowBack,
    );
  }
}
