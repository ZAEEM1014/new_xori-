import 'package:cloud_firestore/cloud_firestore.dart';

class ReelComment {
  final String id;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String text;
  final DateTime createdAt;

  ReelComment({
    required this.id,
    required this.userId,
    required this.username,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory ReelComment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Missing data for reel comment: ${doc.id}');
    }
    return ReelComment(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
