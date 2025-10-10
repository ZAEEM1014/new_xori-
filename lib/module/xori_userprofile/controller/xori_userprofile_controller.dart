import 'package:get/get.dart';
import '../../../models/user_model.dart';
import 'dart:async';

import '../../../services/user_service.dart';
import '../../../services/post_service.dart';
import '../../../services/reel_service.dart';
import '../../../services/follow_service.dart';
import '../../../models/post_model.dart';
import '../../../models/reel_model.dart';

class XoriUserProfileController extends GetxController {
  final String uid;
  final FirestoreService _firestoreService = FirestoreService();
  final FollowService _followService = FollowService();
  final PostService _postService = PostService();
  final ReelService _reelService = ReelService();

  // Stream subscriptions
  StreamSubscription<List<Post>>? _postsStreamSubscription;
  StreamSubscription<List<Reel>>? _reelsStreamSubscription;

  // Observables
  var user = UserModel.empty.obs;
  var isLoading = true.obs;
  var isFollowing = false.obs;
  var activeTab = 0.obs; // 0 = Posts, 1 = Tagged

  // Counts
  var followersCount = 0.obs;
  var followingCount = 0.obs;
  var postsCount = 0.obs;

  // User posts data
  var userPosts = <Post>[].obs;
  var userReels = <Reel>[].obs;

  XoriUserProfileController(this.uid);

  // Stream of posts for this user (from PostService)
  Stream<List<Post>> get userPostsStream => _postService.streamUserPosts(uid);

  // Stream of reels for this user (from ReelService)
  Stream<List<Reel>> get userReelsStream => _reelService.streamUserReels(uid);

  @override
  void onInit() {
    super.onInit();
    _listenToUser();
    _loadCounts();
    _startPostsStream();
    _startReelsStream();
  }

  @override
  void onClose() {
    _postsStreamSubscription?.cancel();
    _reelsStreamSubscription?.cancel();
    super.onClose();
  }

  void _listenToUser() {
    try {
      _firestoreService.streamUserByUid(uid).listen(
        (userModel) {
          try {
            if (userModel != null) {
              user.value = userModel;
            }
            isLoading.value = false;
          } catch (e) {
            print(
                '[DEBUG] XoriUserProfileController: Error updating user data: $e');
            isLoading.value = false;
          }
        },
        onError: (error) {
          print(
              '[DEBUG] XoriUserProfileController: Error listening to user stream: $error');
          isLoading.value = false;
        },
      );
    } catch (e) {
      print(
          '[DEBUG] XoriUserProfileController: Error setting up user stream: $e');
      isLoading.value = false;
    }
  }

  void _startPostsStream() {
    _postsStreamSubscription = _postService.streamUserPosts(uid).listen(
      (List<Post> allUserPosts) {
        try {
          // Only handle posts (not videos)
          userPosts.clear();
          userPosts.addAll(allUserPosts);

          // Update posts count - this is the key fix!
          postsCount.value = allUserPosts.length;
          
          print('[DEBUG] XoriUserProfileController: Updated posts count to ${postsCount.value}');
        } catch (e) {
          print('Error processing posts data: $e');
        }
      },
      onError: (error) {
        print('Error in posts stream: $error');
      },
    );
  }

  void _startReelsStream() {
    _reelsStreamSubscription = _reelService.streamUserReels(uid).listen(
      (List<Reel> userReelsList) {
        try {
          // Handle reels from reels collection
          userReels.clear();
          userReels.addAll(userReelsList);
          
          print('[DEBUG] XoriUserProfileController: Loaded ${userReels.length} reels');
        } catch (e) {
          print('Error processing reels data: $e');
        }
      },
      onError: (error) {
        print('Error in reels stream: $error');
      },
    );
  }

  void toggleFollow() {
    isFollowing.value = !isFollowing.value;
    // Optionally update followers count in Firestore
  }

  void changeTab(int index) {
    activeTab.value = index;
  }

  /// Load actual counts from Firestore
  Future<void> _loadCounts() async {
    try {
      // Load follower counts from service
      final futures = await Future.wait([
        _followService.getFollowersCount(uid),
        _followService.getFollowingCount(uid),
      ]);

      followersCount.value = futures[0];
      followingCount.value = futures[1];
      
      // Posts count will be updated by the stream listener
      print('[DEBUG] XoriUserProfileController: Loaded followers: ${followersCount.value}, following: ${followingCount.value}');
    } catch (e) {
      print('[DEBUG] XoriUserProfileController: Error loading counts: $e');
    }
  }

  /// Refresh counts when needed
  Future<void> refreshCounts() async {
    await _loadCounts();
    // Posts count is automatically updated by the stream
  }
}
