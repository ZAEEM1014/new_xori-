import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _postsCollection = 'posts';

  Future<String> createPost(Post post) async {
    try {
      final docRef = await _firestore.collection(_postsCollection).add(post.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection(_postsCollection).doc(postId).get();
      if (doc.exists && doc.data() != null) {
        return Post.fromDoc(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch post: ${e.toString()}');
    }
  }

  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user posts: ${e.toString()}');
    }
  }

  Future<List<Post>> getAllPosts() async {
    try {
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all posts: ${e.toString()}');
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to like post: ${e.toString()}');
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception('Failed to unlike post: ${e.toString()}');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).update({
        'isDeleted': true
      });
    } catch (e) {
      throw Exception('Failed to delete post: ${e.toString()}');
    }
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      final allowedFields = ['caption', 'hashtags', 'taggedUsers', 'location'];
      final filteredData = <String, dynamic>{};
      
      for (final entry in data.entries) {
        if (allowedFields.contains(entry.key)) {
          filteredData[entry.key] = entry.value;
        }
      }
      
      if (filteredData.isNotEmpty) {
        await _firestore.collection(_postsCollection).doc(postId).update(filteredData);
      }
    } catch (e) {
      throw Exception('Failed to update post: ${e.toString()}');
    }
  }

  Stream<List<Post>> streamUserPosts(String userId) {
    try {
      return _firestore
          .collection(_postsCollection)
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Post.fromDoc(doc)).toList());
    } catch (e) {
      throw Exception('Failed to stream user posts: ${e.toString()}');
    }
  }

  Stream<List<Post>> streamAllPosts() {
    try {
      return _firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Post.fromDoc(doc)).toList());
    } catch (e) {
      throw Exception('Failed to stream all posts: ${e.toString()}');
    }
  }
}
