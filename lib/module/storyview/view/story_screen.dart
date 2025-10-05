import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/story_controller.dart';

class StoryViewScreen extends GetView<StoryController> {
  @override
  Widget build(BuildContext context) {
    // Make the story view immersive (full screen, no system bar)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      final story = controller.story.value;
      if (story == null) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: Text('Story not found',
                  style: TextStyle(color: Colors.white))),
        );
      }
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                story.storyUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white)),
              ),
            ),
            Positioned(
              top: 40,
              left: 8,
              right: 8,
              child: LinearProgressIndicator(
                value: 1.0, // You can add your own progress logic
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Positioned(
              top: 50,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(story.userProfileImage),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                      color: Colors.yellow, size: 30),
                ],
              ),
            ),
          ],
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
