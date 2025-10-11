import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets/enhanced_video_thumbnail_widget.dart';
import '../../../widgets/custom_follow_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../controller/xori_userprofile_controller.dart';

import '../../../models/post_model.dart';
import '../../../models/reel_model.dart';
import '../../../models/follow_user_model.dart';
import '../../../models/user_model.dart';
import '../../../routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class XoriUserProfileScreen extends GetView<XoriUserProfileController> {
  const XoriUserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = controller.user.value;

          // Check if user data is empty (no user found)
          if (user.uid.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'User not found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                /// Settings Button

                /// Profile Info
                Column(
                  children: [
                    SizedBox(height: 40),
                    user.profileImageUrl != null &&
                            user.profileImageUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                NetworkImage(user.profileImageUrl!),
                          )
                        : const CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(AppAssets.ellipse75),
                          ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.username,
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
                    const SizedBox(height: 6),
                    Text(
                      user.bio,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            title: controller.postsCount.value.toString(),
                            subtitle: "Posts",
                          ),
                          _StatItem(
                            title: controller.followersCount.value.toString(),
                            subtitle: "Followers",
                          ),
                          _StatItem(
                            title: controller.followingCount.value.toString(),
                            subtitle: "Following",
                          ),
                        ],
                      )),
                ),

                const SizedBox(height: 20),

                /// Follow + Message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomFollowButton(
                          currentUserId: FirebaseAuth.instance.currentUser!.uid,
                          targetUser: FollowUser(
                            userId: controller.user.value.uid,
                            username: controller.user.value.username,
                            userPhotoUrl:
                                controller.user.value.profileImageUrl ?? '',
                            followedAt: Timestamp.now(),
                          ),
                          height: 44,
                          width: double.infinity,
                          borderRadius: 10,
                          fontSize: 16,
                          onFollowToggled: () {
                            // Refresh counts when follow/unfollow happens
                            controller.refreshCounts();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _openChatWithUser(controller.user.value),
                        child: Container(
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Tabs (SVG icons)
                Row(
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

                const SizedBox(height: 16),

                /// Images / Reels Section
                controller.activeTab.value == 0
                    ? _buildStaggeredGridPosts()
                    : _buildStaggeredGridReels(),
              ],
            ),
          );
        }),
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
    return StreamBuilder<List<Post>>(
      stream: controller.userPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          print(
              '[DEBUG] XoriUserProfileScreen: Error loading posts: \\${snapshot.error}');
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Unable to load posts',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('No posts yet', style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              // Use the first media URL if available, else show a placeholder
              final imageUrl =
                  (post.mediaUrls.isNotEmpty) ? post.mediaUrls.first : null;
              return _postGridImage(imageUrl, height: 160 + (index % 3) * 40.0);
            },
          ),
        );
      },
    );
  }

  Widget _postGridImage(String? imageUrl, {double height = 160}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print(
              '[DEBUG] XoriUserProfileScreen: Error loading image $imageUrl: $error');
          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      ),
    );
  }

  Widget _buildStaggeredGridReels() {
    return Obx(() {
      final reels = controller.userReels;

      if (reels.isEmpty) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: Text('No reels yet', style: TextStyle(color: Colors.grey)),
          ),
        );
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
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            final height = heights[index % heights.length];
            return _buildReelGridItem(reel, height: height);
          },
        ),
      );
    });
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

  /// Open chat with the current user being viewed
  void _openChatWithUser(UserModel user) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Error',
          'You must be logged in to send messages',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (currentUser.uid == user.uid) {
        Get.snackbar(
          'Info',
          'You cannot send messages to yourself',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Navigate to chat screen
      Get.toNamed(
        AppRoutes.chat,
        arguments: {
          'contactId': user.uid,
          'name': user.username,
          'avatar': user.profileImageUrl,
          'isOnline': true,
        },
      );
    } catch (e) {
      print('[DEBUG] XoriUserProfileScreen: Error opening chat: $e');
      Get.snackbar(
        'Error',
        'Failed to open chat. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
