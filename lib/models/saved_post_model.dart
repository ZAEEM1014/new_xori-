import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPost {
  final String id;
  final String userId;
  final String postId;
  final DateTime savedAt;

  SavedPost({
    required this.id,
    required this.userId,
    required this.postId,
    required this.savedAt,
  });

  factory SavedPost.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      postId: data['postId'] ?? '',
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'savedAt': Timestamp.fromDate(savedAt),
    };
  }
}
