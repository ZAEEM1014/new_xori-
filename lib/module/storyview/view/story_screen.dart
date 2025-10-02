import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/story_controller.dart';


class StoryViewScreen extends GetView<StoryController> {
  final Map<String, dynamic> status;
  const StoryViewScreen({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.startProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return GestureDetector(
      onLongPress: controller.pauseProgress,
      onLongPressUp: controller.resumeProgress,
      onTap: () => Get.back(), // tap closes
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Story Image
            Positioned.fill(
              child: Image.asset(
                status['image'] as String? ?? '',
                fit: BoxFit.cover,
              ),
            ),

            // Progress Bar
            Positioned(
              top: 40,
              left: 8,
              right: 8,
              child: Obx(() => LinearProgressIndicator(
                value: controller.progress.value,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              )),
            ),

            // Top Bar (Profile + Close)
            Positioned(
              top: 50,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage(status['image'] as String? ?? ''),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status['name'] as String? ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Bottom Input + Reaction
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
                  const Icon(Icons.favorite_border, color: Colors.yellow, size: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
