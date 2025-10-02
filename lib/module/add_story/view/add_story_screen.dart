import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:xori/constants/app_assets.dart';
import 'package:xori/constants/app_colors.dart';

class AddStoryScreen extends StatelessWidget {
  const AddStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full screen background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.reelsbg),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Close button
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
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
          // Capture button
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Add camera capture functionality
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

          // Bottom bar with controls
          // Bottom bar with controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              decoration: BoxDecoration(color: AppColors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceAround, // 👈 better than spaceEvenly with Padding
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppColors.appGradient.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: SvgPicture.asset(
                      AppAssets.galleryIcon,
                      height: 32,
                      width: 32,
                      color: Colors.white, // 👈 force fill so gradient works
                    ),
                  ),
                  ShaderMask(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
