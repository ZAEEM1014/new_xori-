import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../services/reel_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../models/reel_model.dart';

enum ContentType { video, image }

class ReelController extends GetxController {
  final ReelService _reelService = ReelService();

  // Reactive variables for reels
  var reels = <Reel>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Video controllers and states for individual reels
  var videoControllers = <String, VideoPlayerController>{}.obs;
  var videoLoadingStates = <String, bool>{}.obs;
  var videoErrorStates = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadReels();
  }

  /// Load reels from Firestore with proper error handling
  Future<void> loadReels() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final fetchedReels = await _reelService.getAllReels();
      reels.value = fetchedReels;

      // Initialize video states
      for (final reel in fetchedReels) {
        videoLoadingStates[reel.id] = true;
        videoErrorStates[reel.id] = '';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load reels: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Stream reels from Firestore for real-time updates
  Stream<List<Reel>> get reelsStream {
    try {
      return _reelService.streamAllReels().map((reelsList) {
        // Initialize video states for new reels
        for (final reel in reelsList) {
          if (!videoLoadingStates.containsKey(reel.id)) {
            videoLoadingStates[reel.id] = true;
            videoErrorStates[reel.id] = '';
          }
        }
        return reelsList;
      });
    } catch (e) {
      // Schedule error update after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        hasError.value = true;
        errorMessage.value = 'Failed to stream reels: ${e.toString()}';
      });
      return Stream.value([]);
    }
  }

  /// Check if URL is a supported video format
  bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'];
    final lowercaseUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowercaseUrl.contains(ext));
  }

  /// Check if URL is an image format
  bool _isImageUrl(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final lowercaseUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowercaseUrl.contains(ext));
  }

  /// Determine content type from URL
  ContentType getContentType(String url) {
    if (_isVideoUrl(url)) {
      return ContentType.video;
    } else if (_isImageUrl(url)) {
      return ContentType.image;
    } else {
      // Default to video for unknown extensions
      return ContentType.video;
    }
  }

  /// Initialize video player for a specific reel with fallback URL attempts
  Future<void> initializeVideoPlayer(String reelId, String videoUrl) async {
    try {
      // Set loading state
      videoLoadingStates[reelId] = true;
      videoErrorStates[reelId] = '';

      // Validate URL first
      if (videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      // Check if it's actually a video URL
      if (_isImageUrl(videoUrl)) {
        throw Exception('URL appears to be an image, not a video');
      }

      // Dispose existing controller if any
      if (videoControllers.containsKey(reelId)) {
        await videoControllers[reelId]?.dispose();
        videoControllers.remove(reelId);
      }

      // Try different URL formats for maximum compatibility
      final urlsToTry = _generateFallbackUrls(videoUrl);

      for (int i = 0; i < urlsToTry.length; i++) {
        final currentUrl = urlsToTry[i];
        print(
            'Attempting video URL ${i + 1}/${urlsToTry.length} for reel $reelId: $currentUrl');

        try {
          final controller = await _tryInitializeController(currentUrl);
          videoControllers[reelId] = controller;

          // If we get here, initialization was successful
          videoLoadingStates[reelId] = false;
          print(
              'Successfully initialized video for reel $reelId with URL: $currentUrl');
          return;
        } catch (e) {
          print('Failed to initialize with URL $currentUrl: $e');

          // If this is the last URL to try, throw the error
          if (i == urlsToTry.length - 1) {
            throw e;
          }

          // Continue to next URL
          continue;
        }
      }
    } catch (e) {
      // Handle error
      videoLoadingStates[reelId] = false;

      String errorMessage = _getVideoErrorMessage(e.toString());
      videoErrorStates[reelId] = errorMessage;

      // Remove failed controller
      if (videoControllers.containsKey(reelId)) {
        await videoControllers[reelId]?.dispose();
        videoControllers.remove(reelId);
      }
    }
  }

  /// Generate multiple fallback URLs with different quality/format settings
  List<String> _generateFallbackUrls(String originalUrl) {
    List<String> urls = [];

    // Primary: Conservative settings for maximum compatibility
    urls.add(CloudinaryService.makeVideoUrlFlutterCompatible(originalUrl));

    // If it's already a Cloudinary URL, try variations
    if (originalUrl.contains('cloudinary.com')) {
      try {
        final uri = Uri.parse(originalUrl);
        final pathSegments = uri.pathSegments;

        if (pathSegments.length >= 4) {
          final cloudName = pathSegments[0];
          final publicIdWithVersion = pathSegments.skip(3).join('/');

          String publicId = publicIdWithVersion;
          if (publicId.startsWith('v') && publicId.contains('/')) {
            final parts = publicId.split('/');
            if (parts.length > 1 && RegExp(r'^v\d+$').hasMatch(parts[0])) {
              publicId = parts.skip(1).join('/');
            }
          }

          if (publicId.contains('.')) {
            publicId = publicId.substring(0, publicId.lastIndexOf('.'));
          }

          // Fallback 1: Even more conservative (480p, lower bitrate)
          urls.add(
              'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,vc_h264,ac_aac,br_800k,w_480,h_640,c_limit,q_auto:low/$publicId.mp4');

          // Fallback 2: Basic MP4 without size restrictions
          urls.add(
              'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,vc_h264,ac_aac/$publicId.mp4');

          // Fallback 3: Original URL as last resort
          urls.add(originalUrl);
        }
      } catch (e) {
        print('Error generating fallback URLs: $e');
      }
    } else {
      // For non-Cloudinary URLs, just try the original
      urls.add(originalUrl);
    }

    return urls;
  }

  /// Try to initialize a video controller with the given URL
  Future<VideoPlayerController> _tryInitializeController(
      String videoUrl) async {
    final uri = Uri.parse(videoUrl);
    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    // Initialize with timeout
    await controller.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Video initialization timeout');
      },
    );

    // Set looping and volume
    await controller.setLooping(true);
    await controller.setVolume(1.0);

    // Verify initialization
    if (!controller.value.isInitialized || controller.value.hasError) {
      throw Exception('Video failed to initialize properly');
    }

    return controller;
  }

  /// Get user-friendly error message
  String _getVideoErrorMessage(String? errorDescription) {
    if (errorDescription == null || errorDescription.isEmpty) {
      return 'Unknown video error occurred';
    }

    final error = errorDescription.toLowerCase();

    if (error.contains('exoplaybackexception') ||
        error.contains('mediacodevideorenderer')) {
      return 'Video format not supported on this device';
    } else if (error.contains('timeout')) {
      return 'Video loading timed out. Check your internet connection';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network error. Please check your internet connection';
    } else if (error.contains('format') || error.contains('codec')) {
      return 'Video format not supported';
    } else if (error.contains('permission')) {
      return 'Permission denied to access video';
    } else if (error.contains('not found') || error.contains('404')) {
      return 'Video not found or URL is invalid';
    } else {
      return 'Failed to load video. Please try again';
    }
  }

  /// Play video for a specific reel
  Future<void> playVideo(String reelId) async {
    final controller = videoControllers[reelId];
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
    }
  }

  /// Pause video for a specific reel
  Future<void> pauseVideo(String reelId) async {
    final controller = videoControllers[reelId];
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
    }
  }

  /// Get video controller for a specific reel
  VideoPlayerController? getVideoController(String reelId) {
    return videoControllers[reelId];
  }

  /// Check if video is loading for a specific reel
  bool isVideoLoading(String reelId) {
    return videoLoadingStates[reelId] ?? true;
  }

  /// Check if video has error for a specific reel
  String getVideoError(String reelId) {
    return videoErrorStates[reelId] ?? '';
  }

  /// Check if video is initialized for a specific reel
  bool isVideoInitialized(String reelId) {
    final controller = videoControllers[reelId];
    return controller?.value.isInitialized ?? false;
  }

  /// Retry video initialization for a specific reel
  Future<void> retryVideoInitialization(String reelId, String videoUrl) async {
    // Clear existing error
    videoErrorStates[reelId] = '';

    // Reinitialize video player
    await initializeVideoPlayer(reelId, videoUrl);
  }

  /// Like/unlike a reel
  Future<void> toggleReelLike(
      String reelId, String userId, bool isCurrentlyLiked) async {
    try {
      if (isCurrentlyLiked) {
        await _reelService.unlikeReel(reelId, userId);
      } else {
        await _reelService.likeReel(reelId, userId);
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      Get.snackbar('Error', 'Failed to update like status');
    }
  }

  /// Refresh reels
  Future<void> refreshReels() async {
    // Dispose all video controllers before refresh
    await disposeAllVideoControllers();
    await loadReels();
  }

  /// Dispose all video controllers
  Future<void> disposeAllVideoControllers() async {
    for (final controller in videoControllers.values) {
      await controller.dispose();
    }
    videoControllers.clear();
    videoLoadingStates.clear();
    videoErrorStates.clear();
  }

  /// Pause all videos
  Future<void> pauseAllVideos() async {
    try {
      for (final controller in videoControllers.values) {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          await controller.pause();
        }
      }
    } catch (e) {
      debugPrint('Error pausing all videos: $e');
    }
  }

  /// Play video at specific index
  Future<void> playVideoAtIndex(int index) async {
    try {
      if (index >= 0 && index < reels.length) {
        final reel = reels[index];
        await playVideo(reel.id);
      }
    } catch (e) {
      debugPrint('Error playing video at index $index: $e');
    }
  }

  /// Initialize and play video in one call
  Future<void> initializeAndPlayVideo(String reelId, String videoUrl) async {
    try {
      await initializeVideoPlayer(reelId, videoUrl);
      await playVideo(reelId);
    } catch (e) {
      debugPrint('Error initializing and playing video $reelId: $e');
    }
  }

  /// Preload video for better performance
  Future<void> preloadVideo(String reelId, String videoUrl) async {
    try {
      if (!videoControllers.containsKey(reelId)) {
        await initializeVideoPlayer(reelId, videoUrl);
      }
    } catch (e) {
      debugPrint('Error preloading video $reelId: $e');
    }
  }

  @override
  void onClose() {
    // Dispose all video controllers when controller is closed
    disposeAllVideoControllers();
    super.onClose();
  }

  /// --- Legacy Heart functionality (kept for compatibility) ---
  var isHomeLiked = false.obs;
  var homeLikeCount = 5000.obs;

  void toggleHomeLike() {
    if (isHomeLiked.value) {
      isHomeLiked.value = false;
      homeLikeCount.value--;
    } else {
      isHomeLiked.value = true;
      homeLikeCount.value++;
    }
  }

  /// --- Favourite Heart ---
  var isFavouriteLiked = false.obs;
  var favouriteLikeCount = 2000.obs;

  void toggleFavouriteLike() {
    if (isFavouriteLiked.value) {
      isFavouriteLiked.value = false;
      favouriteLikeCount.value--;
    } else {
      isFavouriteLiked.value = true;
      favouriteLikeCount.value++;
    }
  }

  /// Toggle like for a specific reel
  Future<void> toggleLike(String reelId) async {
    try {
      // Find the reel in the list
      final reelIndex = reels.indexWhere((reel) => reel.id == reelId);
      if (reelIndex != -1) {
        // For now, just update the UI - implement Firebase logic later
        // In a real implementation, you would update Firestore here
        debugPrint('Toggle like for reel: $reelId');
        // This would typically involve:
        // 1. Check if current user has liked this reel
        // 2. Update Firestore document
        // 3. Update local state
        // For now, just acknowledge the action
      }
    } catch (e) {
      debugPrint('Error toggling like for reel $reelId: $e');
    }
  }
}
