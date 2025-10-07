import 'package:get/get.dart';
import '../controller/session_control_controller.dart';

class SessionControlBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SessionControlController>(() => SessionControlController());
  }
}
