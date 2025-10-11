import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/app_like_button.dart';
import '../../../widgets/reel_comment_bottom_sheet.dart';
import '../../../widgets/reel_share_bottom_sheet.dart';
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
      // Don't dispose controller here - GetX manages it
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

      // OPTIMIZATION: Initialize first video after frame is built to prevent flicker
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.reels.isNotEmpty) {
          final firstReel = _controller.reels.first;
          debugPrint('Auto-initializing first reel: ${firstReel.id}');
          _controller.initializeAndPlayVideo(firstReel.id, firstReel.videoUrl);
        }
      });
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

  // OPTIMIZATION: Simplified page change handler without debouncing flags
  void _onPageChanged(int index, List<Reel> reels) {
    try {
      if (index < 0 || index >= reels.length || index == _currentIndex) {
        return;
      }

      debugPrint('Page changed from $_currentIndex to $index');

      // OPTIMIZATION: Pause previous video without delay
      if (_currentIndex >= 0 && _currentIndex < reels.length) {
        final prevReel = reels[_currentIndex];
        _controller.pauseVideo(prevReel.id);
      }

      // Update current index
      _currentIndex = index;

      // OPTIMIZATION: Play current video immediately
      final currentReel = reels[index];
      _controller.initializeAndPlayVideo(currentReel.id, currentReel.videoUrl);
    } catch (e) {
      debugPrint('Error handling page change: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Reels", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
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

          // OPTIMIZATION: Build reels list with optimized PageView
          return RefreshIndicator(
            onRefresh: _controller.refreshReels,
            color: AppColors.primary,
            child: PageView.builder(
              key: const PageStorageKey('reels_page_view'),
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              // OPTIMIZATION: Use BouncingScrollPhysics for smoother scrolling
              physics: const BouncingScrollPhysics(),
              pageSnapping: true,
              onPageChanged: (index) => _onPageChanged(index, reels),
              itemBuilder: (context, index) {
                final reel = reels[index];
                // OPTIMIZATION: Use AutomaticKeepAliveClientMixin via wrapper
                return _ReelItemWrapper(
                  key: ValueKey('reel_${reel.id}'),
                  reel: reel,
                  index: index,
                  currentIndex: _currentIndex,
                  controller: _controller,
                  onTogglePlayPause: _togglePlayPause,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _togglePlayPause(String reelId) async {
    await _controller.togglePlayPause(reelId);
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
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.appGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: _controller.refreshReels,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          )
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
}

// OPTIMIZATION: Wrapper widget with AutomaticKeepAlive to prevent rebuilds
class _ReelItemWrapper extends StatefulWidget {
  final Reel reel;
  final int index;
  final int currentIndex;
  final ReelController controller;
  final Function(String) onTogglePlayPause;

  const _ReelItemWrapper({
    super.key,
    required this.reel,
    required this.index,
    required this.currentIndex,
    required this.controller,
    required this.onTogglePlayPause,
  });

  @override
  State<_ReelItemWrapper> createState() => _ReelItemWrapperState();
}

class _ReelItemWrapperState extends State<_ReelItemWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // OPTIMIZATION: Keep state alive

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Initialize video only for current and adjacent items
    _initializeVideoIfNeeded();
  }

  void _initializeVideoIfNeeded() {
    final isCurrentOrAdjacent = widget.index == widget.currentIndex ||
        (widget.index - widget.currentIndex).abs() == 1;

    if (isCurrentOrAdjacent &&
        !widget.controller.videoControllers.containsKey(widget.reel.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.index == widget.currentIndex) {
            // Current video - initialize and play
            widget.controller
                .initializeAndPlayVideo(widget.reel.id, widget.reel.videoUrl);
          } else {
            // Adjacent video - preload only
            widget.controller
                .preloadVideo(widget.reel.id, widget.reel.videoUrl);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // OPTIMIZATION: Required for AutomaticKeepAlive

    return Obx(() {
      final isLoading = widget.controller.isVideoLoading(widget.reel.id);
      final errorMessage = widget.controller.getVideoError(widget.reel.id);
      final controller = widget.controller.getVideoController(widget.reel.id);
      final isInitialized =
          widget.controller.isVideoInitialized(widget.reel.id);

      return Stack(
        children: [
          // Video player or loading/error state
          SizedBox.expand(
            child: _buildVideoWidget(widget.reel, isLoading, errorMessage,
                controller, isInitialized),
          ),

          // Tap to play/pause
          Positioned.fill(
            child: GestureDetector(
              onTap: () => widget.onTogglePlayPause(widget.reel.id),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Center Play/Pause Button
          if (isInitialized && controller != null)
            _buildCenterPlayPauseButton(widget.reel.id, controller),

          // Mute/Unmute Button (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 15,
            child: _buildMuteButton(),
          ),

          // Right Side Action Icons
          Positioned(
            right: 15,
            bottom: MediaQuery.of(context).padding.bottom + 150,
            child: _buildActionButtons(widget.reel),
          ),

          // Bottom User Info + Caption
          Positioned(
            left: 15,
            right: 80, // Leave space for action buttons
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: _buildUserInfoSection(widget.reel),
          ),
        ],
      );
    });
  }

  Widget _buildVideoWidget(Reel reel, bool isLoading, String errorMessage,
      VideoPlayerController? controller, bool isInitialized) {
    // Show error with fallback
    if (errorMessage.isNotEmpty) {
      return _buildVideoErrorWidget(errorMessage, reel);
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

    // OPTIMIZATION: Use RepaintBoundary to isolate video repaints
    return RepaintBoundary(
      child: SizedBox.expand(
        child: controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            : Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildCenterPlayPauseButton(
      String reelId, VideoPlayerController controller) {
    return Obx(() {
      final isPlaying = widget.controller.isVideoPlaying(reelId);

      // OPTIMIZATION: Don't show button when playing to reduce UI updates
      if (isPlaying) {
        return const SizedBox.shrink();
      }

      return Center(
        child: GestureDetector(
          onTap: () => widget.onTogglePlayPause(reelId),
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
        onTap: () => widget.controller.toggleMute(),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.controller.isMuted.value
                ? Icons.volume_off
                : Icons.volume_up,
            color: Colors.white,
            size: 24,
          ),
        ),
      );
    });
  }

  Widget _buildActionButtons(Reel reel) {
    return Column(
      children: [
        // Like Button
        Column(
          children: [
            Obx(() => AppLikeButton(
                  isLiked: widget.controller.isReelLiked(reel.id),
                  likeCount: widget.controller.getReelLikeCount(reel.id),
                  onTap: (liked) async {
                    await widget.controller.toggleLike(reel.id);
                  },
                  size: 32,
                  likeCountColor: Colors.white,
                  borderColor: Colors.white,
                  showCount: false,
                )),
            const SizedBox(height: 6),
            Obx(() => Text(
                  widget.controller.getReelLikeCount(reel.id).toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                )),
          ],
        ),

        const SizedBox(height: 20),

        // Comment Icon
        Obx(() => _buildActionIcon(
              'assets/icons/comment.svg',
              widget.controller.getReelCommentCount(reel.id).toString(),
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
              widget.controller.getReelShareCount(reel.id).toString(),
              () async {
                // Use the new reel share bottom sheet
                await ReelShareBottomSheet.show(context, reel);
              },
            )),

        const SizedBox(height: 20),

        // Saved Button
        GestureDetector(
          onTap: () {
            widget.controller.toggleSave(reel.id);
          },
          child: Column(
            children: [
              Obx(() => Icon(
                    widget.controller.isReelSaved(reel.id)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: widget.controller.isReelSaved(reel.id)
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

  Widget _buildVideoErrorWidget(String? errorMessage, Reel reel) {
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
                widget.controller
                    .retryVideoInitialization(reel.id, reel.videoUrl);
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
}
