import 'package:get/get.dart';
import '../controller/story_controller.dart';


class StoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StoryController());
  }
}
