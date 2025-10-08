import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/story_controller.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/app_like_button.dart';
import '../../../widgets/story_comment_bottom_sheet.dart';

class StoryViewScreen extends StatefulWidget {
  @override
  _StoryViewScreenState createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late StoryController controller;
  late List<AnimationController> _progressControllers;
  late TextEditingController _commentController;
  bool _isHolding = false;
  static const storyDuration = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    controller = Get.find<StoryController>();
    _commentController = TextEditingController();
    _pageController =
        PageController(initialPage: controller.currentIndex.value);
    _initProgressControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  void _initProgressControllers() {
    _progressControllers = List.generate(
      controller.stories.length,
      (i) => AnimationController(
        vsync: this,
        duration: storyDuration,
      ),
    );
    // Start the current story's animation
    if (_progressControllers.isNotEmpty) {
      _progressControllers[controller.currentIndex.value].forward();
      _progressControllers[controller.currentIndex.value]
          .addStatusListener(_handleAnimationStatus);
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_isHolding) {
      _goToNextStory();
    }
  }

  void _goToNextStory() {
    if (controller.currentIndex.value < controller.stories.length - 1) {
      _progressControllers[controller.currentIndex.value]
          .removeStatusListener(_handleAnimationStatus);
      controller.nextStory();
      _pageController.nextPage(
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      _progressControllers[controller.currentIndex.value].forward(from: 0);
      _progressControllers[controller.currentIndex.value]
          .addStatusListener(_handleAnimationStatus);
    } else {
      Get.back();
    }
  }

  void _goToPreviousStory() {
    if (controller.currentIndex.value > 0) {
      _progressControllers[controller.currentIndex.value]
          .removeStatusListener(_handleAnimationStatus);
      controller.previousStory();
      _pageController.previousPage(
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      _progressControllers[controller.currentIndex.value].forward(from: 0);
      _progressControllers[controller.currentIndex.value]
          .addStatusListener(_handleAnimationStatus);
    } else {
      Get.back();
    }
  }

  void _pauseProgress() {
    _isHolding = true;
    _progressControllers[controller.currentIndex.value].stop();
  }

  void _resumeProgress() {
    _isHolding = false;
    _progressControllers[controller.currentIndex.value].forward();
  }

  @override
  void dispose() {
    for (final c in _progressControllers) {
      c.dispose();
    }
    _pageController.dispose();
    _commentController.dispose();
    // Restore system bar for other screens
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      // If stories changed, re-init progress controllers
      if (_progressControllers.length != controller.stories.length) {
        for (final c in _progressControllers) {
          c.dispose();
        }
        _initProgressControllers();
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
              _goToPreviousStory();
            } else if (details.localPosition.dx > 2 * width / 3) {
              _goToNextStory();
            }
          },
          onLongPressStart: (_) => _pauseProgress(),
          onLongPressEnd: (_) => _resumeProgress(),
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.stories.length,
            onPageChanged: (index) {
              // Pause previous, start new
              for (final c in _progressControllers) {
                c.stop();
                c.removeStatusListener(_handleAnimationStatus);
              }
              controller.currentIndex.value = index;
              _progressControllers[index].forward(from: 0);
              _progressControllers[index]
                  .addStatusListener(_handleAnimationStatus);
            },
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
                  // Animated Gradient Progress Bar (thinner)
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: List.generate(controller.stories.length, (i) {
                        return Expanded(
                          child: AnimatedBuilder(
                            animation: _progressControllers[i],
                            builder: (context, child) {
                              double value = 0;
                              if (i < controller.currentIndex.value) {
                                value = 1;
                              } else if (i == controller.currentIndex.value) {
                                value = _progressControllers[i].value;
                              }
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1),
                                  color: Colors.white.withOpacity(
                                      0.35), // Semi-transparent white background
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(1),
                                        gradient: AppColors.appGradient,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  // Bottom message input and like button (responsive)

                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      bottom: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Show comment bottom sheet
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        StoryCommentBottomSheet(
                                      storyId: story.storyId,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: Colors.white38),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        "Type a Message",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      const Spacer(),
                                      Obx(() {
                                        final commentCount =
                                            controller.currentStoryCommentCount;
                                        if (commentCount > 0) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: AppColors.appGradient,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$commentCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Like button with gradient count color
                            Obx(() => AppLikeButton(
                                  isLiked: controller.isCurrentStoryLiked,
                                  likeCount: controller.currentStoryLikeCount,
                                  onTap: (liked) {
                                    controller.toggleLike(story.storyId);
                                  },
                                  size: 32,
                                  borderColor: Colors.white,
                                  likeCountColor: Colors.white,
                                )),
                          ],
                        ),
                      ),
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
