import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';
import '../../../services/post_service.dart';
import '../../../services/follow_service.dart';

class ProfileController extends GetxController {
  final PostService _postService = PostService();
  final FollowService _followService = FollowService();

  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _userStreamSubscription;
  StreamSubscription<List<Post>>? _postsStreamSubscription;

  // User data from Firestore
  var user = UserModel.empty.obs;
  var name = "".obs;
  var bio = "".obs;
  var profileImageUrl = "".obs;
  var isLoading = true.obs;
  var isLoadingPosts = true.obs;

  // Real user statistics
  var posts = 0.obs;
  var followers = 0.obs;
  var following = 0.obs;

  // User posts data
  var userPosts = <Post>[].obs;
  var userReels = <Post>[].obs;

  var activeTab = 0.obs; // 0 = Posts, 1 = Reels

  @override
  void onInit() {
    super.onInit();
    _initializeStreams();
  }

  @override
  void onClose() {
    _userStreamSubscription?.cancel();
    _postsStreamSubscription?.cancel();
    super.onClose();
  }

  void _initializeStreams() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _startUserStream(currentUser.uid);
      _startPostsStream(currentUser.uid);
    }
  }

  void _startUserStream(String userId) {
    isLoading.value = true;

    _userStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (DocumentSnapshot userDoc) {
        try {
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            name.value = data['username'] ?? '';
            profileImageUrl.value = data['profileImageUrl'] ?? '';

            // Use personalityTraits from Firestore as bio display
            final personalityTraits =
                List<String>.from(data['personalityTraits'] ?? []);
            bio.value = personalityTraits.join(' | '); // Join traits with pipes

            // Update follower/following counts from Firestore
            followers.value = data['followersCount'] ?? 0;
            following.value = data['followingCount'] ?? 0;
          }
        } catch (e) {
          print('Error processing user data: $e');
        } finally {
          isLoading.value = false;
        }
      },
      onError: (error) {
        print('Error in user stream: $error');
        isLoading.value = false;
      },
    );
  }

  void _startPostsStream(String userId) {
    isLoadingPosts.value = true;

    _postsStreamSubscription = _postService.streamUserPosts(userId).listen(
      (List<Post> allUserPosts) {
        try {
          // Separate posts and reels
          userPosts.clear();
          userReels.clear();

          for (final post in allUserPosts) {
            if (post.mediaType == 'video') {
              userReels.add(post);
            } else {
              userPosts.add(post);
            }
          }

          // Update posts count
          posts.value = allUserPosts.length;
        } catch (e) {
          print('Error processing posts data: $e');
        } finally {
          isLoadingPosts.value = false;
        }
      },
      onError: (error) {
        print('Error in posts stream: $error');
        isLoadingPosts.value = false;
      },
    );
  }

  void changeTab(int index) {
    activeTab.value = index;
  }

  // Refresh data by restarting streams
  Future<void> refreshProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Cancel existing streams
      _userStreamSubscription?.cancel();
      _postsStreamSubscription?.cancel();

      // Restart streams
      _startUserStream(currentUser.uid);
      _startPostsStream(currentUser.uid);
    }
  }

  // Get posts for current tab
  List<Post> get currentTabPosts {
    return activeTab.value == 0 ? userPosts : userReels;
  }

  // Manual refresh methods for backward compatibility
  Future<void> loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _startUserStream(currentUser.uid);
    }
  }

  Future<void> loadUserPosts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _startPostsStream(currentUser.uid);
    }
  }
}
