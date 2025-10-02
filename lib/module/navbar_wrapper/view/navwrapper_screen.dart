import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xori/module/add_post/view/add_post_screen.dart';
import 'package:xori/module/search/view/search_screen.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../../home/view/home_page.dart';
import '../../profile/view/profile_screen.dart';
import '../../reels/view/reels_screen.dart';
import '../controller/navwrapper_controller.dart';

class NavbarWrapper extends GetView<NavbarWrapperController> {
  const NavbarWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomePage(),
      SearchScreen(),
      AddPostScreen(),
      ReelsScreen(),

      ProfileScreen(),
    ];

    return Obx(
      () => Scaffold(
        body: Stack(
          children: [
            // Main page content
            pages[controller.selectedIndex.value],

            // Sticky floating navbar
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: CustomNavbar(
                currentIndex: controller.selectedIndex.value,
                onTap: controller.changeTab,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- DEMO SCREENS ---------------- ///

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange,
      child: const Center(
        child: Text(
          "Add Screen",
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
