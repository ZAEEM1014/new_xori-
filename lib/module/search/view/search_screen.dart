import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_assets.dart';
import '../../search/controller/search_controller.dart';

import '../../../models/user_model.dart';
import '../../../models/post_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchScreen extends GetView<SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar with icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDADADA)),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: SvgPicture.asset(
                          AppAssets.searchIcon,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller.searchTextController,
                        decoration: const InputDecoration(
                          hintText: 'Search users, posts...',
                          hintStyle: TextStyle(
                            color: AppColors.textLight,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textLight),
                            onPressed: controller.clearSearch,
                          )
                        : const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
            // Search Results or Default Content
            Expanded(
              child: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
                  return _buildDefaultContent();
                } else {
                  return _buildSearchResults();
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Trending Hashtags Section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Trending hashtags',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
          _buildTrendingHashtags(),
          const SizedBox(height: 100),
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.search,
                  size: 60,
                  color: AppColors.textLight,
                ),
                SizedBox(height: 16),
                Text(
                  'Search for users and posts',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      }

      if (controller.searchedUsers.isEmpty &&
          controller.searchedPosts.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: AppColors.textLight,
              ),
              SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Users Section
            if (controller.searchedUsers.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Suggested for you',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: controller.searchedUsers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildUserListItem(controller.searchedUsers[index]);
                },
              ),
              const SizedBox(height: 24),
            ],
            // Trending Hashtags Section
            if (controller.searchQuery.value.isEmpty ||
                controller.searchedUsers.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Trending hashtags',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              _buildTrendingHashtags(),
              const SizedBox(height: 24),
            ],
            // Posts Section
            if (controller.searchedPosts.isNotEmpty) ...[
              if (controller.searchedUsers
                  .isEmpty) // Only show "Posts" title when no users
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Posts',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              _buildPostsGrid(),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildUserListItem(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage:
                user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
            child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
            backgroundColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Popular on your network',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildFollowButton(user),
        ],
      ),
    );
  }

  Widget _buildFollowButton(UserModel user) {
    return Obx(() {
      final isFollowing = controller.followingStatus[user.uid] ?? false;

      return SizedBox(
        width: 72,
        height: 28,
        child: ElevatedButton(
          onPressed: () => controller.toggleFollow(user),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isFollowing ? Colors.grey[200] : Colors.transparent,
            foregroundColor: isFollowing ? AppColors.textDark : Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: isFollowing
                  ? const BorderSide(color: Color(0xFFE0E0E0))
                  : BorderSide.none,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: isFollowing ? null : AppColors.appGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFollowing ? AppColors.textDark : Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPostsGrid() {
    final List<double> heights = [
      150.0,
      200.0,
      180.0,
      220.0,
      160.0,
      190.0,
      170.0,
      210.0,
      180.0,
      200.0,
      150.0,
      240.0,
      160.0,
      190.0,
      220.0,
      170.0,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: controller.searchedPosts.length,
        itemBuilder: (context, index) {
          final post = controller.searchedPosts[index];
          final height = heights[index % heights.length];
          return _buildPostGridItem(post, height);
        },
      ),
    );
  }

  Widget _buildTrendingHashtags() {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.trendingHashtags.map((hashtag) {
              return GestureDetector(
                onTap: () => controller.searchByHashtag(hashtag),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    hashtag,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }

  Widget _buildPostGridItem(Post post, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: post.mediaUrls.isNotEmpty
            ? Image.network(
                post.mediaUrls.first,
                width: double.infinity,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.inputBackground,
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: AppColors.textLight,
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: AppColors.inputBackground,
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 40,
                    color: AppColors.textLight,
                  ),
                ),
              ),
      ),
    );
  }
}
