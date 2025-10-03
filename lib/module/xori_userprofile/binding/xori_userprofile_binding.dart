import 'package:get/get.dart';
import '../controller/xori_userprofile_controller.dart';

class XoriUserProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<XoriUserProfileController>(
      () => XoriUserProfileController(Get.parameters['uid'] ?? ''),
    );
  }
}
