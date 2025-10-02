import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets/gradient_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../controller/xori_userprofile_controller.dart';

class XoriUserProfileScreen extends GetView<XoriUserProfileController> {
  const XoriUserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Settings Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.settings, color: AppColors.primary, size: 28),
                  ],
                ),
              ),

              /// Profile Info
              Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(AppAssets.ellipse75),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          controller.name.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () => Text(
                      controller.bio.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        title: controller.posts.value.toString(),
                        subtitle: "Posts",
                      ),
                      _StatItem(
                        title: "${controller.followers.value}",
                        subtitle: "Followers",
                      ),
                      _StatItem(
                        title: controller.following.value.toString(),
                        subtitle: "Following",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Follow + Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          text: controller.isFollowing.value
                              ? "Following"
                              : "Follow",
                          onPressed: controller.toggleFollow,
                          height: 44,
                          borderRadius: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 44,
                        width: 50,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Tabs (SVG icons)
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSvgTabIcon(
                      AppAssets.gridTabIcon,
                      controller.activeTab.value == 0,
                      () => controller.changeTab(0),
                    ),
                    const SizedBox(width: 30),
                    _buildSvgTabIcon(
                      AppAssets.reels,
                      controller.activeTab.value == 1,
                      () => controller.changeTab(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// Images / Reels Section
              Obx(() {
                if (controller.activeTab.value == 0) {
                  return _buildStaggeredGridPosts();
                } else {
                  return _buildStaggeredGridReels();
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSvgTabIcon(String asset, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: SvgPicture.asset(
          asset,
          width: 28,
          height: 28,
          color: isActive ? AppColors.primary : AppColors.textLight,
        ),
      ),
    );
  }

  Widget _buildStaggeredGridPosts() {
    final images = [
      AppAssets.searchedImg1,
      AppAssets.searchedImg2,
      AppAssets.searchedImg3,
      AppAssets.searchedImg4,
      AppAssets.searchedImg5,
    ];
    final heights = [160.0, 220.0, 120.0, 180.0, 140.0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _gridImage(images[index], height: heights[index]);
        },
      ),
    );
  }

  Widget _buildStaggeredGridReels() {
    final images = [
      AppAssets.searchedImg1,
      AppAssets.searchedImg2,
      AppAssets.searchedImg3,
      AppAssets.searchedImg4,
      AppAssets.searchedImg5,
    ];
    final heights = [200.0, 180.0, 220.0, 160.0, 140.0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _gridImage(images[index], height: heights[index]);
        },
      ),
    );
  }

  Widget _gridImage(String asset, {double height = 160}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StatItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
      ],
    );
  }
}
