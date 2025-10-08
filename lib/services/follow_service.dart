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
        
        // Use batch write for atomic operations
        final batch = _firestore.batch();
        
        // Add targetUser to currentUser's following
        batch.set(
          _firestore
              .collection(usersCollection)
              .doc(currentUserId)
              .collection(followingSub)
              .doc(targetUser.userId),
          {
            'userId': targetUser.userId,
            'username': targetUser.username,
            'userPhotoUrl': targetUser.userPhotoUrl,
            'followedAt': now,
          }
        );
        
        // Fetch current user's username and profileImageUrl
        final currentUserDoc = await _firestore
            .collection(usersCollection)
            .doc(currentUserId)
            .get();
        final currentUserData = currentUserDoc.data() ?? {};
        final currentUsername = currentUserData['username'] ?? '';
        final currentUserPhoto = currentUserData['profileImageUrl'] ?? '';
        
        // Add currentUser to targetUser's followers
        batch.set(
          _firestore
              .collection(usersCollection)
              .doc(targetUser.userId)
              .collection(followersSub)
              .doc(currentUserId),
          {
            'userId': currentUserId,
            'username': currentUsername,
            'userPhotoUrl': currentUserPhoto,
            'followedAt': now,
          }
        );
        
        // Update follower counts
        batch.update(
          _firestore.collection(usersCollection).doc(currentUserId),
          {
            'followingCount': FieldValue.increment(1),
          }
        );
        
        batch.update(
          _firestore.collection(usersCollection).doc(targetUser.userId),
          {
            'followersCount': FieldValue.increment(1),
          }
        );
        
        // Commit batch
        await batch.commit();
      } else {
        // Already following: unfollow
        final batch = _firestore.batch();
        
        // Remove from collections
        batch.delete(
          _firestore
              .collection(usersCollection)
              .doc(currentUserId)
              .collection(followingSub)
              .doc(targetUser.userId)
        );
        
        batch.delete(
          _firestore
              .collection(usersCollection)
              .doc(targetUser.userId)
              .collection(followersSub)
              .doc(currentUserId)
        );
        
        // Update follower counts (ensure they don't go negative)
        final currentUserDoc = await _firestore
            .collection(usersCollection)
            .doc(currentUserId)
            .get();
        final targetUserDoc = await _firestore
            .collection(usersCollection)
            .doc(targetUser.userId)
            .get();
            
        final currentUserData = currentUserDoc.data() ?? {};
        final targetUserData = targetUserDoc.data() ?? {};
        
        final currentFollowingCount = currentUserData['followingCount'] ?? 0;
        final targetFollowersCount = targetUserData['followersCount'] ?? 0;
        
        // Only decrement if count is greater than 0
        if (currentFollowingCount > 0) {
          batch.update(
            _firestore.collection(usersCollection).doc(currentUserId),
            {
              'followingCount': FieldValue.increment(-1),
            }
          );
        }
        
        if (targetFollowersCount > 0) {
          batch.update(
            _firestore.collection(usersCollection).doc(targetUser.userId),
            {
              'followersCount': FieldValue.increment(-1),
            }
          );
        }
        
        // Commit batch
        await batch.commit();
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

  /// Get actual followers count from subcollection
  Future<int> getFollowersCount(String userId) async {
    try {
      final followersSnap = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(followersSub)
          .get();
      return followersSnap.docs.length;
    } catch (e) {
      print('Error fetching followers count for $userId: $e');
      return 0;
    }
  }

  /// Get actual following count from subcollection
  Future<int> getFollowingCount(String userId) async {
    try {
      final followingSnap = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(followingSub)
          .get();
      return followingSnap.docs.length;
    } catch (e) {
      print('Error fetching following count for $userId: $e');
      return 0;
    }
  }

  /// Get posts count for a user
  Future<int> getPostsCount(String userId) async {
    try {
      final postsSnap = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .get();
      return postsSnap.docs.length;
    } catch (e) {
      print('Error fetching posts count for $userId: $e');
      return 0;
    }
  }
}
