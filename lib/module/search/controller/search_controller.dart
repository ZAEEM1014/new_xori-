import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';
import '../../../models/follow_user_model.dart';
import '../../../services/follow_service.dart';
import '../../../services/auth_service.dart';

class SearchController extends GetxController {
  final TextEditingController searchTextController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FollowService _followService = FollowService();
  final AuthService _authService = AuthService();

  // Observable variables
  final RxString searchQuery = ''.obs;
  final RxList<UserModel> searchedUsers = <UserModel>[].obs;
  final RxList<Post> searchedPosts = <Post>[].obs;
  final RxList<String> trendingHashtags = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, bool> followingStatus = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to search text changes
    searchTextController.addListener(_onSearchChanged);
    // Load trending hashtags
    _loadTrendingHashtags();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    final query = searchTextController.text.trim();
    searchQuery.value = query;

    if (query.isEmpty) {
      searchedUsers.clear();
      searchedPosts.clear();
      followingStatus.clear();
    } else {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    isLoading.value = true;

    try {
      // Search users and posts in parallel
      await Future.wait([
        _searchUsers(query),
        _searchPosts(query),
      ]);
    } catch (e) {
      print('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return;

      // Search users by username (case insensitive)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username',
              isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      final users = <UserModel>[];
      for (final doc in usersSnapshot.docs) {
        try {
          final userData = doc.data();
          if (userData.isNotEmpty) {
            final user = UserModel.fromJson(userData);
            if (user.uid != currentUserId && user.username.isNotEmpty) {
              users.add(user);
            }
          }
        } catch (e) {
          print('Error parsing user document ${doc.id}: $e');
        }
      }

      searchedUsers.value = users;

      // Check follow status for each user
      for (final user in users) {
        _checkFollowStatus(user.uid);
      }
    } catch (e) {
      print('Error searching users: $e');
      searchedUsers.clear();
    }
  }

  Future<void> _searchPosts(String query) async {
    try {
      // Search posts by caption, hashtags, or username
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final posts = <Post>[];
      for (final doc in postsSnapshot.docs) {
        try {
          final post = Post.fromDoc(doc);
          final searchTerm = query.toLowerCase();

          final matchesCaption =
              post.caption.toLowerCase().contains(searchTerm);
          final matchesUsername =
              post.username.toLowerCase().contains(searchTerm);
          final matchesHashtags = post.hashtags
              .any((hashtag) => hashtag.toLowerCase().contains(searchTerm));

          if (matchesCaption || matchesUsername || matchesHashtags) {
            posts.add(post);
            if (posts.length >= 20) break; // Limit to 20 posts
          }
        } catch (e) {
          print('Error parsing post document ${doc.id}: $e');
        }
      }

      searchedPosts.value = posts;
    } catch (e) {
      print('Error searching posts: $e');
      searchedPosts.clear();
    }
  }

  void _checkFollowStatus(String targetUserId) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    _followService.isFollowingStream(currentUserId, targetUserId).listen(
      (isFollowing) {
        followingStatus[targetUserId] = isFollowing;
      },
      onError: (error) {
        print('Error checking follow status for $targetUserId: $error');
        followingStatus[targetUserId] = false;
      },
    );
  }

  Future<void> toggleFollow(UserModel targetUser) async {
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return;

      final followUser = FollowUser(
        userId: targetUser.uid,
        username: targetUser.username,
        userPhotoUrl: targetUser.profileImageUrl ?? '',
        followedAt: Timestamp.now(),
      );

      await _followService.toggleFollow(currentUserId, followUser);

      // The follow status will be updated automatically through the stream
    } catch (e) {
      print('Error toggling follow: $e');
      Get.snackbar(
        'Error',
        'Failed to update follow status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToUserProfile(UserModel user) {
    try {
      Get.toNamed('/xori_userprofile', parameters: {'uid': user.uid});
    } catch (e) {
      print('Error navigating to user profile: $e');
      Get.snackbar(
        'Error',
        'Failed to open user profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool isFollowing(String userId) {
    return followingStatus[userId] ?? false;
  }

  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
    searchedUsers.clear();
    searchedPosts.clear();
    followingStatus.clear();
  }

  Future<void> _loadTrendingHashtags() async {
    try {
      // Get hashtags from recent posts
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      final hashtagCount = <String, int>{};

      for (final doc in postsSnapshot.docs) {
        try {
          final data = doc.data();
          final hashtags = (data['hashtags'] as List?)?.cast<String>() ?? [];

          for (final hashtag in hashtags) {
            if (hashtag.isNotEmpty) {
              hashtagCount[hashtag] = (hashtagCount[hashtag] ?? 0) + 1;
            }
          }
        } catch (e) {
          print('Error processing hashtag from post: $e');
        }
      }

      // Sort hashtags by popularity and get top trending ones
      final sortedHashtags = hashtagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      trendingHashtags.value = sortedHashtags
          .where((entry) => entry.value >= 2) // At least 2 posts
          .take(8)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('Error loading trending hashtags: $e');
      // Fallback trending hashtags
      trendingHashtags.value = [
        '#photography',
        '#travel',
        '#fitness',
        '#foodie',
        '#art',
        '#nature',
        '#lifestyle',
        '#sunset'
      ];
    }
  }

  Future<void> searchByHashtag(String hashtag) async {
    // Clear current search and set hashtag as search query
    searchTextController.text = hashtag;
    searchQuery.value = hashtag;

    isLoading.value = true;

    try {
      // Search posts specifically by hashtag
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('hashtags', arrayContains: hashtag.toLowerCase())
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      final posts = <Post>[];
      for (final doc in postsSnapshot.docs) {
        try {
          final post = Post.fromDoc(doc);
          posts.add(post);
        } catch (e) {
          print('Error parsing post document ${doc.id}: $e');
        }
      }

      searchedPosts.value = posts;
      searchedUsers.clear(); // Clear users when searching by hashtag
      followingStatus.clear();
    } catch (e) {
      print('Error searching by hashtag: $e');
      searchedPosts.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
