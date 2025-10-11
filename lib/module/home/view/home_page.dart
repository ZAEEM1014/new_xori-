import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../../../widgets/post_card.dart';
import '../../../constants/app_assets.dart';
import '../../../widgets/post_shimmer.dart';
import '../../../routes/app_routes.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final topBar = controller.topBar;
      final statuses = controller.statuses;

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // 🔹 Top Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) {
                          final String? profilePic =
                              topBar['profilePic'] as String?;
                          if (profilePic != null && profilePic.isNotEmpty) {
                            final bool isNetwork =
                                profilePic.startsWith('http');
                            return CircleAvatar(
                              radius: 24,
                              backgroundImage: isNetwork
                                  ? NetworkImage(profilePic)
                                  : AssetImage(profilePic) as ImageProvider,
                              backgroundColor: Colors.grey[200],
                            );
                          } else {
                            return const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topBar['greeting'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            topBar['name'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ...(topBar['icons'] as List<dynamic>? ?? []).map((icon) {
                        final String path = icon['path'] as String? ?? '';
                        final bool isSend = icon['isSend'] == true;
                        final double height = isSend
                            ? 32.0
                            : ((icon['height'] as num?)?.toDouble() ?? 24.0);
                        final double width = isSend
                            ? 32.0
                            : ((icon['width'] as num?)?.toDouble() ?? 24.0);
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: GestureDetector(
                            onTap: isSend
                                ? () => Get.toNamed(AppRoutes.chatList)
                                : (path == AppAssets.homeheart)
                                    ? () => Get.toNamed(AppRoutes.notifications)
                                    : null,
                            child: SvgPicture.asset(
                              path,
                              height: height,
                              width: width,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 🔹 Stories Section
                SizedBox(
                  height: 90,
                  child: Obx(() {
                    if (controller.isLoadingStories.value &&
                        controller.statuses.isEmpty) {
                      // Show loading indicators for stories
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5, // Show 5 loading placeholders
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 58,
                                height: 69,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Container(
                                  width: 40,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (controller.storiesErrorMessage.value.isNotEmpty) {
                      return Center(
                        child: GestureDetector(
                          onTap: controller.refreshStories,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to retry',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: statuses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final status = statuses[index];
                        final bool isAdd = status['isAdd'] == 'true';
                        return GestureDetector(
                          onTap: () {
                            if (isAdd) {
                              Get.toNamed('/addStory');
                            } else {
                              // Use the controller's story handling method
                              controller.handleStoryTap(status);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 58,
                                height: 69,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isAdd ? Colors.grey : Colors.amber,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: isAdd
                                    ? const Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.grey,
                                          size: 28,
                                        ),
                                      )
                                    : Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: status['image'] != null &&
                                                  (status['image'] as String)
                                                      .isNotEmpty
                                              ? Image.network(
                                                  status['image'] as String,
                                                  fit: BoxFit.cover,
                                                  width: 50,
                                                  height: 59,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      width: 50,
                                                      height: 59,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                          Icons.person,
                                                          color: Colors.grey),
                                                    );
                                                  },
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Container(
                                                      width: 50,
                                                      height: 59,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  width: 50,
                                                  height: 59,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                      Icons.person,
                                                      color: Colors.grey),
                                                ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: SizedBox(
                                  width: 58,
                                  child: Text(
                                    status['name'] as String? ?? '',
                                    style: const TextStyle(fontSize: 13),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 10),
                // 🔹 Posts Section
                Obx(
                  () {
                    if (controller.isLoading.value) {
                      // Show shimmer effect for posts section only
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 6,
                        itemBuilder: (context, index) => const PostShimmer(),
                      );
                    }
                    if (controller.errorMessage.value.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              controller.errorMessage.value,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: controller.refreshPosts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (controller.posts.isEmpty) {
                      return const Center(
                        child: Text(
                          'No posts available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: controller.refreshPosts,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.posts.length > 10
                            ? 10
                            : controller.posts.length,
                        itemBuilder: (context, index) {
                          final post = controller.posts[index];
                          // Add extra space after the last post
                          if (index ==
                              (controller.posts.length > 10
                                      ? 10
                                      : controller.posts.length) -
                                  1) {
                            return Column(
                              children: [
                                PostCard(post: post),
                                const SizedBox(
                                    height:
                                        80), // Extra space for navbar overlap
                              ],
                            );
                          }
                          return PostCard(post: post);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
