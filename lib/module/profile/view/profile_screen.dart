import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/enhanced_video_thumbnail_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../controller/profile_controller.dart';
import '../../../models/post_model.dart';
import '../../../models/reel_model.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                      GestureDetector(
                        onTap: () => Get.toNamed('/settings'),
                        child: Icon(Icons.settings,
                            color: AppColors.primary, size: 28),
                      ),
                    ],
                  ),
                ),

                /// Profile Info
                Column(
                  children: [
                    Obx(() => CircleAvatar(
                          radius: 50,
                          backgroundImage: controller
                                  .profileImageUrl.value.isNotEmpty
                              ? NetworkImage(controller.profileImageUrl.value)
                              : const AssetImage(AppAssets.ellipse75)
                                  as ImageProvider,
                        )),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
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

                /// Edit Profile Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GradientButton(
                    text: "Edit Profile",
                    onPressed: () {
                      Get.toNamed('/editProfile');
                    },
                    height: 44,
                    borderRadius: 10,
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
                  if (controller.isLoadingPosts.value) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

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
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: SvgPicture.asset(
          asset,
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            isActive ? AppColors.primary : AppColors.textLight,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildStaggeredGridPosts() {
    if (controller.userPosts.isEmpty) {
      return _buildEmptyState('No posts yet', 'Share your first post!');
    }

    final heights = [160.0, 220.0, 120.0, 180.0, 140.0, 200.0, 160.0, 180.0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.userPosts.length,
        itemBuilder: (context, index) {
          final post = controller.userPosts[index];
          final height = heights[index % heights.length];
          return _buildPostGridItem(post, height: height);
        },
      ),
    );
  }

  Widget _buildStaggeredGridReels() {
    if (controller.userReels.isEmpty) {
      return _buildEmptyState('No reels yet', 'Create your first reel!');
    }

    final heights = [200.0, 180.0, 220.0, 160.0, 140.0, 240.0, 180.0, 200.0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.userReels.length,
        itemBuilder: (context, index) {
          final reel = controller.userReels[index];
          final height = heights[index % heights.length];
          return _buildReelGridItem(reel, height: height);
        },
      ),
    );
  }

  Widget _buildPostGridItem(Post post, {double height = 160}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        post.mediaUrls.isNotEmpty ? post.mediaUrls.first : '',
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            color: Colors.grey[300],
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReelGridItem(Reel reel, {double height = 200}) {
    return EnhancedVideoThumbnailWidget(
      videoUrl: reel.videoUrl,
      height: height,
      width: double.infinity,
      borderRadius: BorderRadius.circular(12),
      showPlayButton: true,
      playButtonColor: Colors.white,
      playButtonSize: 36,
      onTap: () {
        // Disabled navigation for now
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
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
