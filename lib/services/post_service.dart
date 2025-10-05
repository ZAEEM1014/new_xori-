import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  // Returns a stream of the like count for a post
  Stream<int> getLikeCount(String postId) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection('likes')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Returns a stream indicating whether the user has liked the post
  Stream<bool> isPostLikedByUser(String postId, String userId) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _postsCollection = 'posts';

  Future<String> createPost(Post post) async {
    try {
      final docRef =
          await _firestore.collection(_postsCollection).add(post.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  Future<Post?> getPostById(String postId) async {
    try {
      final doc =
          await _firestore.collection(_postsCollection).doc(postId).get();
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
      // Get all posts by user (no orderBy to avoid composite index requirement)
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Filter out deleted posts and sort client-side
      final posts = querySnapshot.docs
          .map((doc) => Post.fromDoc(doc))
          .where((post) => !post.isDeleted)
          .toList();

      // Sort by createdAt descending (newest first) on client side
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return posts;
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
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .set({'likedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to like post: ${e.toString()}');
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to unlike post: ${e.toString()}');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .update({'isDeleted': true});
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
        await _firestore
            .collection(_postsCollection)
            .doc(postId)
            .update(filteredData);
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
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs
            .map((doc) => Post.fromDoc(doc))
            .where((post) => !post.isDeleted)
            .toList();
        // Sort by createdAt descending (newest first) on client side
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      });
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
          .map((snapshot) =>
              snapshot.docs.map((doc) => Post.fromDoc(doc)).toList());
    } catch (e) {
      throw Exception('Failed to stream all posts: ${e.toString()}');
    }
  }

  // Get all posts with pagination support
  Future<List<Post>> getAllPostsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch paginated posts: ${e.toString()}');
    }
  }

  // Get all posts of a specific media type (image or video)
  Future<List<Post>> getPostsByMediaType(String mediaType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .where('mediaType', isEqualTo: mediaType)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch posts by media type: ${e.toString()}');
    }
  }

  // Get all posts with specific hashtags
  Future<List<Post>> getPostsByHashtag(String hashtag) async {
    try {
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .where('hashtags', arrayContains: hashtag)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch posts by hashtag: ${e.toString()}');
    }
  }

  // Get recent posts (last 24 hours)
  Future<List<Post>> getRecentPosts() async {
    try {
      final yesterday =
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)));

      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .where('createdAt', isGreaterThan: yesterday)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent posts: ${e.toString()}');
    }
  }

  // Get posts count for a user
  Future<int> getUserPostsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get user posts count: ${e.toString()}');
    }
  }

  // Get total posts count
  Future<int> getTotalPostsCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get total posts count: ${e.toString()}');
    }
  }
}
