import 'package:get/get.dart';

import 'package:xori/module/add_story/controller/add_story_controller.dart';

class AddStoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddStoryController>(() => AddStoryController());
  }
}
