import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets/app_text_field.dart';
import '../controller/add_post_controller.dart';

class AddPostScreen extends GetView<AddPostController> {
  // VideoPlayerController for preview
  static VideoPlayerController? _videoController;
  static Future<void>? _videoInitFuture;

  Widget _mediaPreview(AddPostController controller) {
    final isReel = controller.selectedTab.value == 1;
    final file = controller.selectedImage.value;
    if (file == null) return const SizedBox.shrink();
    if (isReel) {
      // Video preview with improved performance
      if (_videoController == null ||
          _videoController!.dataSource != file.path) {
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(file);
        _videoInitFuture = _videoController!.initialize();
      }
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FutureBuilder(
              future: _videoInitFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _videoController != null &&
                    _videoController!.value.isInitialized) {
                  return AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  );
                } else {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                _videoController?.dispose();
                _videoController = null;
                _videoInitFuture = null;
                controller.removeSelectedImage();
                (controller as dynamic).update();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          if (_videoController != null && _videoController!.value.isInitialized)
            Positioned(
              bottom: 12,
              left: 12,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black54,
                onPressed: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                  (controller as dynamic).update();
                },
                child: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    } else {
      // Image preview
      return Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                file,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: controller.removeSelectedImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  const AddPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inputBackground,
      appBar: AppBar(
        backgroundColor: AppColors.inputBackground,
        elevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(color: AppColors.textDark, fontSize: 15),
        ),
        centerTitle: false,
      ),
      body: Obx(() => SingleChildScrollView(
            child: Column(
              children: [
                // Toggle Tabs OUTSIDE main container
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 0,
                  ),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.switchTab(0),
                            child: Container(
                              height: 36,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: controller.selectedTab.value == 0
                                    ? AppColors.appGradient
                                    : null,
                                color: controller.selectedTab.value == 0
                                    ? null
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  'Post',
                                  style: TextStyle(
                                    color: controller.selectedTab.value == 0
                                        ? Colors.white
                                        : AppColors.textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.switchTab(1),
                            child: Container(
                              height: 36,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: controller.selectedTab.value == 1
                                    ? AppColors.appGradient
                                    : null,
                                color: controller.selectedTab.value == 1
                                    ? null
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  'Reel',
                                  style: TextStyle(
                                    color: controller.selectedTab.value == 1
                                        ? Colors.white
                                        : AppColors.textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload Image/Video label
                        const Text(
                          'Upload Image/Video',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Selected Image/Video Preview
                        _mediaPreview(controller),

                        // Upload Image/Video container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: [
                              if (controller.isLoading.value)
                                const CircularProgressIndicator()
                              else ...[
                                SvgPicture.asset(
                                  AppAssets.uploadCloud,
                                  width: 48,
                                  height: 48,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.textLight,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  controller.selectedImage.value != null
                                      ? 'Change image or capture new one'
                                      : 'Tap to upload from gallery or camera',
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.textDark,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.pickImageFromGallery,
                                    icon: SvgPicture.asset(
                                      AppAssets.galleryIcon,
                                      width: 22,
                                      height: 22,
                                      colorFilter: ColorFilter.mode(
                                        AppColors.textLight,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    label: const Text('Gallery'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.textDark,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.pickImageFromCamera,
                                    icon: SvgPicture.asset(
                                      AppAssets.cameraIcon,
                                      width: 22,
                                      height: 22,
                                      colorFilter: ColorFilter.mode(
                                        AppColors.textLight,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    label: const Text('Camera'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Caption label
                        const Text(
                          'Caption',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Caption paragraph box
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: AppTextField(
                            controller: controller.captionController,
                            hintText: 'Write a caption...',
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            keyboardType: TextInputType.multiline,
                            minLines: 3,
                            maxLines: 6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Hashtags label
                        const Text(
                          'Hashtags',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Hashtags box
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: AppTextField(
                            controller: controller.hashtagsController,
                            hintText:
                                'Add hashtags (e.g., #nature #photography)',
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Tag people
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                AppAssets.tagIcon,
                                width: 22,
                                height: 22,
                                colorFilter: ColorFilter.mode(
                                  AppColors.textLight,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Tag people',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.divider),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  foregroundColor: AppColors.textLight,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: controller.isUploading.value
                                    ? null
                                    : controller.cancelPost,
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: controller.isUploading.value
                                    ? null
                                    : controller.createPost,
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: controller.isUploading.value
                                        ? null
                                        : AppColors.appGradient,
                                    color: controller.isUploading.value
                                        ? Colors.grey
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    child: controller.isUploading.value
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            controller.selectedTab.value == 0
                                                ? 'Post'
                                                : 'Create Reel',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Add space at the bottom so content can scroll above the navbar
                const SizedBox(height: 90),
              ],
            ),
          )),
    );
  }
}
