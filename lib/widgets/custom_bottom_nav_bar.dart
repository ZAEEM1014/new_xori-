import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xori/constants/app_colors.dart';
import '../constants/app_assets.dart';
import 'package:get/get.dart';
import '../module/profile/controller/profile_controller.dart';
import 'dart:ui';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.textDark.withOpacity(0.1), // More transparent
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2), // Glass effect border
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSvgItem(AppAssets.home, 0),
                  _buildSvgItem(AppAssets.searchIcon, 1),
                  _buildSvgItem(AppAssets.add, 2), // center button
                  _buildSvgItem(AppAssets.reels, 3),
                  _buildProfileItem(4), // 👈 Profile image
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Normal SVG icons
  Widget _buildSvgItem(String assetPath, int index) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: isActive
          ? ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.appGradient.createShader(bounds),
              child: SvgPicture.asset(
                assetPath,
                height: 28,
                width: 28,
                color: Colors.white, // overridden by gradient
              ),
            )
          : SvgPicture.asset(
              assetPath,
              height: 28,
              width: 28,
              color: Colors.white,
            ),
    );
  }

  /// Profile image item (last one)
  Widget _buildProfileItem(int index) {
    final isActive = currentIndex == index;
    final profileController = Get.find<ProfileController>();
    return GestureDetector(
      onTap: () => onTap(index),
      child: Obx(() {
        final imageUrl = profileController.profileImageUrl.value;
        return Container(
          padding: const EdgeInsets.all(2), // border effect
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive ? AppColors.appGradient : null,
          ),
          child: CircleAvatar(
            radius: 15,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : const AssetImage(AppAssets.profilePic) as ImageProvider,
          ),
        );
      }),
    );
  }
}
