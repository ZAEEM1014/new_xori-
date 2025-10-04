import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:xori/constants/app_assets.dart';
import 'package:xori/constants/app_colors.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import '../controller/add_story_controller.dart';
import '../../../widgets/gradient_button.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/story_service.dart';

class AddStoryScreen extends StatelessWidget {
  const AddStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddStoryController controller = Get.find<AddStoryController>();
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Obx(() {
        final imageSelected = controller.selectedImage.value != null;
        return Stack(
          children: [
            // Show selected image fullscreen
            if (imageSelected)
              Positioned.fill(
                child: Image.file(
                  controller.selectedImage.value!,
                  fit: BoxFit.cover,
                ),
              )
            // Show camera preview if no image selected
            else if (controller.isCameraInitialized.value &&
                controller.cameraController.value != null)
              Positioned.fill(
                child: CameraPreview(controller.cameraController.value!),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),

            // Add Story button (top right) when image is selected
            if (imageSelected)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 20,
                child: Obx(() {
                  final isUploading =
                      Get.find<CloudinaryService>().isUploading.value;
                  return GradientButton(
                    text: isUploading ? 'Uploading...' : 'Add Story',
                    height: 40,
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    enabled: !isUploading,
                    isLoading: isUploading,
                    onPressed: () async {
                      final cloudinaryService = Get.find<CloudinaryService>();
                      final storyService = Get.find<StoryService>();
                      final imageFile = controller.selectedImage.value;
                      if (imageFile == null) return;
                      // Upload to Cloudinary
                      final url = await cloudinaryService.uploadImage(imageFile,
                          folder: 'xori_stories');
                      if (url != null) {
                        await storyService.uploadStory(url);
                        controller.clearImage();
                        // Navigate to navwrapper (home) after successful upload
                        Get.offAllNamed('/navwrapper');
                        Get.snackbar('Success', 'Story added!');
                      } else {
                        Get.snackbar('Error', 'Failed to upload story image.');
                      }
                    },
                  );
                }),
              ),

            // Close button (top left) when image is selected
            if (imageSelected)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => controller.clearImage(),
                ),
              ),

            // Close button (top left) when camera is active
            if (!imageSelected)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),

            // Capture button (center bottom) when camera is active
            if (!imageSelected)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () async {
                      if (controller.cameraController.value != null &&
                          controller
                              .cameraController.value!.value.isInitialized) {
                        final image = await controller.cameraController.value!
                            .takePicture();
                        controller.setSelectedImage(File(image.path));
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.appGradient,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.appGradient,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom bar with controls (gallery/camera switch) only when camera is active
            if (!imageSelected)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(color: AppColors.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: GestureDetector(
                          onTap: () => controller.pickImageFromGallery(),
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) =>
                                AppColors.appGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                            child: SvgPicture.asset(
                              AppAssets.galleryIcon,
                              height: 32,
                              width: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: GestureDetector(
                          onTap: () => controller.switchCamera(),
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) =>
                                AppColors.appGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                            child: SvgPicture.asset(
                              AppAssets.cameraIcon,
                              height: 32,
                              width: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
