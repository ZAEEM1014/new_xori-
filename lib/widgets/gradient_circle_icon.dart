import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GradientCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final List<Color>? gradientColors;

  const GradientCircleIcon({
    Key? key,
    required this.icon,
    this.size = 28,
    this.iconSize = 16,
    this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors ?? AppColors.appGradient.colors,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
