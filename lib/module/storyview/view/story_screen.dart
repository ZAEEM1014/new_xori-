import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/story_controller.dart';
import '../../../constants/app_colors.dart';

class StoryViewScreen extends StatefulWidget {
  @override
  _StoryViewScreenState createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late PageController _pageController;
  late StoryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<StoryController>();
    _pageController =
        PageController(initialPage: controller.currentIndex.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.stories.isEmpty) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: Text('Story not found',
                  style: TextStyle(color: Colors.white))),
        );
      }
      // Sync page controller with currentIndex
      if (_pageController.hasClients &&
          controller.currentIndex.value != _pageController.page?.round()) {
        _pageController.jumpToPage(controller.currentIndex.value);
      }
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.localPosition.dx < width / 3) {
              if (controller.currentIndex.value > 0) {
                controller.previousStory();
                _pageController.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut);
              } else {
                Get.back();
              }
            } else if (details.localPosition.dx > 2 * width / 3) {
              if (controller.currentIndex.value <
                  controller.stories.length - 1) {
                controller.nextStory();
                _pageController.nextPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut);
              } else {
                Get.back();
              }
            }
          },
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.stories.length,
            onPageChanged: (index) => controller.currentIndex.value = index,
            itemBuilder: (context, index) {
              final story = controller.stories[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      story.storyUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.white)),
                    ),
                  ),
                  // Transparent Top Bar (no gradient)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                NetworkImage(story.userProfileImage),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            story.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeAgo(story.postedAt),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              SystemChrome.setEnabledSystemUIMode(
                                  SystemUiMode.edgeToEdge);
                              Get.back();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Gradient Progress Bar
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: List.generate(controller.stories.length, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: i <= controller.currentIndex.value
                                  ? AppColors.appGradient
                                  : null,
                              color: i <= controller.currentIndex.value
                                  ? null
                                  : Colors.white30,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Bottom message input and heart
                  Positioned(
                    bottom: 20,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white38),
                            ),
                            child: const TextField(
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Type a Message",
                                hintStyle: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.favorite_border,
                            color: Color(0xFFFFEF12), size: 30),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
