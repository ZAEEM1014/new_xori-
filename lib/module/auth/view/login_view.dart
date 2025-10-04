import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:xori/constants/app_colors.dart';
import 'package:xori/widgets/app_text_field.dart';
import 'package:xori/widgets/gradient_button.dart';
import 'package:xori/widgets/app_text_button.dart';
import 'package:xori/constants/app_assets.dart';
import '../controller/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Text(
                'Welcome back! Glad\nto see you, Again!',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.3,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),
              Obx(() => AppTextField(
                    controller: TextEditingController(),
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => controller.updateLoginEmail(value),
                    errorText: controller.loginEmailError.value.isEmpty
                        ? null
                        : controller.loginEmailError.value,
                  )),
              const SizedBox(height: 12),
              Obx(() => AppTextField(
                    controller: TextEditingController(),
                    hintText: 'Enter your password',
                    isPassword: true,
                    isPasswordVisible: controller.isLoginPasswordVisible.value,
                    onTogglePassword: controller.toggleLoginPasswordVisibility,
                    onChanged: (value) => controller.updateLoginPassword(value),
                    errorText: controller.loginPasswordError.value.isEmpty
                        ? null
                        : controller.loginPasswordError.value,
                  )),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => controller
                      .sendPasswordResetEmail(controller.loginEmail.value),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.linkColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Error and Success Messages
              Obx(() {
                if (controller.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (controller.hasSuccess) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      controller.successMessage.value,
                      style: const TextStyle(color: Colors.green),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(() {
                final enabled = controller.isLoginFormValid.value &&
                    !controller.isLoading.value;
                return GradientButton(
                  text: 'Login',
                  onPressed: enabled
                      ? () {
                          controller.signIn();
                        }
                      : () {},
                  isLoading: controller.isLoading.value,
                  height: 56,
                  borderRadius: 8,
                  margin: const EdgeInsets.symmetric(vertical: 0),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or Login with',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 105,
                    height: 56,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed:
                          null, // TODO: Implement Google sign-in if needed
                      icon: Image.asset(
                        'assets/icons/google.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  Container(
                    width: 105,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                        onPressed:
                            null, // TODO: Implement Apple sign-in if needed
                        icon: SvgPicture.asset(
                          AppAssets.appleIcon, // make sure it's an .svg file
                          width: 24,
                          height: 24,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppTextButton(
              text: 'Register Now',
              onPressed: () {
                Get.toNamed('/signup');
              },
              textStyle: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
