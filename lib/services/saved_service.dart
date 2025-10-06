import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_post_model.dart';

class SavedService {
  final _firestore = FirebaseFirestore.instance;

  // Add a saved post
  Future<void> savePost(String userId, String postId) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('saved')
        .doc(postId);
    await ref.set({
      'userId': userId,
      'postId': postId,
      'savedAt': Timestamp.now(),
    });
  }

  // Remove a saved post
  Future<void> unsavePost(String userId, String postId) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('saved')
        .doc(postId);
    await ref.delete();
  }

  // Check if a post is saved by the user
  Future<bool> isPostSaved(String userId, String postId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved')
        .doc(postId)
        .get();
    return doc.exists;
  }

  // Stream all saved posts for a user
  Stream<List<SavedPost>> streamSavedPosts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavedPost.fromDoc(doc)).toList());
  }
}
