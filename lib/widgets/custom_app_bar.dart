import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onBack,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.black),
              onPressed: onBack,
            )
          : null,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      actions: actions,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
