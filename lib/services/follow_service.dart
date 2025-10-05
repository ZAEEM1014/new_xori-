import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/follow_user_model.dart';

class FollowService {
  /// Debug: Log all following and followers for a user
  Future<void> debugUserFollowCollections(String userId) async {
    try {
      // Log following
      final followingSnap = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(followingSub)
          .get();
      print('--- [DEBUG] FOLLOWING for user $userId ---');
      if (followingSnap.docs.isEmpty) {
        print('No following users.');
      } else {
        for (final doc in followingSnap.docs) {
          print('Following: ${doc.id} | Data: ${doc.data()}');
        }
      }

      // Log followers
      final followersSnap = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(followersSub)
          .get();
      print('--- [DEBUG] FOLLOWERS for user $userId ---');
      if (followersSnap.docs.isEmpty) {
        print('No followers.');
      } else {
        for (final doc in followersSnap.docs) {
          print('Follower: ${doc.id} | Data: ${doc.data()}');
        }
      }
      print('--- [DEBUG] END for user $userId ---');
    } catch (e) {
      print('[DEBUG] Error debugging follow collections for $userId: $e');
    }
  }

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
          'userId': targetUser.userId,
          'username': targetUser.username,
          'userPhotoUrl': targetUser.userPhotoUrl,
          'followedAt': now,
        });
        // Fetch current user's username and profileImageUrl
        final currentUserDoc = await _firestore
            .collection(usersCollection)
            .doc(currentUserId)
            .get();
        final currentUserData = currentUserDoc.data() ?? {};
        final currentUsername = currentUserData['username'] ?? '';
        final currentUserPhoto = currentUserData['profileImageUrl'] ?? '';
        // Add currentUser to targetUser's followers
        await _firestore
            .collection(usersCollection)
            .doc(targetUser.userId)
            .collection(followersSub)
            .doc(currentUserId)
            .set({
          'userId': currentUserId,
          'username': currentUsername,
          'userPhotoUrl': currentUserPhoto,
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

  /// Get list of user IDs that the current user is following, with debug logging
  Future<List<String>> getFollowingUserIds(String currentUserId) async {
    try {
      final followingSnap = await _firestore
          .collection(usersCollection)
          .doc(currentUserId)
          .collection(followingSub)
          .get();

      final ids = followingSnap.docs.map((doc) => doc.id).toList();
      print('[FollowService] User $currentUserId is following: $ids');
      return ids;
    } catch (e) {
      print('Error fetching following user IDs for $currentUserId: $e');
      return [];
    }
  }
}
