import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/app_text_field.dart';
import '../controller/change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Change Password',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Make sure your new password is at least 8 characters long.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => AppTextField(
                    controller: controller.oldPasswordController,
                    hintText: 'Enter old Password',
                    isPassword: true,
                    isPasswordVisible: controller.isOldPasswordVisible.value,
                    onTogglePassword: controller.toggleOldPasswordVisibility,
                    onChanged: controller.onOldPasswordChanged,
                    errorText: controller.oldPasswordError.value.isEmpty
                        ? null
                        : controller.oldPasswordError.value,
                  )),
              const SizedBox(height: 16),
              Obx(() => AppTextField(
                    controller: controller.newPasswordController,
                    hintText: 'Enter new Password',
                    isPassword: true,
                    isPasswordVisible: controller.isNewPasswordVisible.value,
                    onTogglePassword: controller.toggleNewPasswordVisibility,
                    onChanged: controller.onNewPasswordChanged,
                    errorText: controller.newPasswordError.value.isEmpty
                        ? null
                        : controller.newPasswordError.value,
                  )),
              const SizedBox(height: 16),
              Obx(() => AppTextField(
                    controller: controller.confirmPasswordController,
                    hintText: 'Confirm password',
                    isPassword: true,
                    isPasswordVisible:
                        controller.isConfirmPasswordVisible.value,
                    onTogglePassword:
                        controller.toggleConfirmPasswordVisibility,
                    onChanged: controller.onConfirmPasswordChanged,
                    errorText: controller.confirmPasswordError.value.isEmpty
                        ? null
                        : controller.confirmPasswordError.value,
                  )),
              const SizedBox(height: 32),
              Obx(() => GradientButton(
                    text: 'Update Password',
                    onPressed: () => controller.updatePassword(),
                    enabled: !controller.isLoading.value,
                    isLoading: controller.isLoading.value,
                    height: 50,
                    borderRadius: 8,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
