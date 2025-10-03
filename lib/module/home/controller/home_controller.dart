import 'package:get/get.dart';
import 'package:xori/data/demo_top_bar.dart';
import 'package:xori/data/demo_statuses.dart';
import 'package:xori/services/post_service.dart';
import 'package:xori/models/post_model.dart';

class HomeController extends GetxController {
  final PostService _postService = PostService();

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
    fetchAllPosts();
  }

  Future<void> fetchAllPosts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final fetchedPosts = await _postService.getAllPosts();
      posts.assignAll(fetchedPosts);
    } catch (e) {
      errorMessage.value = 'Failed to load posts: ${e.toString()}';
      print('Error fetching posts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPosts() async {
    await fetchAllPosts();
  }
}
