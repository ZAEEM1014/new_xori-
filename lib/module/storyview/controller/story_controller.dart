import 'package:get/get.dart';
import 'package:xori/models/story_model.dart';
import 'package:xori/services/story_service.dart';

class StoryController extends GetxController {
  final StoryService _storyService = StoryService();
  final Rx<StoryModel?> story = Rx<StoryModel?>(null);
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    final storyId = Get.arguments?['storyId'] as String?;
    if (storyId != null) {
      fetchStory(storyId);
    }
  }

  Future<void> fetchStory(String storyId) async {
    isLoading.value = true;
    try {
      final doc = await _storyService.fetchStoryById(storyId);
      story.value = doc;
    } finally {
      isLoading.value = false;
    }
  }
}
