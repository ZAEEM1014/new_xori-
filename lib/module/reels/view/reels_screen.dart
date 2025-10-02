import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:xori/constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../controller/reels_controller.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReelController controller = Get.put(ReelController());
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Reels", style: TextStyle(color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      body: Stack(
        children: [
          // Background Reel Image
          SizedBox.expand(
            child: Image.asset(
              AppAssets.reelsbg, // replace with your reel bg
              fit: BoxFit.cover,
            ),
          ),

          // Right Side Icons
          Positioned(
            right: 15,
            bottom: 150,
            child: Column(
              children: [
                // Home Heart Button
                Obx(
                  () => GestureDetector(
                    onTap: controller.toggleHomeLike,
                    child: ShaderMask(
                      shaderCallback: (bounds) => controller.isHomeLiked.value
                          ? AppColors.appGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            )
                          : const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                      blendMode: BlendMode.srcIn,
                      child: SvgPicture.asset(
                        AppAssets.homeheart,
                        height: 32,
                        width: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Obx(
                  () => Text(
                    controller.homeLikeCount.value.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                // Comment Icon
                Column(
                  children: [
                    SvgPicture.asset(
                      AppAssets.comment,
                      height: 32,
                      width: 32,
                      color: AppColors.white,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "6000",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Share Icon
                Column(
                  children: [
                    SvgPicture.asset(
                      AppAssets.share,
                      height: 32,
                      width: 32,
                      color: AppColors.white,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "7000",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Favourite Heart Button
                Obx(
                  () => GestureDetector(
                    onTap: controller.toggleFavouriteLike,
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          controller.isFavouriteLiked.value
                          ? AppColors.appGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            )
                          : const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                      blendMode: BlendMode.srcIn,
                      child: SvgPicture.asset(
                        AppAssets.favourite,
                        height: 32,
                        width: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Obx(
                  () => Text(
                    controller.favouriteLikeCount.value.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Bottom User + Caption
          Positioned(
            left: 15,
            right: 15,
            top: 620,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image
                      const CircleAvatar(
                        radius: 23,
                        backgroundImage: AssetImage(AppAssets.profilePic),
                      ),
                      const SizedBox(width: 10),
                      // Name + Caption
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SizedBox(height: 8),
                            Text(
                              "Esther",
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "8 min ago",
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(right: 40.0, left: 8),
                  child: Text(
                    "If you could live anywhere in the world, where would you pick?",
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
