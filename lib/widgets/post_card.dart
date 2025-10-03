import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:xori/constants/app_colors.dart';
import 'package:xori/models/post_model.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_assets.dart';

class PostCard extends StatelessWidget {
  final dynamic
      post; // Can be either Post model or Map<String, dynamic> for backward compatibility
  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if it's a Post model or Map
    final bool isPostModel = post is Post;

    return Card(
      color: AppColors.inputBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              radius: 23,
              backgroundImage: isPostModel
                  ? (post as Post).userPhotoUrl.isNotEmpty
                      ? NetworkImage((post as Post).userPhotoUrl)
                      : const AssetImage('assets/images/profile1.png')
                          as ImageProvider
                  : AssetImage(post["profilePic"]),
            ),
            title: Text(
              isPostModel ? (post as Post).username : post["name"],
              style: const TextStyle(fontWeight: FontWeight.bold),
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

          // Post Image/Media
          if (isPostModel && (post as Post).mediaUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
            )
          else if (!isPostModel)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.asset(post["postImage"], fit: BoxFit.cover),
              ),
            ),

          // Caption
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 12, right: 12),
            child: Text(
              isPostModel ? (post as Post).caption : post["caption"],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          : post[
                              "shares"], // Static since shares not in Post model
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
        ],
      ),
    );
  }

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
}
