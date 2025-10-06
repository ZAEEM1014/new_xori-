import 'package:get/get.dart';
import 'package:xori/module/chat_list/controller/chat_list_controller.dart';

class ChatListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}
