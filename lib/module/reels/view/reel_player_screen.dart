import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../models/reel_model.dart';
import '../../../constants/app_colors.dart';

class ReelPlayerScreen extends StatefulWidget {
  final Reel reel;
  final List<Reel>? allReels;
  final int? initialIndex;

  const ReelPlayerScreen({
    Key? key,
    required this.reel,
    this.allReels,
    this.initialIndex,
  }) : super(key: key);

  @override
  State<ReelPlayerScreen> createState() => _ReelPlayerScreenState();
}

class _ReelPlayerScreenState extends State<ReelPlayerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  VideoPlayerController? _currentController;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _showControls = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
    
    _initializeFirstVideo();
    _hideControlsAfterDelay();
  }

  @override
  void dispose() {
    _currentController?.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeFirstVideo() {
    final reels = widget.allReels ?? [widget.reel];
    if (reels.isNotEmpty && _currentIndex < reels.length) {
      _initializeVideoController(reels[_currentIndex].videoUrl);
    }
  }

  Future<void> _initializeVideoController(String videoUrl) async {
    try {
      _currentController?.dispose();
      
      _currentController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );

      await _currentController!.initialize();
      
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
        _currentController!.play();
        _currentController!.setLooping(true);
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        _fadeController.forward();
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _fadeController.reverse();
      _hideControlsAfterDelay();
    } else {
      _fadeController.forward();
    }
  }

  void _togglePlayPause() {
    if (_currentController != null && _currentController!.value.isInitialized) {
      setState(() {
        if (_isPlaying) {
          _currentController!.pause();
          _isPlaying = false;
        } else {
          _currentController!.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reels = widget.allReels ?? [widget.reel];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // Video PageView
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _initializeVideoController(reels[index].videoUrl);
              },
              itemBuilder: (context, index) {
                return _buildVideoPlayer(reels[index]);
              },
            ),

            // Controls overlay
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildControlsOverlay(),
            ),

            // Tap detector for toggling controls
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                onDoubleTap: _togglePlayPause,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(Reel reel) {
    if (_currentController == null || !_currentController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _currentController!.value.aspectRatio,
        child: VideoPlayer(_currentController!),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Add more controls here if needed
                ],
              ),
            ),
            
            const Spacer(),
            
            // Bottom controls and info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Reel info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // User info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: widget.reel.userPhotoUrl.isNotEmpty
                                  ? NetworkImage(widget.reel.userPhotoUrl)
                                  : null,
                              backgroundColor: AppColors.primary,
                              child: widget.reel.userPhotoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.reel.username.isNotEmpty ? widget.reel.username : 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Reel caption
                        if (widget.reel.caption.isNotEmpty)
                          Text(
                            widget.reel.caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Action buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Like button
                      _buildActionButton(
                        icon: Icons.favorite_border,
                        onTap: () {
                          // TODO: Implement like functionality
                          HapticFeedback.lightImpact();
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Comment button
                      _buildActionButton(
                        icon: Icons.comment_outlined,
                        onTap: () {
                          // TODO: Implement comment functionality
                          HapticFeedback.lightImpact();
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Share button
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        onTap: () {
                          // TODO: Implement share functionality
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Play/Pause button center
            if (!_isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
