import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/app_like_button.dart';
import '../../../widgets/reel_comment_bottom_sheet.dart';
import '../../../models/reel_model.dart';
import '../controller/reels_controller.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  late final ReelController _controller;
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.put(ReelController());
      _pageController = PageController();
      WidgetsBinding.instance.addObserver(this);
      _loadReels();
    } catch (e) {
      debugPrint('Error initializing ReelsScreen: $e');
      _showErrorSnackbar('Failed to initialize reels screen');
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
      _pageController.dispose();
      _controller.dispose();
    } catch (e) {
      debugPrint('Error disposing ReelsScreen: $e');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
          _isAppInBackground = true;
          _pauseCurrentVideo();
          break;
        case AppLifecycleState.resumed:
          _isAppInBackground = false;
          _playCurrentVideo();
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('Error handling app lifecycle state: $e');
    }
  }

  Future<void> _loadReels() async {
    try {
      await _controller.loadReels();
    } catch (e) {
      debugPrint('Error loading reels: $e');
      _showErrorSnackbar('Failed to load reels');
    }
  }

  void _showErrorSnackbar(String message) {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadReels,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }
  }

  void _pauseCurrentVideo() {
    try {
      if (_currentIndex >= 0) {
        _controller.pauseAllVideos();
      }
    } catch (e) {
      debugPrint('Error pausing current video: $e');
    }
  }

  void _playCurrentVideo() {
    try {
      if (_currentIndex >= 0 && !_isAppInBackground && mounted) {
        _controller.playVideoAtIndex(_currentIndex);
      }
    } catch (e) {
      debugPrint('Error playing current video: $e');
    }
  }

  void _onPageChanged(int index, List<Reel> reels) {
    try {
      if (index >= 0 && index < reels.length && index != _currentIndex) {
        debugPrint('Page changed from $_currentIndex to $index');
        
        // Pause previous video immediately
        if (_currentIndex >= 0 && _currentIndex < reels.length) {
          final prevReel = reels[_currentIndex];
          _controller.pauseVideo(prevReel.id);
        }

        // Update current index immediately
        final oldIndex = _currentIndex;
        _currentIndex = index;

        // Initialize and play current video immediately
        final currentReel = reels[index];
        _controller.initializeAndPlayVideo(currentReel.id, currentReel.videoUrl);

        // Preload adjacent videos for smooth navigation
        _preloadAdjacentVideos(index, reels);
        
        // Dispose distant videos to free memory
        _disposeDistantVideos(index, reels, oldIndex);
      }
    } catch (e) {
      debugPrint('Error handling page change: $e');
    }
  }

  void _preloadAdjacentVideos(int currentIndex, List<Reel> reels) {
    // Preload next 2 videos
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < reels.length) {
        final reel = reels[nextIndex];
        _controller.preloadVideo(reel.id, reel.videoUrl);
      }
    }
    
    // Preload previous 1 video for backward navigation
    if (currentIndex > 0) {
      final prevReel = reels[currentIndex - 1];
      _controller.preloadVideo(prevReel.id, prevReel.videoUrl);
    }
  }

  void _disposeDistantVideos(int currentIndex, List<Reel> reels, int oldIndex) {
    // Dispose videos that are more than 3 positions away
    for (int i = 0; i < reels.length; i++) {
      if ((i - currentIndex).abs() > 3 && i != oldIndex) {
        final reel = reels[i];
        _controller.disposeVideoController(reel.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Reels", style: TextStyle(color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      body: StreamBuilder<List<Reel>>(
        stream: _controller.reelsStream,
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3.0,
              ),
            );
          }

          // Handle error state
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final reels = snapshot.data ?? [];

          // Handle empty state
          if (reels.isEmpty) {
            return _buildEmptyWidget();
          }

          // Build reels list
          return RefreshIndicator(
            onRefresh: _controller.refreshReels,
            color: AppColors.primary,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              physics: const BouncingScrollPhysics(),
              pageSnapping: true,
              allowImplicitScrolling: true,
              onPageChanged: (index) => _onPageChanged(index, reels),
              itemBuilder: (context, index) {
                final reel = reels[index];
                return _buildReelItem(reel, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReelItem(Reel reel, int index) {
    // Only initialize if not already done and if within visible range
    if (!_controller.videoControllers.containsKey(reel.id) && 
        (index - _currentIndex).abs() <= 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.preloadVideo(reel.id, reel.videoUrl);
        }
      });
    }

    return Obx(() {
      final isLoading = _controller.isVideoLoading(reel.id);
      final errorMessage = _controller.getVideoError(reel.id);
      final controller = _controller.getVideoController(reel.id);
      final isInitialized = _controller.isVideoInitialized(reel.id);

      return Stack(
        children: [
          // Video player or loading/error state
          SizedBox.expand(
            child: _buildVideoWidget(
                reel, isLoading, errorMessage, controller, isInitialized),
          ),

          // Tap to play/pause
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _togglePlayPause(reel.id),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Center Play/Pause Button
          if (isInitialized && controller != null)
            _buildCenterPlayPauseButton(reel.id, controller),

          // Mute/Unmute Button (Top Right)
          Positioned(
            top: 50,
            right: 15,
            child: _buildMuteButton(),
          ),

          // Right Side Action Icons
          Positioned(
            right: 15,
            bottom: 150,
            child: _buildActionButtons(reel),
          ),

          // Bottom User Info + Caption
          Positioned(
            left: 15,
            right: 15,
            bottom: 80,
            child: _buildUserInfoSection(reel),
          ),
        ],
      );
    });
  }

  Widget _buildVideoWidget(Reel reel, bool isLoading, String errorMessage,
      VideoPlayerController? controller, bool isInitialized) {
    // Show error with fallback to image
    if (errorMessage.isNotEmpty) {
      return _buildMixedContentWidget(reel, errorMessage);
    }

    if (isLoading || !isInitialized || controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3.0,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading content...',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _controller.togglePlayPause(reel.id),
          child: VideoPlayer(controller),
        ),
        // Center play/pause button
        _buildCenterPlayPauseButton(reel.id, controller),
        // Mute button in top right
        Positioned(
          top: 50,
          right: 16,
          child: _buildMuteButton(),
        ),
        // Progress indicator at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildProgressIndicator(controller),
        ),
      ],
    );
  }

  Widget _buildMixedContentWidget(Reel reel, String errorMessage) {
    // Don't try to show video URLs as images - just show error widget
    return _buildVideoErrorWidget(errorMessage, reel);
  }

  void _togglePlayPause(String reelId) async {
    await _controller.togglePlayPause(reelId);
  }

  Widget _buildActionButtons(Reel reel) {
    return Column(
      children: [
        // Like Button
        Column(
          children: [
            Obx(() => AppLikeButton(
              isLiked: _controller.isReelLiked(reel.id),
              likeCount: _controller.getReelLikeCount(reel.id),
              onTap: (liked) async {
                await _controller.toggleLike(reel.id);
              },
              size: 32,
              likeCountColor: Colors.white,
              borderColor: Colors.white,
              showCount: false,
            )),
            const SizedBox(height: 6),
            Obx(() => Text(
              _controller.getReelLikeCount(reel.id).toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            )),
          ],
        ),

        const SizedBox(height: 20),

        // Comment Icon
        Obx(() => _buildActionIcon(
          'assets/icons/comment.svg',
          _controller.getReelCommentCount(reel.id).toString(),
          () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ReelCommentBottomSheet(
                reelId: reel.id,
              ),
            );
          },
        )),

        const SizedBox(height: 20),

        // Share Icon
        Obx(() => _buildActionIcon(
          'assets/icons/share.svg',
          _controller.getReelShareCount(reel.id).toString(),
          () {
            _controller.shareReel(reel.id);
          },
        )),

        const SizedBox(height: 20),

        // Saved Button
        GestureDetector(
          onTap: () {
            _controller.toggleSave(reel.id);
          },
          child: Column(
            children: [
              Obx(() => Icon(
                _controller.isReelSaved(reel.id) 
                    ? Icons.bookmark 
                    : Icons.bookmark_border,
                color: _controller.isReelSaved(reel.id) 
                    ? Colors.orange 
                    : Colors.white,
                size: 32,
              )),
              const SizedBox(height: 6),
              const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(String iconPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SvgPicture.asset(
            iconPath,
            height: 32,
            width: 32,
            colorFilter: ColorFilter.mode(AppColors.white, BlendMode.srcIn),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(Reel reel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            CircleAvatar(
              radius: 23,
              backgroundImage: NetworkImage(reel.userPhotoUrl),
              onBackgroundImageError: (exception, stackTrace) {
                // Handle profile image error
              },
            ),
            const SizedBox(width: 12),

            // Username and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    reel.username,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _getTimeAgo(reel.createdAt),
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Caption
        if (reel.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              reel.caption,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load reels',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _controller.refreshReels,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No reels found',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or check back later',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoErrorWidget(String? errorMessage, [Reel? reel]) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                errorMessage ?? 'Failed to load content',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (reel != null) {
                  // Retry specific video
                  _controller.retryVideoInitialization(reel.id, reel.videoUrl);
                } else {
                  // Refresh all reels
                  _controller.refreshReels();
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    try {
      final now = DateTime.now();
      final createdAt = timestamp.toDate() as DateTime;
      final difference = now.difference(createdAt);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  // Additional interaction methods with error handling

  Widget _buildCenterPlayPauseButton(String reelId, VideoPlayerController controller) {
    return Obx(() {
      final isPlaying = _controller.isVideoPlaying(reelId);
      
      // Only show play button when paused and hide after a few seconds when playing
      if (isPlaying) {
        // Hide button after 2 seconds of playing
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() {});
        });
        return const SizedBox.shrink();
      }
      
      return Center(
        child: GestureDetector(
          onTap: () => _togglePlayPause(reelId),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMuteButton() {
    return Obx(() {
      return GestureDetector(
        onTap: () => _controller.toggleMute(),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _controller.isMuted.value ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 24,
          ),
        ),
      );
    });
  }

  Widget _buildProgressIndicator(VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (!value.isInitialized) return SizedBox.shrink();
        
        return Container(
          height: 2,
          child: LinearProgressIndicator(
            value: value.duration.inMilliseconds > 0
                ? value.position.inMilliseconds / value.duration.inMilliseconds
                : 0.0,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            backgroundColor: Colors.white.withOpacity(0.3),
          ),
        );
      },
    );
  }
}
