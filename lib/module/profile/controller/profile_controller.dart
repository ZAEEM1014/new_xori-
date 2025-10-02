import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../models/post_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/post_service.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final PostService _postService = PostService();

  // User data from Firestore
  var user = UserModel.empty.obs;
  var name = "".obs;
  var bio = "".obs;
  var profileImageUrl = "".obs;
  var isLoading = true.obs;
  var isLoadingPosts = true.obs;

  // Real user statistics
  var posts = 0.obs;
  var followers = 1500.obs;
  var following = 100.obs;

  // User posts data
  var userPosts = <Post>[].obs;
  var userReels = <Post>[].obs;

  var activeTab = 0.obs; // 0 = Posts, 1 = Reels

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    loadUserPosts();
  }

  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get user document from Firestore directly
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          name.value = data['username'] ?? '';
          profileImageUrl.value = data['profileImageUrl'] ?? '';

          // Use personalityTraits from Firestore as bio display
          final personalityTraits =
              List<String>.from(data['personalityTraits'] ?? []);
          bio.value = personalityTraits.join(' | '); // Join traits with pipes
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserPosts() async {
    try {
      isLoadingPosts.value = true;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get user posts from PostService
        final allUserPosts = await _postService.getUserPosts(currentUser.uid);
        
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
      }
    } catch (e) {
      print('Error loading user posts: $e');
    } finally {
      isLoadingPosts.value = false;
    }
  }

  void changeTab(int index) {
    activeTab.value = index;
  }

  // Refresh posts data
  Future<void> refreshProfile() async {
    await Future.wait([
      loadUserProfile(),
      loadUserPosts(),
    ]);
  }

  // Get posts for current tab
  List<Post> get currentTabPosts {
    return activeTab.value == 0 ? userPosts : userReels;
  }
}
