import 'package:cloud_firestore/cloud_firestore.dart';

class SavedReel {
  final String id;
  final String userId;
  final String reelId;
  final DateTime savedAt;

  SavedReel({
    required this.id,
    required this.userId,
    required this.reelId,
    required this.savedAt,
  });

  factory SavedReel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Missing data for saved reel: ${doc.id}');
    }
    return SavedReel(
      id: doc.id,
      userId: data['userId'] ?? '',
      reelId: data['reelId'] ?? '',
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'reelId': reelId,
      'savedAt': Timestamp.fromDate(savedAt),
    };
  }
}
