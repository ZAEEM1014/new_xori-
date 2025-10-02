import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final ValueChanged<String>? onChanged;
  final int? minLines;
  final int? maxLines;

  const AppTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.borderRadius = 8,
    this.margin,
    this.padding,
    this.onChanged,
    this.minLines,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !isPasswordVisible,
        onChanged: onChanged,
        // Only allow multiline for non-password fields
        minLines: isPassword ? 1 : minLines,
        maxLines: isPassword ? 1 : maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textLight),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: SvgPicture.asset(
                    AppAssets.eyeIcon,
                    color: AppColors.textLight,
                    width: 24,
                    height: 24,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
        ),
      ),
    );
  }
}
