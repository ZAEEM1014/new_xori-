import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';
import '../../../models/reel_model.dart';
import '../../../services/post_service.dart';
import '../../../services/reel_service.dart';

class ProfileController extends GetxController {
  final PostService _postService = PostService();
  final ReelService _reelService = ReelService();

  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _userStreamSubscription;
  StreamSubscription<List<Post>>? _postsStreamSubscription;
  StreamSubscription<List<Reel>>? _reelsStreamSubscription;

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
  var userReels = <Reel>[].obs;

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
    _reelsStreamSubscription?.cancel();
    super.onClose();
  }

  void _initializeStreams() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _startUserStream(currentUser.uid);
      _startPostsStream(currentUser.uid);
      _startReelsStream(currentUser.uid);
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
          // Only handle posts (not videos)
          userPosts.clear();
          userPosts.addAll(allUserPosts);

          // Update posts count (only posts, not reels)
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

  void _startReelsStream(String userId) {
    _reelsStreamSubscription = _reelService.streamUserReels(userId).listen(
      (List<Reel> userReelsList) {
        try {
          // Handle reels from reels collection
          userReels.clear();
          userReels.addAll(userReelsList);
          
          print('[DEBUG] ProfileController: Loaded ${userReels.length} reels');
        } catch (e) {
          print('Error processing reels data: $e');
        }
      },
      onError: (error) {
        print('Error in reels stream: $error');
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
      _reelsStreamSubscription?.cancel();

      // Restart streams
      _startUserStream(currentUser.uid);
      _startPostsStream(currentUser.uid);
      _startReelsStream(currentUser.uid);
    }
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

  // Clear all user data when logging out
  Future<void> clearUserData() async {
    try {
      // Cancel all active streams
      _userStreamSubscription?.cancel();
      _postsStreamSubscription?.cancel();
      _reelsStreamSubscription?.cancel();

      // Clear all observables
      user.value = UserModel.empty;
      name.value = "";
      bio.value = "";
      profileImageUrl.value = "";
      isLoading.value = true;
      isLoadingPosts.value = true;
      posts.value = 0;
      followers.value = 0;
      following.value = 0;
      userPosts.clear();
      userReels.clear();
      activeTab.value = 0;

      print('[DEBUG] ProfileController: User data cleared successfully');
    } catch (e) {
      print('[DEBUG] ProfileController: Error clearing user data: $e');
    }
  }

  // Reinitialize with new user data
  Future<void> reinitializeForNewUser() async {
    await clearUserData();
    _initializeStreams();
  }
}
