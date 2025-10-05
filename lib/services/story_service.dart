import 'follow_service.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import '../models/story_model.dart';

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
    return storiesSnap.docs
        .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
        .toList();
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
      return querySnap.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();
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
}
