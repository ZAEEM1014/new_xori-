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

  // Real user statistics
  var posts = 0.obs;
  var followers = 1500.obs;
  var following = 100.obs;

  // User posts data (stream)
  RxList<Post> userPosts = <Post>[].obs;
  RxList<Post> userReels = <Post>[].obs;
  var isLoadingPosts = false.obs;

  var activeTab = 0.obs; // 0 = Posts, 1 = Reels

  Stream<List<Post>>? userPostsStream;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    setupUserPostsStream();
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

  void setupUserPostsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userPostsStream = _postService.streamUserPosts(currentUser.uid);
      userPostsStream!.listen((allUserPosts) {
        userPosts.value =
            allUserPosts.where((p) => p.mediaType != 'video').toList();
        userReels.value =
            allUserPosts.where((p) => p.mediaType == 'video').toList();
        posts.value = allUserPosts.length;
      });
    }
  }

  void changeTab(int index) {
    activeTab.value = index;
  }

  Future<void> refreshProfile() async {
    await loadUserProfile();
    // No need to reload posts, stream will update automatically
  }

  List<Post> get currentTabPosts {
    return activeTab.value == 0 ? userPosts : userReels;
  }
}
