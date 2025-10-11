import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../services/reel_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../models/reel_model.dart';
import '../../../models/reel_comment_model.dart';

enum ContentType { video, image }

class ReelController extends GetxController {
  final ReelService _reelService = ReelService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  // Reactive variables for reels
  var reels = <Reel>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Video controllers and states for individual reels
  var videoControllers = <String, VideoPlayerController>{}.obs;
  var videoLoadingStates = <String, bool>{}.obs;
  var videoErrorStates = <String, String>{}.obs;

  // OPTIMIZATION: Initialization lock to prevent concurrent inits
  final Map<String, Completer<void>> _initializationLocks = {};

  // OPTIMIZATION: Track current visible reel for smart preloading
  var currentVisibleReelIndex = 0.obs;

  // Like, comment, share, and save related observables
  var reelLikeStates = <String, bool>{}.obs;
  var reelLikeCounts = <String, int>{}.obs;
  var reelCommentCounts = <String, int>{}.obs;
  var reelShareCounts = <String, int>{}.obs;
  var reelSaveStates = <String, bool>{}.obs;

  // Video control states
  var isMuted = false.obs;
  var currentPlayingReelId = ''.obs;
  var videoPlayStates = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadReels();

    // OPTIMIZATION: Removed aggressive 30-second cleanup timer
    // Controllers now persist for smoother playback
  }

  /// Load reels from Firestore with proper error handling
  Future<void> loadReels() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      debugPrint('Starting to load reels...');
      final fetchedReels = await _reelService.getAllReels();
      debugPrint('Fetched ${fetchedReels.length} reels from Firestore');

      reels.value = fetchedReels;

      // OPTIMIZATION: Initialize states but don't set loading=true to prevent flicker
      for (final reel in fetchedReels) {
        videoLoadingStates[reel.id] = false;
        videoErrorStates[reel.id] = '';
        videoPlayStates[reel.id] = false;
        debugPrint('Reel loaded: ${reel.id} - ${reel.videoUrl}');
      }

      // Initialize like, comment, share, and save states
      _initializeInteractionData();

      debugPrint('Reels loading completed successfully');
    } catch (e) {
      debugPrint('Error loading reels: $e');
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
            videoLoadingStates[reel.id] = false;
            videoErrorStates[reel.id] = '';
            videoPlayStates[reel.id] = false;
          }
        }
        return reelsList;
      });
    } catch (e) {
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
      return ContentType.video;
    }
  }

  /// OPTIMIZATION: Initialize video player with lock mechanism to prevent concurrent inits
  Future<void> initializeVideoPlayer(String reelId, String videoUrl) async {
    // OPTIMIZATION: Check for existing lock - if initializing, wait for completion
    if (_initializationLocks.containsKey(reelId)) {
      await _initializationLocks[reelId]!.future;
      return;
    }

    // OPTIMIZATION: Create lock for this initialization
    final completer = Completer<void>();
    _initializationLocks[reelId] = completer;

    try {
      // OPTIMIZATION: If already initialized and working, don't reinitialize
      final existingController = videoControllers[reelId];
      if (existingController != null &&
          existingController.value.isInitialized &&
          !existingController.value.hasError) {
        completer.complete();
        _initializationLocks.remove(reelId);
        return;
      }

      // OPTIMIZATION: Smarter disposal - keep more controllers (5 instead of 2)
      // Only dispose controllers far from current view
      if (videoControllers.length >= 5) {
        final currentIndex = reels.indexWhere((reel) => reel.id == reelId);
        final controllersToDispose = <String>[];

        for (final controllerId in videoControllers.keys) {
          final controllerIndex =
              reels.indexWhere((reel) => reel.id == controllerId);
          // OPTIMIZATION: Keep controllers within 2 positions (previous 2 + current + next 2)
          if (controllerIndex != -1 &&
              (controllerIndex - currentIndex).abs() > 2) {
            controllersToDispose.add(controllerId);
          }
        }

        // Dispose far controllers
        for (final id in controllersToDispose) {
          await disposeVideoController(id);
        }
      }

      // Set loading state
      videoLoadingStates[reelId] = true;
      videoErrorStates[reelId] = '';

      // Validate URL first
      if (videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

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
        debugPrint(
            'Attempting video URL ${i + 1}/${urlsToTry.length} for reel $reelId: $currentUrl');

        try {
          final controller = await _tryInitializeController(currentUrl);
          videoControllers[reelId] = controller;

          // OPTIMIZATION: Mark as initialized immediately to prevent flicker
          videoLoadingStates[reelId] = false;
          debugPrint(
              'Successfully initialized video for reel $reelId with URL: $currentUrl');

          completer.complete();
          _initializationLocks.remove(reelId);
          return;
        } catch (e) {
          debugPrint('Failed to initialize with URL $currentUrl: $e');

          if (i == urlsToTry.length - 1) {
            throw e;
          }
          continue;
        }
      }
    } catch (e) {
      videoLoadingStates[reelId] = false;
      String errorMessage = _getVideoErrorMessage(e.toString());
      videoErrorStates[reelId] = errorMessage;

      if (videoControllers.containsKey(reelId)) {
        await videoControllers[reelId]?.dispose();
        videoControllers.remove(reelId);
      }

      completer.completeError(e);
      _initializationLocks.remove(reelId);
    }
  }

  /// Generate multiple fallback URLs with different quality/format settings
  List<String> _generateFallbackUrls(String originalUrl) {
    List<String> urls = [];

    urls.add(CloudinaryService.makeVideoUrlFlutterCompatible(originalUrl));

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

          urls.add(
              'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,vc_h264,ac_aac,br_800k,w_480,h_640,c_limit,q_auto:low/$publicId.mp4');
          urls.add(
              'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,vc_h264,ac_aac/$publicId.mp4');
          urls.add(originalUrl);
        }
      } catch (e) {
        debugPrint('Error generating fallback URLs: $e');
      }
    } else {
      urls.add(originalUrl);
    }

    return urls;
  }

  /// Try to initialize a video controller with the given URL
  Future<VideoPlayerController> _tryInitializeController(
      String videoUrl) async {
    debugPrint('Trying to initialize controller for URL: $videoUrl');

    final uri = Uri.parse(videoUrl);
    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
      httpHeaders: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
        'Connection': 'close',
        'Accept-Ranges': 'bytes',
      },
    );

    try {
      await controller.initialize().timeout(
        const Duration(
            seconds: 10), // OPTIMIZATION: Increased timeout for stability
        onTimeout: () {
          debugPrint('Video initialization timeout for URL: $videoUrl');
          throw Exception('Video initialization timeout after 10 seconds');
        },
      );

      debugPrint('Video initialized successfully for URL: $videoUrl');

      // OPTIMIZATION: Set properties in sequence to avoid conflicts
      await controller.setLooping(true);
      await controller.setVolume(isMuted.value ? 0.0 : 1.0);

      if (!controller.value.isInitialized) {
        throw Exception(
            'Video failed to initialize - not marked as initialized');
      }

      if (controller.value.hasError) {
        throw Exception(
            'Video has error: ${controller.value.errorDescription}');
      }

      debugPrint('Video controller setup completed for URL: $videoUrl');
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
      await controller.dispose();
      rethrow;
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

  /// OPTIMIZATION: Smart preloading for adjacent reels
  Future<void> preloadAdjacentVideos(int currentIndex) async {
    currentVisibleReelIndex.value = currentIndex;

    // Preload previous video
    if (currentIndex > 0) {
      final prevReel = reels[currentIndex - 1];
      if (!videoControllers.containsKey(prevReel.id)) {
        await preloadVideo(prevReel.id, prevReel.videoUrl);
      }
    }

    // Preload next video
    if (currentIndex < reels.length - 1) {
      final nextReel = reels[currentIndex + 1];
      if (!videoControllers.containsKey(nextReel.id)) {
        await preloadVideo(nextReel.id, nextReel.videoUrl);
      }
    }
  }

  /// Play video for a specific reel
  Future<void> playVideo(String reelId) async {
    try {
      final controller = videoControllers[reelId];
      if (controller != null &&
          controller.value.isInitialized &&
          !controller.value.hasError) {
        // OPTIMIZATION: Pause all other videos without disposing
        for (final entry in videoControllers.entries) {
          if (entry.key != reelId && entry.value.value.isPlaying) {
            await entry.value.pause();
            videoPlayStates[entry.key] = false;
          }
        }

        await controller.setVolume(isMuted.value ? 0.0 : 1.0);

        // OPTIMIZATION: Seek to beginning only if at end to prevent mid-play resets
        if (controller.value.position >= controller.value.duration) {
          await controller.seekTo(Duration.zero);
        }

        if (!controller.value.isPlaying) {
          await controller.play();
        }

        currentPlayingReelId.value = reelId;
        videoPlayStates[reelId] = true;
      }
    } catch (e) {
      debugPrint('Error playing video $reelId: $e');
    }
  }

  /// Pause video for a specific reel
  Future<void> pauseVideo(String reelId) async {
    final controller = videoControllers[reelId];
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
      videoPlayStates[reelId] = false;

      if (currentPlayingReelId.value == reelId) {
        currentPlayingReelId.value = '';
      }
    }
  }

  /// Get video controller for a specific reel
  VideoPlayerController? getVideoController(String reelId) {
    return videoControllers[reelId];
  }

  /// Check if video is loading for a specific reel
  bool isVideoLoading(String reelId) {
    return videoLoadingStates[reelId] ?? false;
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
    videoErrorStates[reelId] = '';
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
      Get.snackbar('Error', 'Failed to update like status');
    }
  }

  /// Refresh reels
  Future<void> refreshReels() async {
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
    videoPlayStates.clear();
    _initializationLocks.clear(); // OPTIMIZATION: Clear locks
  }

  /// Dispose a specific video controller
  Future<void> disposeVideoController(String reelId) async {
    try {
      final controller = videoControllers[reelId];
      if (controller != null) {
        await controller.dispose();
        videoControllers.remove(reelId);
        videoLoadingStates.remove(reelId);
        videoErrorStates.remove(reelId);
        videoPlayStates.remove(reelId);
        _initializationLocks.remove(reelId); // OPTIMIZATION: Clear lock

        if (currentPlayingReelId.value == reelId) {
          currentPlayingReelId.value = '';
        }
      }
    } catch (e) {
      debugPrint('Error disposing video controller for reel $reelId: $e');
    }
  }

  /// Pause all videos
  Future<void> pauseAllVideos() async {
    try {
      for (final entry in videoControllers.entries) {
        final reelId = entry.key;
        final controller = entry.value;
        if (controller.value.isInitialized && controller.value.isPlaying) {
          await controller.pause();
          videoPlayStates[reelId] = false;
        }
      }
      currentPlayingReelId.value = '';
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
        // OPTIMIZATION: Preload adjacent videos
        await preloadAdjacentVideos(index);
      }
    } catch (e) {
      debugPrint('Error playing video at index $index: $e');
    }
  }

  /// Initialize and play video in one call
  Future<void> initializeAndPlayVideo(String reelId, String videoUrl) async {
    try {
      final existingController = videoControllers[reelId];
      if (existingController != null &&
          existingController.value.isInitialized &&
          !existingController.value.hasError) {
        await playVideo(reelId);
        return;
      }

      await initializeVideoPlayer(reelId, videoUrl);
      // OPTIMIZATION: Small delay to ensure initialization completes
      await Future.delayed(const Duration(milliseconds: 100));
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
    disposeAllVideoControllers();
    super.onClose();
  }

  // Legacy functionality preserved
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

  /// Initialize interaction data for reels
  void _initializeInteractionData() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    for (final reel in reels) {
      _reelService.isReelLikedByUser(reel.id, currentUserId).listen((isLiked) {
        reelLikeStates[reel.id] = isLiked;
      });

      _reelService.getLikeCount(reel.id).listen((count) {
        reelLikeCounts[reel.id] = count;
      });

      _reelService.getCommentCount(reel.id).listen((count) {
        reelCommentCounts[reel.id] = count;
      });

      _reelService.getShareCount(reel.id).listen((count) {
        reelShareCounts[reel.id] = count;
      });

      _reelService.isReelSavedByUser(currentUserId, reel.id).listen((isSaved) {
        reelSaveStates[reel.id] = isSaved;
      });
    }
  }

  Future<void> toggleLike(String reelId) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final isCurrentlyLiked = reelLikeStates[reelId] ?? false;
      if (isCurrentlyLiked) {
        await _reelService.unlikeReel(reelId, currentUserId);
      } else {
        await _reelService.likeReel(reelId, currentUserId);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update like: ${e.toString()}');
    }
  }

  Future<void> addComment(String reelId, String text) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null || text.trim().isEmpty) return;

    try {
      final userDoc = await _firestoreService.getUser(currentUserId);
      if (userDoc == null) return;

      final comment = ReelComment(
        id: '',
        userId: currentUserId,
        username: userDoc.username,
        userPhotoUrl: userDoc.profileImageUrl ?? '',
        text: text.trim(),
        createdAt: DateTime.now(),
      );

      await _reelService.addComment(reelId, comment);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add comment: ${e.toString()}');
    }
  }

  Future<void> shareReel(String reelId) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _reelService.shareReel(reelId, currentUserId);
      Get.snackbar('Success', 'Reel shared successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to share reel: ${e.toString()}');
    }
  }

  Future<void> toggleSave(String reelId) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final isCurrentlySaved = reelSaveStates[reelId] ?? false;
      if (isCurrentlySaved) {
        await _reelService.unsaveReel(currentUserId, reelId);
        Get.snackbar('Success', 'Reel unsaved');
      } else {
        await _reelService.saveReel(currentUserId, reelId);
        Get.snackbar('Success', 'Reel saved');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update save status: ${e.toString()}');
    }
  }

  bool isReelLiked(String reelId) => reelLikeStates[reelId] ?? false;
  int getReelLikeCount(String reelId) => reelLikeCounts[reelId] ?? 0;
  int getReelCommentCount(String reelId) => reelCommentCounts[reelId] ?? 0;
  int getReelShareCount(String reelId) => reelShareCounts[reelId] ?? 0;
  bool isReelSaved(String reelId) => reelSaveStates[reelId] ?? false;

  Future<void> toggleMute() async {
    isMuted.value = !isMuted.value;
    for (final controller in videoControllers.values) {
      if (controller.value.isInitialized) {
        await controller.setVolume(isMuted.value ? 0.0 : 1.0);
      }
    }
  }

  bool isVideoPlaying(String reelId) => videoPlayStates[reelId] ?? false;

  Future<void> togglePlayPause(String reelId) async {
    final controller = videoControllers[reelId];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        await pauseVideo(reelId);
      } else {
        await playVideo(reelId);
      }
    }
  }
}
