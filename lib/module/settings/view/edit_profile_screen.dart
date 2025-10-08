import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/gradient_button.dart';
import '../../../constants/app_colors.dart';
import '../controller/edit_profile_controller.dart';

class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Edit Profile',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // Profile Image Section
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
                                      child: controller.profileImage.value !=
                                              null
                                          ? Image.file(
                                              controller.profileImage.value!,
                                              width: 110,
                                              height: 110,
                                              fit: BoxFit.cover,
                                            )
                                          : controller.profileImageUrl.value
                                                  .isNotEmpty
                                              ? Image.network(
                                                  controller
                                                      .profileImageUrl.value,
                                                  width: 110,
                                                  height: 110,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    width: 110,
                                                    height: 110,
                                                    color: AppColors
                                                        .inputBackground,
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 50,
                                                      color:
                                                          AppColors.textLight,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 110,
                                                  height: 110,
                                                  color:
                                                      AppColors.inputBackground,
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
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => AppColors
                                          .appGradient
                                          .createShader(bounds),
                                      child: const Icon(
                                        Icons.add,
                                        size: 20,
                                        color: Colors
                                            .white, // base color replaced by gradient
                                      ),
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

                      // Username Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: TextField(
                          controller: controller.usernameController,
                          decoration: const InputDecoration(
                            hintText: 'Username',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Field (Read-only)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: TextField(
                          controller: controller.emailController,
                          enabled: false,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Personality Traits Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color.fromARGB(255, 255, 255, 255)!),
                        ),
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
                            const SizedBox(height: 12),
                            Obx(() => Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: controller.allTraits.map((trait) {
                                    final isSelected = controller.selectedTraits
                                        .contains(trait);
                                    return ChoiceChip(
                                      label: Text(trait),
                                      selected: isSelected,
                                      onSelected: (_) =>
                                          controller.toggleTrait(trait),
                                      selectedColor:
                                          AppColors.appGradient.colors.first,
                                      backgroundColor: Colors.grey[200],
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
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
                      const SizedBox(height: 24),

                      // Error and Success Messages
                      Obx(() {
                        if (controller.hasError) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              controller.errorMessage.value,
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        } else if (controller.hasSuccess) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              controller.successMessage.value,
                              style: const TextStyle(color: Colors.green),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Save Button
                      Obx(() => GradientButton(
                            text: 'Save Changes',
                            onPressed: controller.isUpdating.value
                                ? () {}
                                : controller.updateProfile,
                            isLoading: controller.isUpdating.value,
                            height: 56,
                            borderRadius: 8,
                            margin: const EdgeInsets.symmetric(vertical: 0),
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
