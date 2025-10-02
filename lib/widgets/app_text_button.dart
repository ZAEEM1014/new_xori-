import 'package:flutter/material.dart';

class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final double? minHeight;

  const AppTextButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.textStyle,
    this.padding,
    this.minWidth,
    this.minHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: padding ?? EdgeInsets.zero,
        minimumSize: Size(minWidth ?? 0, minHeight ?? 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: textStyle ?? const TextStyle(fontSize: 14),
      ),
    );
  }
}
