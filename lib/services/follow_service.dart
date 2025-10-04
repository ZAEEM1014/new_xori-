import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/follow_user_model.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String usersCollection = 'users';
  static const String followersSub = 'followers';
  static const String followingSub = 'following';

  /// Real-time stream: true if following, false otherwise
  Stream<bool> isFollowingStream(String currentUserId, String targetUserId) {
    try {
      return _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(followingSub)
          .doc(targetUserId)
          .snapshots()
          .map((doc) => doc.exists);
    } catch (e) {
      // If error, emit false
      return Stream.value(false);
    }
  }

  /// Toggle follow/unfollow logic
  Future<void> toggleFollow(String currentUserId, FollowUser targetUser) async {
    try {
      final followingDoc = await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(followingSub)
          .doc(targetUser.userId)
          .get();

      if (!followingDoc.exists) {
        // Not following: follow
        final now = Timestamp.now();
        // Add targetUser to currentUser's following
        await _firestore
            .collection(usersCollection)
            .doc(currentUserId)
            .collection(followingSub)
            .doc(targetUser.userId)
            .set({
          'uid': targetUser.userId,
          'username': targetUser.username,
          'profileImageUrl': targetUser.userPhotoUrl,
          'followedAt': now,
        });
        // Add currentUser to targetUser's followers
        await _firestore
            .collection(usersCollection)
            .doc(targetUser.userId)
            .collection(followersSub)
            .doc(currentUserId)
            .set({
          'uid': currentUserId,
          // You may want to fetch current user's username/photo for display
          'username': '',
          'profileImageUrl': '',
          'followedAt': now,
        });
      } else {
        // Already following: unfollow
        await _firestore
            .collection(usersCollection)
            .doc(currentUserId)
            .collection(followingSub)
            .doc(targetUser.userId)
            .delete();
        await _firestore
            .collection(usersCollection)
            .doc(targetUser.userId)
            .collection(followersSub)
            .doc(currentUserId)
            .delete();
      }
    } catch (e) {
      throw Exception('Failed to toggle follow: ${e.toString()}');
    }
  }

  /// Get list of user IDs that the current user is following
  Future<List<String>> getFollowingUserIds(String currentUserId) async {
    try {
      final followingSnap = await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(followingSub)
          .get();

      return followingSnap.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching following user IDs: $e');
      return [];
    }
  }
}
