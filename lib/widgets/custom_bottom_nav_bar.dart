import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xori/constants/app_colors.dart';
import '../constants/app_assets.dart';
import 'package:get/get.dart';
import '../module/profile/controller/profile_controller.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.textDark.withOpacity(0.25), // pill background
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
