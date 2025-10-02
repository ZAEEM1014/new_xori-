import 'dart:async';
import 'package:get/get.dart';

class StoryController extends GetxController {
  var progress = 0.0.obs;
  Timer? _timer;
  bool isPaused = false;

  final int durationInSeconds = 10; // 30 sec story

  void startProgress() {
    progress.value = 0.0;
    const tick = Duration(milliseconds: 100);
    _timer = Timer.periodic(tick, (timer) {
      if (!isPaused) {
        progress.value += tick.inMilliseconds / (durationInSeconds * 1000);
        if (progress.value >= 1.0) {
          timer.cancel();
          Get.back(); // Auto close when time ends
        }
      }
    });
  }

  void pauseProgress() {
    isPaused = true;
  }

  void resumeProgress() {
    isPaused = false;
  }

  void stopProgress() {
    _timer?.cancel();
  }

  @override
  void onClose() {
    stopProgress();
    super.onClose();
  }
}
