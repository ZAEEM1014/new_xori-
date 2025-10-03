import 'package:get/get.dart';
import 'package:xori/data/demo_top_bar.dart';
import 'package:xori/data/demo_statuses.dart';
import 'package:xori/services/post_service.dart';
import 'package:xori/models/post_model.dart';
import 'dart:async';

class HomeController extends GetxController {
  final PostService _postService = PostService();

  // Stream subscription
  StreamSubscription<List<Post>>? _postsStreamSubscription;

  // Top bar is a single map
  final RxMap<String, dynamic> topBar = demoTopBar.obs;

  // Statuses is a list of maps
  final RxList<Map<String, dynamic>> statuses = demoStatuses.obs;

  // Posts from Firestore
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _startPostsStream();
  }

  @override
  void onClose() {
    _postsStreamSubscription?.cancel();
    super.onClose();
  }

  void _startPostsStream() {
    isLoading.value = true;
    errorMessage.value = '';

    _postsStreamSubscription = _postService.streamAllPosts().listen(
      (List<Post> fetchedPosts) {
        try {
          posts.assignAll(fetchedPosts);
          errorMessage.value = '';
        } catch (e) {
          errorMessage.value = 'Failed to process posts: ${e.toString()}';
          print('Error processing posts: $e');
        } finally {
          isLoading.value = false;
        }
      },
      onError: (error) {
        errorMessage.value = 'Failed to load posts: ${error.toString()}';
        print('Error in posts stream: $error');
        isLoading.value = false;
      },
    );
  }

  Future<void> refreshPosts() async {
    // Restart the stream for refresh
    _postsStreamSubscription?.cancel();
    _startPostsStream();
  }

  // Backward compatibility method
  Future<void> fetchAllPosts() async {
    _startPostsStream();
  }
}
