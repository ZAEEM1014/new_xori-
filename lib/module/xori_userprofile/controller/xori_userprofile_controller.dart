import 'package:get/get.dart';
import '../../../models/user_model.dart';

import '../../../services/user_service.dart';
import '../../../services/post_service.dart';
import '../../../services/follow_service.dart';
import '../../../models/post_model.dart';

class XoriUserProfileController extends GetxController {
  final String uid;
  final FirestoreService _firestoreService = FirestoreService();
  final FollowService _followService = FollowService();

  // Observables
  var user = UserModel.empty.obs;
  var isLoading = true.obs;
  var isFollowing = false.obs;
  var activeTab = 0.obs; // 0 = Posts, 1 = Tagged

  // Counts
  var followersCount = 0.obs;
  var followingCount = 0.obs;
  var postsCount = 0.obs;

  XoriUserProfileController(this.uid);

  // Stream of posts for this user (from PostService)
  Stream<List<Post>> get userPostsStream => PostService().streamUserPosts(uid);

  // Stream of reels for this user
  Stream<List<Post>> get userReelsStream => PostService().streamUserReels(uid);

  @override
  void onInit() {
    super.onInit();
    _listenToUser();
    _loadCounts();
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
      // Load counts concurrently
      final futures = await Future.wait([
        _followService.getFollowersCount(uid),
        _followService.getFollowingCount(uid),
        _followService.getPostsCount(uid),
      ]);

      followersCount.value = futures[0];
      followingCount.value = futures[1];
      postsCount.value = futures[2];
    } catch (e) {
      print('[DEBUG] XoriUserProfileController: Error loading counts: $e');
    }
  }

  /// Refresh counts when needed
  Future<void> refreshCounts() async {
    await _loadCounts();
  }
}
