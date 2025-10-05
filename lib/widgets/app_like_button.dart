import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import '../constants/app_colors.dart';

class AppLikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final ValueChanged<bool> onTap;
  final double size;
  final Color? likeCountColor;
  final Color? borderColor;

  const AppLikeButton({
    Key? key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    this.size = 32.0,
    this.likeCountColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LikeButton(
      size: size,
      isLiked: isLiked,
      likeCount: likeCount,
      circleColor: const CircleColor(
        start: Color(0xFFFFEF12),
        end: Color(0xFFFFEF12),
      ),
      bubblesColor: BubblesColor(
        dotPrimaryColor: AppColors.appGradient.colors.first,
        dotSecondaryColor: AppColors.appGradient.colors.last,
      ),
      likeBuilder: (bool liked) {
        if (liked) {
          return ShaderMask(
            shaderCallback: (Rect bounds) {
              return AppColors.appGradient.createShader(bounds);
            },
            child: Icon(
              Icons.favorite,
              color: Colors.white,
              size: size,
            ),
          );
        } else {
          return Icon(
            Icons.favorite_border,
            color: borderColor ?? Colors.grey,
            size: size,
          );
        }
      },
      likeCountPadding: const EdgeInsets.only(left: 6),
      countBuilder: (int? count, bool liked, String text) {
        return Text(
          text,
          style: TextStyle(
            color: likeCountColor ?? Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        );
      },
      onTap: (bool liked) async {
        onTap(!liked);
        return !liked;
      },
    );
  }
}
