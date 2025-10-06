import 'package:get/get.dart';
import '../controller/reels_controller.dart';

class ReelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReelController>(() => ReelController());
  }
}
