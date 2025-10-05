import 'package:get/get.dart';
import 'package:xori/models/story_model.dart';
import 'package:xori/services/story_service.dart';

class StoryController extends GetxController {
  final StoryService _storyService = StoryService();
  final RxList<StoryModel> stories = <StoryModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final List<StoryModel>? storyList = args?['stories'] as List<StoryModel>?;
    final int? initialIndex = args?['initialIndex'] as int?;
    if (storyList != null && storyList.isNotEmpty) {
      stories.assignAll(storyList);
      currentIndex.value = initialIndex ?? 0;
      isLoading.value = false;
    } else {
      isLoading.value = false;
    }
  }

  Future<void> fetchStory(String storyId) async {
    isLoading.value = true;
    try {
      final doc = await _storyService.fetchStoryById(storyId);
      if (doc != null) {
        stories.assignAll([doc]);
        currentIndex.value = 0;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void nextStory() {
    if (currentIndex.value < stories.length - 1) {
      currentIndex.value++;
    } else {
      Get.back();
    }
  }

  void previousStory() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
    } else {
      Get.back();
    }
  }
}
