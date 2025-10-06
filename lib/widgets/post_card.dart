import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../module/navbar_wrapper/controller/navwrapper_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:xori/constants/app_colors.dart';
import 'package:xori/models/post_model.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_assets.dart';

import 'app_like_button.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:xori/services/post_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'comment_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'saved_button.dart';

class PostCard extends StatefulWidget {
  final dynamic
      post; // Can be either Post model or Map<String, dynamic> for backward compatibility
  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // For share icon animation
  double _shareIconScale = 1.0;

  // For share count
  int? _localShareCount;

  Future<void> _onShareTap(String postId) async {
    setState(() => _shareIconScale = 0.85);
    await Future.delayed(const Duration(milliseconds: 80));
    setState(() => _shareIconScale = 1.0);

    final link = 'https://xori.app/post/$postId';

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          link,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.black),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: link));
                          Navigator.of(context).pop('copy');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('Share',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        try {
                          await Share.share(link);
                        } catch (_) {}
                        Navigator.of(context).pop('share');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );

    if (result == 'copy') {
      // Already copied in the bottom sheet, just show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard!')),
      );
    }
    if (result == 'copy' || result == 'share') {
      if (currentUserId != null) {
        await PostService().addShare(postId, currentUserId!);
      }
    }
  }

  // For comment icon animation
  double _commentIconScale = 1.0;

  // For comment count
  int? _localCommentCount;

  void _showCommentSheet(BuildContext context, String postId) async {
    setState(() => _commentIconScale = 0.85);
    await Future.delayed(const Duration(milliseconds: 80));
    setState(() => _commentIconScale = 1.0);
    // Show the bottom sheet and listen for result
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CommentBottomSheetWithCount(
        postId: postId,
        onCountChanged: (count) {
          setState(() => _localCommentCount = count);
        },
      ),
    );
    // Optionally handle result
  }

  late String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _onLikeTap(bool liked) async {
    if (currentUserId == null) return;
    final isPostModel = widget.post is Post;
    final postId = isPostModel ? (widget.post as Post).id : widget.post["id"];
    try {
      if (liked) {
        await PostService().likePost(postId, currentUserId!);
      } else {
        await PostService().unlikePost(postId, currentUserId!);
      }
    } catch (e) {
      // Optionally show error
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPostModel = widget.post is Post;
    final String tappedUserUid =
        isPostModel ? (widget.post as Post).userId : widget.post["uid"] ?? '';
    final String postId =
        isPostModel ? (widget.post as Post).id : widget.post["id"];

    final List<Widget> children = [];

    // Header
    children.add(
      ListTile(
        leading: GestureDetector(
          onTap: () => _handleProfileTap(context, tappedUserUid),
          child: CircleAvatar(
            radius: 23,
            backgroundImage: isPostModel
                ? (widget.post as Post).userPhotoUrl.isNotEmpty
                    ? NetworkImage((widget.post as Post).userPhotoUrl)
                    : const AssetImage('assets/images/profile1.png')
                        as ImageProvider
                : AssetImage(widget.post["profilePic"]),
          ),
        ),
        title: GestureDetector(
          onTap: () => _handleProfileTap(context, tappedUserUid),
          child: Text(
            isPostModel ? (widget.post as Post).username : widget.post["name"],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: Text(isPostModel
            ? _formatTimestamp((widget.post as Post).createdAt.toDate())
            : widget.post["time"]),
        trailing: SavedButton(postId: postId, size: 20),
      ),
    );

    // Post Image/Media
    if (isPostModel && (widget.post as Post).mediaUrls.isNotEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.network(
              (widget.post as Post).mediaUrls.first,
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
            child: Image.asset(widget.post["postImage"], fit: BoxFit.cover),
          ),
        ),
      );
    }

    // Caption
    children.add(
      Padding(
        padding: EdgeInsets.only(top: 12.0, left: 12, right: 12),
        child: Text(
          isPostModel ? (widget.post as Post).caption : widget.post["caption"],
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
            // Like button with burst effect
            StreamBuilder<int>(
              stream: PostService().getLikeCount(postId),
              builder: (context, likeCountSnapshot) {
                final int likeCount = likeCountSnapshot.data ?? 0;
                return StreamBuilder<bool>(
                  stream: currentUserId == null
                      ? null
                      : PostService().isPostLikedByUser(postId, currentUserId!),
                  builder: (context, isLikedSnapshot) {
                    final bool isLiked = isLikedSnapshot.data ?? false;
                    return AppLikeButton(
                      isLiked: isLiked,
                      likeCount: likeCount,
                      onTap: (liked) async {
                        await _onLikeTap(liked);
                      },
                      size: 28,
                      borderColor: AppColors.textDark,
                      likeCountColor: AppColors.textDark,
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 10),
            // Comments
            _CommentIconWithCount(
              postId: postId,
              initialCount: isPostModel
                  ? (widget.post as Post).commentCount
                  : int.tryParse(widget.post["comments"].toString()) ?? 0,
              localCount: _localCommentCount,
              iconScale: _commentIconScale,
              onTap: () => _showCommentSheet(context, postId),
            ),

            const SizedBox(width: 10),

            _ShareIconWithCount(
              postId: postId,
              iconScale: _shareIconScale,
              onTap: () => _onShareTap(postId),
              localCount: _localShareCount,
              initialCount: isPostModel
                  ? (widget.post as Post).shareCount
                  : int.tryParse(widget.post["shares"].toString()) ?? 0,
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
      // Always navigate to navwrapper if not already there
      if (Get.currentRoute != AppRoutes.navwrapper) {
        Get.toNamed(AppRoutes.navwrapper)?.then((_) {
          // After navigation, switch to profile tab
          Future.delayed(Duration.zero, () {
            final navController = Get.find<NavbarWrapperController>();
            navController.changeTab(4);
          });
        });
      } else {
        // Already on navwrapper, just switch tab
        final navController = Get.find<NavbarWrapperController>();
        navController.changeTab(4);
      }
    } else {
      Get.toNamed(AppRoutes.xoriUserProfile,
          parameters: {'uid': tappedUserUid});
    }
  }
}

// Standalone widget for animated comment icon and count
class _CommentIconWithCount extends StatefulWidget {
  final String postId;
  final int initialCount;
  final int? localCount;
  final double iconScale;
  final VoidCallback onTap;
  const _CommentIconWithCount({
    required this.postId,
    required this.initialCount,
    required this.localCount,
    required this.iconScale,
    required this.onTap,
  });
  @override
  State<_CommentIconWithCount> createState() => _CommentIconWithCountState();
}

class _CommentIconWithCountState extends State<_CommentIconWithCount> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.iconScale,
        duration: const Duration(milliseconds: 80),
        child: Row(
          children: [
            SvgPicture.asset(
              AppAssets.comment,
              height: 19,
              width: 19,
              color: AppColors.textDark,
            ),
            const SizedBox(width: 4),
            StreamBuilder<int>(
              stream: _commentCountStream(widget.postId),
              builder: (context, snapshot) {
                final count =
                    widget.localCount ?? snapshot.data ?? widget.initialCount;
                return Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Stream comment count from Firestore
  Stream<int> _commentCountStream(String postId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snap) => snap.size);
  }
}

// Bottom sheet with callback for comment count changes
class _CommentBottomSheetWithCount extends StatefulWidget {
  final String postId;
  final ValueChanged<int> onCountChanged;
  const _CommentBottomSheetWithCount(
      {required this.postId, required this.onCountChanged});
  @override
  State<_CommentBottomSheetWithCount> createState() =>
      _CommentBottomSheetWithCountState();
}

class _CommentBottomSheetWithCountState
    extends State<_CommentBottomSheetWithCount> {
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    // Listen to comment count
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .snapshots()
        .listen((snap) {
      setState(() {
        _commentCount = snap.size;
      });
      widget.onCountChanged(_commentCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommentBottomSheet(postId: widget.postId);
  }
}

// Animated share icon with live count
class _ShareIconWithCount extends StatefulWidget {
  final String postId;
  final double iconScale;
  final VoidCallback onTap;
  final int? localCount;
  final int initialCount;
  const _ShareIconWithCount({
    required this.postId,
    required this.iconScale,
    required this.onTap,
    required this.localCount,
    required this.initialCount,
  });
  @override
  State<_ShareIconWithCount> createState() => _ShareIconWithCountState();
}

class _ShareIconWithCountState extends State<_ShareIconWithCount> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.iconScale,
        duration: const Duration(milliseconds: 80),
        child: Row(
          children: [
            SvgPicture.asset(
              AppAssets.share,
              height: 24,
              width: 24,
              color: AppColors.textDark,
            ),
            const SizedBox(width: 4),
            StreamBuilder<int>(
              stream: PostService().getShareCount(widget.postId),
              builder: (context, snapshot) {
                final count =
                    widget.localCount ?? snapshot.data ?? widget.initialCount;
                return Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
