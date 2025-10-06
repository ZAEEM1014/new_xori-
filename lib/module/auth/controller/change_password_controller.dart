import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';

class ChangePasswordController extends GetxController {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isOldPasswordVisible = false.obs;
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  final oldPasswordError = ''.obs;
  final newPasswordError = ''.obs;
  final confirmPasswordError = ''.obs;
  final isFormValid = false.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // No auto-validation on field change; only validate on submit
  }

  void onOldPasswordChanged(String value) {
    oldPasswordError.value = '';
  }

  void onNewPasswordChanged(String value) {
    newPasswordError.value = '';
  }

  void onConfirmPasswordChanged(String value) {
    confirmPasswordError.value = '';
  }

  void toggleOldPasswordVisibility() => isOldPasswordVisible.toggle();
  void toggleNewPasswordVisibility() => isNewPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();

  bool _validateForm() {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    oldPasswordError.value = '';
    newPasswordError.value = '';
    confirmPasswordError.value = '';

    bool valid = true;
    if (oldPassword.isEmpty) {
      oldPasswordError.value = 'Old password required';
      valid = false;
    }
    if (newPassword.isEmpty) {
      newPasswordError.value = 'New password required';
      valid = false;
    } else if (newPassword.length < 8) {
      newPasswordError.value = 'At least 8 characters';
      valid = false;
    }
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Confirm your password';
      valid = false;
    } else if (newPassword != confirmPassword) {
      confirmPasswordError.value = 'Passwords do not match';
      valid = false;
    }
    isFormValid.value = valid;
    return valid;
  }

  Future<void> updatePassword() async {
    if (isLoading.value) return;
    if (!_validateForm()) return;
    isLoading.value = true;
    try {
      await AuthService().changePassword(
        oldPasswordController.text.trim(),
        newPasswordController.text.trim(),
      );
      Get.snackbar(
          'Success', 'Password updated successfully! Please log in again.',
          snackPosition: SnackPosition.BOTTOM);
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      await Future.delayed(const Duration(seconds: 2));
      await AuthService().signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
