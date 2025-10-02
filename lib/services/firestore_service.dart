import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xori/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userCollection = 'users';

  Future<void> saveUser(UserModel user) async {
    try {
      print(
          '[DEBUG] FirestoreService: Attempting to save user with UID: ${user.uid}');
      print('[DEBUG] FirestoreService: User data: ${user.toJson()}');
      await _firestore
          .collection(_userCollection)
          .doc(user.uid)
          .set(user.toJson());
      print('[DEBUG] FirestoreService: User saved successfully to Firestore');
    } catch (e) {
      print('[DEBUG] FirestoreService: Error saving user: $e');
      throw Exception('Failed to save user: $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_userCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<bool> usernameExists(String username) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection(_userCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check username: $e');
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_userCollection).doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Posts collection methods
  Future<void> createPost(Map<String, dynamic> postData) async {
    try {
      print('[DEBUG] FirestoreService: Creating post with data: $postData');
      await _firestore.collection('posts').add(postData);
      print('[DEBUG] FirestoreService: Post created successfully');
    } catch (e) {
      print('[DEBUG] FirestoreService: Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPosts({int limit = 20}) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[DEBUG] FirestoreService: Error getting posts: $e');
      throw Exception('Failed to get posts: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[DEBUG] FirestoreService: Error getting user posts: $e');
      throw Exception('Failed to get user posts: $e');
    }
  }
}
