import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUser {
  final String userId;
  final String username;
  final String userPhotoUrl;
  final Timestamp followedAt;

  const FollowUser({
    required this.userId,
    required this.username,
    required this.userPhotoUrl,
    required this.followedAt,
  });

  factory FollowUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FollowUser(
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      followedAt: _safeTimestamp(data['followedAt']),
    );
  }

  static Timestamp _safeTimestamp(dynamic val) {
    if (val is Timestamp) return val;
    if (val is Map && val.containsKey('_seconds')) {
      return Timestamp(val['_seconds'] ?? 0, val['_nanoseconds'] ?? 0);
    }
    return Timestamp.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'followedAt': followedAt,
    };
  }
}
