import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordVisible = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void login() {
    // Only UI navigation, no authentication
    Get.offAllNamed('/navwrapper');
  }

  void signInWithGoogle() {
    // Implement Google sign-in
  }

  void signInWithApple() {
    // Implement Apple sign-in
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
