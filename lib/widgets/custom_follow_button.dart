import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../models/follow_user_model.dart';
import '../services/follow_service.dart';

class CustomFollowButton extends StatelessWidget {
  final String currentUserId;
  final FollowUser targetUser;
  final VoidCallback? onFollowToggled;
  final double height;
  final double? width;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;

  const CustomFollowButton({
    Key? key,
    required this.currentUserId,
    required this.targetUser,
    this.onFollowToggled,
    this.height = 36,
    this.width,
    this.borderRadius = 18,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FollowService followService = FollowService();

    return StreamBuilder<bool>(
      stream: followService.isFollowingStream(currentUserId, targetUser.userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          width: width,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: () async {
                try {
                  await followService.toggleFollow(currentUserId, targetUser);
                  if (onFollowToggled != null) {
                    onFollowToggled!();
                  }
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to update follow status',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: Container(
                height: height,
                width: width,
                padding: padding ??
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isFollowing ? null : AppColors.appGradient,
                  color: isFollowing ? const Color(0xFFE8E8E8) : null,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: !isFollowing
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      color: isFollowing ? Colors.black87 : Colors.white,
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
