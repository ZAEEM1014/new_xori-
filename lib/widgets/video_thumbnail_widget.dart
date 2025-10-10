import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Global memory management for video controllers
class _VideoControllerManager {
  static final _VideoControllerManager _instance = _VideoControllerManager._internal();
  factory _VideoControllerManager() => _instance;
  _VideoControllerManager._internal();

  final Set<VideoPlayerController> _activeControllers = {};
  static const int maxActiveControllers = 3;

  void addController(VideoPlayerController controller) {
    // If we're at the limit, dispose the oldest controller
    if (_activeControllers.length >= maxActiveControllers) {
      final oldestController = _activeControllers.first;
      oldestController.dispose();
      _activeControllers.remove(oldestController);
    }
    _activeControllers.add(controller);
  }

  void removeController(VideoPlayerController controller) {
    _activeControllers.remove(controller);
  }

  void cleanup() {
    print('Memory cleanup performed. Active controllers: ${_activeControllers.length}');
    // Clean up any disposed controllers
    _activeControllers.removeWhere((controller) => !controller.value.isInitialized);
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    Key? key,
    required this.videoUrl,
    this.width = 150,
    this.height = 200,
    this.onTap,
  }) : super(key: key);

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  Widget? _thumbnailWidget;
  int _currentTryIndex = 0;
  final _controllerManager = _VideoControllerManager();

  // Multiple URL formats to try for better compatibility
  List<String> get _videoUrls {
    final baseUrl = widget.videoUrl;

    // If it's a Cloudinary URL, try different format optimizations
    if (baseUrl.contains('cloudinary.com')) {
      final urlParts = baseUrl.split('/');
      final uploadIndex = urlParts.indexWhere((part) => part == 'upload');

      if (uploadIndex != -1 && uploadIndex < urlParts.length - 1) {
        final beforeUpload = urlParts.sublist(0, uploadIndex + 1).join('/');
        final afterUpload = urlParts.sublist(uploadIndex + 1).join('/');

        return [
          // Try with mobile-friendly format transformations
          '$beforeUpload/f_mp4,vc_h264,ac_aac/$afterUpload',
          '$beforeUpload/f_mp4,q_auto,w_300/$afterUpload',
          '$beforeUpload/f_auto,q_auto/$afterUpload',
          baseUrl, // Original URL as last resort
        ];
      }
    }

    // For non-Cloudinary URLs, just return the original
    return [baseUrl];
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final urls = _videoUrls;

    for (int i = _currentTryIndex; i < urls.length; i++) {
      try {
        final url = urls[i];
        print('Attempting video URL ${i + 1}/${urls.length} for reel: $url');

        _controller?.dispose();
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(url),
          videoPlayerOptions: VideoPlayerOptions(
            allowBackgroundPlayback: false,
            mixWithOthers: false,
          ),
        );

        // Set a timeout for initialization
        await _controller!.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Video initialization timeout');
          },
        );

        if (mounted && _controller!.value.isInitialized) {
          // Add to manager for memory management
          _controllerManager.addController(_controller!);
          
          // Seek to get thumbnail
          final duration = _controller!.value.duration;
          final seekPosition = duration.inMilliseconds > 1000
              ? const Duration(seconds: 1)
              : Duration(milliseconds: (duration.inMilliseconds * 0.1).round());

          await _controller!.seekTo(seekPosition);

          setState(() {
            _isLoading = false;
            _thumbnailWidget = VideoPlayer(_controller!);
          });
          return; // Success, exit the loop
        }
      } catch (e) {
        print('Failed to initialize with URL ${urls[i]}: $e');
        _controller?.dispose();
        _controller = null;

        // If this was the last URL, show error
        if (i == urls.length - 1) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controllerManager.removeController(_controller!);
      _controller!.dispose();
    }
    _controllerManager.cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Background/Content
              if (_isLoading)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_hasError)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade600,
                      ],
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_thumbnailWidget != null)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: _thumbnailWidget!,
                    ),
                  ),
                ),

              // Play button overlay
              if (!_isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
