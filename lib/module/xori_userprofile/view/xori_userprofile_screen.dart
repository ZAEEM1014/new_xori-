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
        child: Obx(() {
          try {
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

                  /// Stats (placeholders, replace with real data if available)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _StatItem(
                          title: '0',
                          subtitle: "Posts",
                        ),
                        _StatItem(
                          title: '0',
                          subtitle: "Followers",
                        ),
                        _StatItem(
                          title: '0',
                          subtitle: "Following",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Follow + Message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
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
          } catch (e) {
            print('[DEBUG] XoriUserProfileScreen: Error rendering UI: $e');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
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
    try {
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
            try {
              return _gridImage(images[index], height: heights[index]);
            } catch (e) {
              print(
                  '[DEBUG] XoriUserProfileScreen: Error building grid item: $e');
              return Container(
                height: heights[index],
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.error_outline, color: Colors.grey),
              );
            }
          },
        ),
      );
    } catch (e) {
      print('[DEBUG] XoriUserProfileScreen: Error building posts grid: $e');
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Unable to load posts',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
  }

  Widget _buildStaggeredGridReels() {
    try {
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
            try {
              return _gridImage(images[index], height: heights[index]);
            } catch (e) {
              print(
                  '[DEBUG] XoriUserProfileScreen: Error building grid item: $e');
              return Container(
                height: heights[index],
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.error_outline, color: Colors.grey),
              );
            }
          },
        ),
      );
    } catch (e) {
      print('[DEBUG] XoriUserProfileScreen: Error building reels grid: $e');
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Unable to load reels',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
  }

  Widget _gridImage(String asset, {double height = 160}) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          height: height,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print(
                '[DEBUG] XoriUserProfileScreen: Error loading image $asset: $error');
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
        ),
      );
    } catch (e) {
      print('[DEBUG] XoriUserProfileScreen: Error creating grid image: $e');
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.error_outline, color: Colors.grey),
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
