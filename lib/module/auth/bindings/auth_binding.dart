import 'package:get/get.dart';
import 'package:xori/module/auth/controller/auth_controller.dart';
import 'package:xori/services/auth_service.dart';
import 'package:xori/services/firestore_service.dart';
import 'package:xori/services/storage_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize services
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => FirestoreService(), fenix: true);
    Get.lazyPut(() => StorageService(), fenix: true);

    // Initialize controller
    Get.lazyPut(() => AuthController(), fenix: true);
  }
}
