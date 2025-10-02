import 'package:get/get.dart';

class NavbarWrapperController extends GetxController {
  // Observable index
  final selectedIndex = 0.obs;

  // Update selected index
  void changeTab(int index) {
    selectedIndex.value = index;
  }
}
