import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _postsCollection = 'posts';
  final String _commentsSubcollection = 'comments';

  Future<void> addComment(String postId, Comment comment) async {
    final ref = _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsSubcollection)
        .doc();
    await ref.set(comment.toMap());
  }

  Stream<List<Comment>> streamComments(String postId) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Comment.fromDoc(doc)).toList());
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsSubcollection)
        .doc(commentId)
        .delete();
  }
}
