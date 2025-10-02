import 'package:get/get.dart';
import '../controller/navwrapper_controller.dart';
import '../../add_post/controller/add_post_controller.dart';

class NavbarWrapperBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NavbarWrapperController());
    Get.lazyPut(() => AddPostController());
  }
}
