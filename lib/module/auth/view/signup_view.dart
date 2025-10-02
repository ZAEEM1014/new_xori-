import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:xori/constants/app_colors.dart';
import 'package:xori/module/auth/controller/auth_controller.dart';
import 'package:xori/widgets/app_text_field.dart';
import 'package:xori/widgets/gradient_button.dart';
import 'package:xori/widgets/app_text_button.dart';
import 'package:xori/constants/app_assets.dart';

class SignupView extends GetView<AuthController> {
  const SignupView({super.key});

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
              const SizedBox(height: 48),
              const Text(
                'Hello! Register to get\nstarted',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.3,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.appGradient,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Obx(() => ClipOval(
                              child: controller.profileImage.value != null
                                  ? Image.file(
                                      controller.profileImage.value!,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 110,
                                      height: 110,
                                      color: AppColors.inputBackground,
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                            )),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: PopupMenuButton<int>(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.appGradient,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 0) {
                            controller.pickImageFromCamera();
                          } else if (value == 1) {
                            controller.pickImageFromGallery();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 0,
                            child: Text('Take Photo'),
                          ),
                          const PopupMenuItem(
                            value: 1,
                            child: Text('Choose from Gallery'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: TextEditingController(),
                hintText: 'Username',
                onChanged: (value) => controller.updateSignUpUsername(value),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: TextEditingController(),
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => controller.updateSignUpEmail(value),
              ),
              const SizedBox(height: 12),
              Obx(() => AppTextField(
                    controller: TextEditingController(),
                    hintText: 'Password',
                    isPassword: true,
                    isPasswordVisible: controller.isSignUpPasswordVisible.value,
                    onTogglePassword: controller.toggleSignUpPasswordVisibility,
                    onChanged: (value) =>
                        controller.updateSignUpPassword(value),
                  )),
              const SizedBox(height: 12),
              Obx(() => AppTextField(
                    controller: TextEditingController(),
                    hintText: 'Confirm password',
                    isPassword: true,
                    isPasswordVisible:
                        controller.isSignUpConfirmPasswordVisible.value,
                    onTogglePassword:
                        controller.toggleSignUpConfirmPasswordVisibility,
                    onChanged: (value) =>
                        controller.updateSignUpConfirmPassword(value),
                  )),
              const SizedBox(height: 16),
              // Personality Traits Selection UI
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose personality traits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.allTraits.map((trait) {
                            final isSelected =
                                controller.selectedTraits.contains(trait);
                            return ChoiceChip(
                              label: Text(trait),
                              selected: isSelected,
                              onSelected: (_) => controller.toggleTrait(trait),
                              selectedColor: AppColors.appGradient.colors.first,
                              backgroundColor: Colors.grey[200],
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              shape: const StadiumBorder(),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.appGradient.colors.last
                                    : Colors.grey,
                              ),
                            );
                          }).toList(),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
                final enabled = controller.isSignUpFormValid.value &&
                    !controller.isLoading.value;
                return GradientButton(
                  text: 'Register',
                  onPressed: enabled
                      ? () {
                          controller.signUp();
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or Register with',
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 32),
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
              'Already have an account? ',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppTextButton(
              text: 'Login Now',
              onPressed: () {
                // TODO: Implement navigation to login page in your UI layer
              },
              textStyle: TextStyle(
                fontSize: 15,
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
