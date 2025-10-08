import 'follow_service.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import '../models/story_model.dart';
import '../models/story_comment_model.dart';

class StoryService extends GetxService {
  Future<StoryModel?> fetchStoryById(String storyId) async {
    final doc = await _firestore.collection('stories').doc(storyId).get();
    if (doc.exists && doc.data() != null) {
      return StoryModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Fetch all active (non-expired) stories for users the current user is following
  Future<List<StoryModel>> getActiveStoriesOfFollowingUsers() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final followService = FollowService();
    final followingIds = await followService.getFollowingUserIds(user.uid);
    print('[StoryService] Following IDs for user ${user.uid}: $followingIds');
    if (followingIds.isEmpty) {
      print('[StoryService] No following users found for user ${user.uid}');
      return [];
    }
    final now = DateTime.now();
    final storiesSnap = await _firestore
        .collection('stories')
        .where('userId', whereIn: followingIds)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: false)
        .orderBy('postedAt', descending: true)
        .get();
    print(
        '[StoryService] Stories fetched for following users: ${storiesSnap.docs.length}');
    // Ensure distinct stories by storyId
    final allStories = storiesSnap.docs
        .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
        .toList();
    final Map<String, StoryModel> uniqueStories = {};
    for (final story in allStories) {
      uniqueStories[story.storyId] = story;
    }
    return uniqueStories.values.toList();
  }

  /// Fetch all active (non-expired) stories for a given user by uid.
  Future<List<StoryModel>> getActiveStoriesForUser(String uid) async {
    try {
      final now = DateTime.now();
      final querySnap = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: uid)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt', descending: false)
          .orderBy('postedAt', descending: true)
          .get();
      // Ensure distinct stories by storyId
      final allStories = querySnap.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();
      final Map<String, StoryModel> uniqueStories = {};
      for (final story in allStories) {
        uniqueStories[story.storyId] = story;
      }
      return uniqueStories.values.toList();
    } catch (e) {
      print('Error fetching active stories for user $uid: $e');
      return [];
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Creates a story document with a Cloudinary image URL and 24h expiry
  Future<void> uploadStory(String storyUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final storyId = _firestore.collection('stories').doc().id;
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    // Use safe access for fields, fallback to empty string if missing
    final username = (userDoc.data()?['username'] ?? '').toString();
    final userProfileImage =
        (userDoc.data()?['profileImageUrl'] ?? '').toString();
    final story = StoryModel(
      storyId: storyId,
      userId: user.uid,
      username: username,
      userProfileImage: userProfileImage,
      storyUrl: storyUrl,
      postedAt: now,
      expiresAt: expiresAt,
      viewedBy: [],
    );
    await _firestore.collection('stories').doc(storyId).set(story.toMap());
  }

  // Fetches stories for current user and users they follow (not expired)
  Future<List<StoryModel>> getStoriesForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final followingSnap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .get();
    final followingIds = followingSnap.docs.map((d) => d.id).toList();
    followingIds.add(user.uid); // include own stories
    final now = DateTime.now();
    final storiesSnap = await _firestore
        .collection('stories')
        .where('userId', whereIn: followingIds)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: false)
        .orderBy('postedAt', descending: true)
        .get();
    return storiesSnap.docs
        .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Streams stories for current user and users they follow (not expired)
  Stream<List<StoryModel>> streamStoriesForCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final followingRef =
        _firestore.collection('users').doc(user.uid).collection('following');
    final now = DateTime.now();
    // Listen to following changes, then stories
    return followingRef.snapshots().switchMap((followingSnap) {
      final followingIds = followingSnap.docs.map((d) => d.id).toList();
      followingIds.add(user.uid);
      return _firestore
          .collection('stories')
          .where('userId', whereIn: followingIds)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt', descending: false)
          .orderBy('postedAt', descending: true)
          .snapshots();
    }).map((storiesSnap) => storiesSnap.docs
        .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Marks a story as viewed by the current user
  Future<void> markStoryAsViewed(String storyId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final storyRef = _firestore.collection('stories').doc(storyId);
    await storyRef.update({
      'viewedBy': FieldValue.arrayUnion([user.uid])
    });
  }

  /// Stream all active (non-expired) stories of the current user only
  Stream<List<StoryModel>> getCurrentUserActiveStories() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    // Use snapshots to listen for real-time updates
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: user.uid)
        .where('expiresAt', isGreaterThan: DateTime.now())
        .orderBy('expiresAt', descending: false)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((storiesSnap) => storiesSnap.docs
            .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Like functionality for stories
  Future<void> likeStory(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to like story: ${e.toString()}');
    }
  }

  Future<void> unlikeStory(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception('Failed to unlike story: ${e.toString()}');
    }
  }

  // Get like count for a story
  Stream<int> getLikeCount(String storyId) {
    return _firestore.collection('stories').doc(storyId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final likes = doc.data()!['likes'];
        if (likes is List) {
          return likes.length;
        }
      }
      return 0;
    });
  }

  // Check if user has liked the story
  Stream<bool> isStoryLikedByUser(String storyId, String userId) {
    return _firestore.collection('stories').doc(storyId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final likes = doc.data()!['likes'];
        if (likes is List) {
          return likes.contains(userId);
        }
      }
      return false;
    });
  }

  // Comment functionality for stories
  Future<void> addComment(String storyId, StoryComment comment) async {
    try {
      // Add comment to subcollection
      await _firestore
          .collection('stories')
          .doc(storyId)
          .collection('comments')
          .add(comment.toMap());

      // Update comment count in story document
      await _firestore
          .collection('stories')
          .doc(storyId)
          .update({'commentCount': FieldValue.increment(1)});
    } catch (e) {
      throw Exception('Failed to add comment: ${e.toString()}');
    }
  }

  // Get comments for a story
  Stream<List<StoryComment>> streamComments(String storyId) {
    return _firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StoryComment.fromDoc(doc)).toList());
  }

  // Get comment count for a story
  Stream<int> getCommentCount(String storyId) {
    return _firestore.collection('stories').doc(storyId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data()!['commentCount'] ?? 0;
      }
      return 0;
    });
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
