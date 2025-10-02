import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String caption;
  final List<String> hashtags;
  final List<String> mediaUrls;
  final String mediaType; // "image" or "video"
  final Timestamp createdAt;
  final List<String> likes;
  final int commentCount;
  final String? location;
  final List<String>? mentions;
  final bool isDeleted;
  final List<String> taggedUsers;

  const Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userPhotoUrl,
    required this.caption,
    required this.hashtags,
    required this.mediaUrls,
    required this.mediaType,
    required this.createdAt,
    required this.likes,
    required this.commentCount,
    this.location,
    this.mentions,
    this.isDeleted = false,
    this.taggedUsers = const [],
  });

  factory Post.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    List<String> _safeStringList(dynamic val) {
      if (val is List) {
        return val.whereType<String>().toList();
      }
      return [];
    }

    Timestamp _safeTimestamp(dynamic val) {
      if (val is Timestamp) return val;
      if (val is Map && val.containsKey('_seconds')) {
        return Timestamp(val['_seconds'] ?? 0, val['_nanoseconds'] ?? 0);
      }
      return Timestamp.now();
    }

    int _safeInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      return 0;
    }

    return Post(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      hashtags: _safeStringList(data['hashtags']),
      mediaUrls: _safeStringList(data['mediaUrls']),
      mediaType: data['mediaType'] as String? ?? '',
      createdAt: _safeTimestamp(data['createdAt']),
      likes: _safeStringList(data['likes']),
      commentCount: _safeInt(data['commentCount']),
      location: data['location'] as String?,
      mentions:
          data['mentions'] != null ? _safeStringList(data['mentions']) : null,
      isDeleted: data['isDeleted'] is bool ? data['isDeleted'] : false,
      taggedUsers: _safeStringList(data['taggedUsers']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'caption': caption,
      'hashtags': hashtags,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType,
      'createdAt': createdAt,
      'likes': likes,
      'commentCount': commentCount,
      if (location != null) 'location': location,
      if (mentions != null) 'mentions': mentions,
      'isDeleted': isDeleted,
      'taggedUsers': taggedUsers,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? userPhotoUrl,
    String? caption,
    List<String>? hashtags,
    List<String>? mediaUrls,
    String? mediaType,
    Timestamp? createdAt,
    List<String>? likes,
    int? commentCount,
    String? location,
    List<String>? mentions,
    bool? isDeleted,
    List<String>? taggedUsers,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      location: location ?? this.location,
      mentions: mentions ?? this.mentions,
      isDeleted: isDeleted ?? this.isDeleted,
      taggedUsers: taggedUsers ?? this.taggedUsers,
    );
  }
}
