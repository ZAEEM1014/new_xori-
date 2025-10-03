import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:xori/constants/app_colors.dart';
import 'package:xori/models/post_model.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_assets.dart';
import 'package:xori/module/navbar_wrapper/controller/navwrapper_controller.dart';

class PostCard extends StatelessWidget {
  final dynamic
      post; // Can be either Post model or Map<String, dynamic> for backward compatibility
  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPostModel = post is Post;
    final String tappedUserUid =
        isPostModel ? (post as Post).userId : post["uid"] ?? '';

    final List<Widget> children = [];

    // Header
    children.add(
      ListTile(
        leading: GestureDetector(
          onTap: () => _handleProfileTap(context, tappedUserUid),
          child: CircleAvatar(
            radius: 23,
            backgroundImage: isPostModel
                ? (post as Post).userPhotoUrl.isNotEmpty
                    ? NetworkImage((post as Post).userPhotoUrl)
                    : const AssetImage('assets/images/profile1.png')
                        as ImageProvider
                : AssetImage(post["profilePic"]),
          ),
        ),
        title: GestureDetector(
          onTap: () => _handleProfileTap(context, tappedUserUid),
          child: Text(
            isPostModel ? (post as Post).username : post["name"],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: Text(isPostModel
            ? _formatTimestamp((post as Post).createdAt.toDate())
            : post["time"]),
        trailing: SvgPicture.asset(
          AppAssets.favourite,
          height: 24,
          width: 24,
        ),
      ),
    );

    // Post Image/Media
    if (isPostModel && (post as Post).mediaUrls.isNotEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.network(
              (post as Post).mediaUrls.first,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),
        ),
      );
    } else if (!isPostModel) {
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(post["postImage"], fit: BoxFit.cover),
          ),
        ),
      );
    }

    // Caption
    children.add(
      Padding(
        padding: EdgeInsets.only(top: 12.0, left: 12, right: 12),
        child: Text(
          isPostModel ? (post as Post).caption : post["caption"],
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );

    // Actions
    children.add(
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            // Likes
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  isPostModel
                      ? (post as Post).likes.length.toString()
                      : post["likes"],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Comments
            Row(
              children: [
                SvgPicture.asset(
                  AppAssets.comment,
                  height: 19,
                  width: 19,
                  color: AppColors.textDark,
                ),
                const SizedBox(width: 4),
                Text(
                  isPostModel
                      ? (post as Post).commentCount.toString()
                      : post["comments"],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Shares (static for now)
            Row(
              children: [
                SvgPicture.asset(
                  AppAssets.share,
                  height: 24,
                  width: 24,
                  color: AppColors.textDark,
                ),
                const SizedBox(width: 4),
                Text(
                  isPostModel
                      ? "0"
                      : post["shares"], // Static since shares not in Post model
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Card(
      color: AppColors.inputBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Only methods below this line

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleProfileTap(BuildContext context, String tappedUserUid) {
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (tappedUserUid == currentUserUid) {
      // Switch to profile tab (index 4) in NavbarWrapper
      try {
        final navController = Get.find<NavbarWrapperController>();
        navController.changeTab(4);
      } catch (e) {
        // If not found, fallback to navigation
        Get.toNamed(AppRoutes.navwrapper);
      }
      // Ensure we are on the navwrapper route
      if (Get.currentRoute != AppRoutes.navwrapper) {
        Get.toNamed(AppRoutes.navwrapper);
      }
    } else {
      Get.toNamed(AppRoutes.xoriUserProfile,
          parameters: {'uid': tappedUserUid});
    }
  }
}
