import 'package:get/get.dart';

class SettingsController extends GetxController {
  // Add any settings logic here
  var isDarkMode = false.obs;
  var isTwoFactorEnabled = false.obs;

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
  }

  void toggleTwoFactor(bool value) {
    isTwoFactorEnabled.value = value;
  }
}
