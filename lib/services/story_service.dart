import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import '../models/story_model.dart';

class StoryService extends GetxService {
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
    } catch (e, stack) {
      print('Error fetching active stories for user $uid: $e');
      return [];
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
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
        .map((doc) =>
            StoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
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

  /// Get all active (non-expired) stories of the current user only
  Future<List<StoryModel>> getCurrentUserActiveStories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final storiesSnap = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: user.uid)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt', descending: false)
          .orderBy('postedAt', descending: true)
          .get();

      return storiesSnap.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching current user active stories: $e');
      return [];
    }
  }

  /// Get all active stories of users that the current user is following
  Future<List<StoryModel>> getFollowingUsersActiveStories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get list of user IDs that current user is following
      final followingSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .get();

      final followingIds = followingSnap.docs.map((d) => d.id).toList();

      // If not following anyone, return empty list
      if (followingIds.isEmpty) return [];

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
    } catch (e) {
      print('Error fetching following users active stories: $e');
      return [];
    }
  }
}
