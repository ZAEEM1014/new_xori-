import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String id;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String videoUrl;
  final String caption;
  final List<String> likes;
  final int commentCount;
  final Timestamp createdAt;
  final bool isDeleted;

  const Reel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userPhotoUrl,
    required this.videoUrl,
    required this.caption,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory Reel.fromDoc(DocumentSnapshot doc) {
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

    return Reel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      likes: _safeStringList(data['likes']),
      commentCount: _safeInt(data['commentCount']),
      createdAt: _safeTimestamp(data['createdAt']),
      isDeleted: data['isDeleted'] is bool ? data['isDeleted'] : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'videoUrl': videoUrl,
      'caption': caption,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': createdAt,
      'isDeleted': isDeleted,
    };
  }

  Reel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userPhotoUrl,
    String? videoUrl,
    String? caption,
    List<String>? likes,
    int? commentCount,
    Timestamp? createdAt,
    bool? isDeleted,
  }) {
    return Reel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
