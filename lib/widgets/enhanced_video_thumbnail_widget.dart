import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Enhanced video thumbnail widget with proper Instagram-style thumbnail generation
class EnhancedVideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool showPlayButton;
  final Color? playButtonColor;
  final double playButtonSize;

  const EnhancedVideoThumbnailWidget({
    Key? key,
    required this.videoUrl,
    this.width = 150,
    this.height = 200,
    this.onTap,
    this.borderRadius,
    this.showPlayButton = true,
    this.playButtonColor = Colors.white,
    this.playButtonSize = 40,
  }) : super(key: key);

  @override
  State<EnhancedVideoThumbnailWidget> createState() => _EnhancedVideoThumbnailWidgetState();
}

class _EnhancedVideoThumbnailWidgetState extends State<EnhancedVideoThumbnailWidget>
    with SingleTickerProviderStateMixin {
  String? _thumbnailPath;
  bool _isLoading = true;
  bool _hasError = false;
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );
    _generateThumbnail();
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    super.dispose();
  }

  /// Generate thumbnail for video with caching
  Future<void> _generateThumbnail() async {
    try {
      if (!mounted) return;

      // Generate a unique cache key based on video URL
      final cacheKey = _generateCacheKey(widget.videoUrl);
      final cachedPath = await _getCachedThumbnailPath(cacheKey);

      // Check if thumbnail is already cached
      if (cachedPath != null && await File(cachedPath).exists()) {
        if (mounted) {
          setState(() {
            _thumbnailPath = cachedPath;
            _isLoading = false;
          });
          _fadeController?.forward();
        }
        return;
      }

      // Generate new thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: await _getThumbnailDirectory(),
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        maxWidth: 300,
        timeMs: 1000, // Get thumbnail at 1 second
        quality: 85,
      );

      if (thumbnailPath != null && mounted) {
        // Cache the thumbnail
        await _cacheThumbnail(cacheKey, thumbnailPath);
        
        setState(() {
          _thumbnailPath = thumbnailPath;
          _isLoading = false;
        });
        _fadeController?.forward();
      } else {
        _handleError('Failed to generate thumbnail');
      }
    } catch (e) {
      print('Error generating thumbnail for ${widget.videoUrl}: $e');
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  /// Generate cache key for video URL
  String _generateCacheKey(String videoUrl) {
    final bytes = utf8.encode(videoUrl);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get cached thumbnail path if exists
  Future<String?> _getCachedThumbnailPath(String cacheKey) async {
    try {
      final directory = await _getThumbnailDirectory();
      final cachedFile = File('$directory/thumb_$cacheKey.jpg');
      return cachedFile.exists().then((exists) => exists ? cachedFile.path : null);
    } catch (e) {
      return null;
    }
  }

  /// Cache thumbnail with key
  Future<void> _cacheThumbnail(String cacheKey, String thumbnailPath) async {
    try {
      final directory = await _getThumbnailDirectory();
      final cachedFile = File('$directory/thumb_$cacheKey.jpg');
      final originalFile = File(thumbnailPath);
      
      if (await originalFile.exists()) {
        await originalFile.copy(cachedFile.path);
      }
    } catch (e) {
      print('Error caching thumbnail: $e');
    }
  }

  /// Get thumbnail directory
  Future<String> _getThumbnailDirectory() async {
    final directory = await getTemporaryDirectory();
    final thumbnailDir = Directory('${directory.path}/video_thumbnails');
    
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }
    
    return thumbnailDir.path;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail or loading/error state
              _buildThumbnailContent(),
              
              // Gradient overlay for better play button visibility
              if (!_isLoading && !_hasError)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),

              // Single centralized play button
              if (widget.showPlayButton && !_isLoading)
                Center(
                  child: Container(
                    width: widget.playButtonSize + 16,
                    height: widget.playButtonSize + 16,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular((widget.playButtonSize + 16) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: widget.playButtonColor,
                      size: widget.playButtonSize,
                    ),
                  ),
                ),

              // Video duration badge (optional enhancement)
              if (!_isLoading && !_hasError)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '0:15', // You can make this dynamic by getting video duration
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

  Widget _buildThumbnailContent() {
    if (_isLoading) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      );
    }

    if (_hasError || _thumbnailPath == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade500,
            ],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation!,
      child: Image.file(
        File(_thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image_rounded,
              color: Colors.grey,
              size: 32,
            ),
          );
        },
      ),
    );
  }
}
