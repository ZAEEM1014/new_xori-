import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/app_like_button.dart';
import '../../../widgets/saved_button.dart';
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
      if (index != _currentIndex && index < reels.length) {
        // Pause previous video
        if (_currentIndex >= 0 && _currentIndex < reels.length) {
          _controller.pauseVideo(reels[_currentIndex].id);
        }

        // Update current index
        setState(() {
          _currentIndex = index;
        });

        // Play current video
        final currentReel = reels[index];
        _controller.initializeAndPlayVideo(
            currentReel.id, currentReel.videoUrl);

        // Preload next video
        if (index + 1 < reels.length) {
          final nextReel = reels[index + 1];
          _controller.preloadVideo(nextReel.id, nextReel.videoUrl);
        }
      }
    } catch (e) {
      debugPrint('Error handling page change: $e');
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
              onPageChanged: (index) => _onPageChanged(index, reels),
              itemBuilder: (context, index) {
                final reel = reels[index];

                // Auto-play first video when it's initialized
                if (index == 0 && _currentIndex == 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_controller.isVideoInitialized(reel.id)) {
                      _controller.playVideo(reel.id);
                    }
                  });
                }

                return _buildReelItem(reel, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReelItem(Reel reel, int index) {
    // Initialize video player when reel is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_controller.videoControllers.containsKey(reel.id)) {
        _controller.initializeVideoPlayer(reel.id, reel.videoUrl);
      }
    });

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

    return VideoPlayer(controller);
  }

  Widget _buildMixedContentWidget(Reel reel, String errorMessage) {
    // Don't try to show video URLs as images - just show error widget
    return _buildVideoErrorWidget(errorMessage, reel);
  }

  void _togglePlayPause(String reelId) {
    final controller = _controller.getVideoController(reelId);
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        _controller.pauseVideo(reelId);
      } else {
        _controller.playVideo(reelId);
      }
    }
  }

  Widget _buildActionButtons(Reel reel) {
    return Column(
      children: [
        // Like Button
        Column(
          children: [
            AppLikeButton(
              isLiked: false, // You can implement like state logic here
              likeCount: reel.likes.length,
              onTap: (liked) async {
                // Implement like functionality
                // await _controller.toggleReelLike(reel.id, currentUserId, liked);
              },
              size: 32,
              likeCountColor: Colors.white,
              borderColor: Colors.white,
              showCount: false,
            ),
            const SizedBox(height: 6),
            Text(
              reel.likes.length.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Comment Icon
        _buildActionIcon(
          'assets/icons/comment.svg',
          reel.commentCount.toString(),
          () {
            // Handle comment tap
          },
        ),

        const SizedBox(height: 20),

        // Share Icon
        _buildActionIcon(
          'assets/icons/share.svg',
          'Share',
          () {
            // Handle share tap
          },
        ),

        const SizedBox(height: 20),

        // Saved Button
        SavedButton(
          postId: reel.id,
          size: 32,
          initialColor: Colors.white,
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
  void _toggleLike(String reelId) {
    try {
      // Implement like functionality
      _controller.toggleLike(reelId);
    } catch (e) {
      debugPrint('Error toggling like: $e');
      _showErrorSnackBar('Failed to update like status');
    }
  }

  void _showComments(String reelId) {
    try {
      // Navigate to comments or show comments bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Comments feature coming soon!'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing comments: $e');
      _showErrorSnackBar('Failed to show comments');
    }
  }

  void _shareReel(Reel reel) {
    try {
      // Implement share functionality
      // Share.share('Check out this reel: ${reel.videoUrl}');
      _showErrorSnackBar('Share feature coming soon!');
    } catch (e) {
      debugPrint('Error sharing reel: $e');
      _showErrorSnackBar('Failed to share reel');
    }
  }

  void _retryVideo(Reel reel) {
    try {
      _controller.retryVideoInitialization(reel.id, reel.videoUrl);
    } catch (e) {
      debugPrint('Error retrying video: $e');
      _showErrorSnackBar('Failed to retry video');
    }
  }

  void _showErrorSnackBar(String message) {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing error snackbar: $e');
    }
  }
}
