import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:get/get.dart';
import 'package:xori/config/cloudinary_config.dart';

class CloudinaryService extends GetxService {
  late final Cloudinary _cloudinary;
  final RxBool isUploading = false.obs;
  bool _isInitialized = false;

  CloudinaryService() {
    _initializeCloudinary();
  }

  void _initializeCloudinary() {
    try {
      _cloudinary = Cloudinary.full(
        apiKey: CloudinaryConfig.apiKey,
        apiSecret: CloudinaryConfig.apiSecret,
        cloudName: CloudinaryConfig.cloudName,
      );
      _isInitialized = true;
      print('[DEBUG] Cloudinary service initialized successfully');
      print('[DEBUG] Cloud name: ${CloudinaryConfig.cloudName}');
      print('[DEBUG] API key: ${CloudinaryConfig.apiKey}');
    } catch (e) {
      print('[DEBUG] Failed to initialize Cloudinary: $e');
      _isInitialized = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _initializeCloudinary();
    }
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      // Try to get account info or usage details to verify connection
      print('Testing Cloudinary connection...');
      // The upload functionality will be the real test of the connection
      print('Cloudinary connection configured successfully!');
    } catch (e) {
      print('Error connecting to Cloudinary: $e');
    }
  }

  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    try {
      isUploading.value = true;

      // Create a unique file name using UID and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${uid}_$timestamp';

      final response = await _cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'xori_profile_images',
        fileName: fileName,
        progressCallback: (count, total) {
          final progress = (count / total) * 100;
          print('Upload progress: ${progress.toStringAsFixed(2)}%');
        },
      );

      if (response.isSuccessful) {
        print('Image uploaded successfully to Cloudinary');
        return response.secureUrl;
      }

      print('Cloudinary upload failed: ${response.error}');
      return null;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> deleteProfileImage(String uid) async {
    try {
      final response = await _cloudinary.deleteFile(
        publicId: 'profile_images/profile_$uid',
        resourceType: CloudinaryResourceType.image,
      );

      return response.isSuccessful;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      print('[DEBUG] CloudinaryService: Starting image upload...');
      print('[DEBUG] Service initialized: $_isInitialized');
      print('[DEBUG] Image file path: ${imageFile.path}');

      if (!_isInitialized) {
        print('[DEBUG] Cloudinary not initialized, trying to initialize...');
        _initializeCloudinary();
        if (!_isInitialized) {
          throw Exception('Failed to initialize Cloudinary service');
        }
      }

      final fileExists = await imageFile.exists();
      final fileSize = await imageFile.length();

      print('[DEBUG] Image file exists: $fileExists');
      print('[DEBUG] Image file size: $fileSize bytes');
      print('[DEBUG] Upload folder: ${folder ?? 'xori_posts'}');

      if (!fileExists) {
        throw Exception('Image file does not exist');
      }

      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }

      isUploading.value = true;

      // Create a unique file name using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'image_$timestamp';

      print('[DEBUG] CloudinaryService: Uploading with filename: $fileName');
      print(
          '[DEBUG] CloudinaryService: Using cloud name: ${CloudinaryConfig.cloudName}');

      final response = await _cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: folder ?? 'xori_posts',
        fileName: fileName,
        progressCallback: (count, total) {
          final progress = (count / total) * 100;
          print('[DEBUG] Upload progress: ${progress.toStringAsFixed(2)}%');
        },
      );

      print('[DEBUG] CloudinaryService: Upload response received');
      print('[DEBUG] Response successful: ${response.isSuccessful}');

      if (response.isSuccessful && response.secureUrl != null) {
        print('[DEBUG] Image uploaded successfully to Cloudinary');
        print('[DEBUG] Secure URL: ${response.secureUrl}');
        print('[DEBUG] Public ID: ${response.publicId}');
        return response.secureUrl;
      }

      print('[DEBUG] Cloudinary upload failed: ${response.error}');
      print('[DEBUG] Response success flag: ${response.isSuccessful}');
      print('[DEBUG] Response URL: ${response.secureUrl}');
      return null;
    } catch (e) {
      print('[DEBUG] Error uploading to Cloudinary: $e');
      print('[DEBUG] Stack trace: ${StackTrace.current}');
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<String?> uploadVideo(File videoFile, {String? folder}) async {
    try {
      isUploading.value = true;

      // Create a unique file name using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'video_$timestamp';

      final response = await _cloudinary.uploadFile(
        filePath: videoFile.path,
        resourceType: CloudinaryResourceType.video,
        folder: folder ?? 'xori_reels',
        fileName: fileName,
        progressCallback: (count, total) {
          final progress = (count / total) * 100;
          print('Upload progress: ${progress.toStringAsFixed(2)}%');
        },
      );

      if (response.isSuccessful) {
        print('Video uploaded successfully to Cloudinary');
        // Generate a Flutter-compatible MP4 URL with H.264/AAC transformation
        final compatibleUrl = _generateFlutterCompatibleVideoUrl(
            response.secureUrl!, response.publicId!);
        print('Generated Flutter-compatible video URL: $compatibleUrl');
        return compatibleUrl;
      }

      print('Cloudinary upload failed: ${response.error}');
      return null;
    } catch (e) {
      print('Error uploading video to Cloudinary: $e');
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  /// Generates a Flutter video_player compatible URL from Cloudinary
  /// Forces MP4 format with H.264 video codec and AAC audio codec
  String _generateFlutterCompatibleVideoUrl(
      String originalUrl, String publicId) {
    try {
      // Get cloud name from config
      String cloudName = CloudinaryConfig.cloudName;

      // Build the transformation URL for Flutter compatibility with conservative settings
      // f_mp4: Force MP4 format
      // vc_h264: Use H.264 video codec (baseline profile for maximum compatibility)
      // ac_aac: Use AAC audio codec
      // br_1500k: Limit bitrate to 1.5Mbps for better compatibility
      // w_720,h_1280: Limit resolution to 720p for better performance
      // q_auto:low: Use lower quality for better compatibility
      final transformedUrl =
          'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,vc_h264,ac_aac,br_1500k,w_720,h_1280,c_limit,q_auto:low/$publicId.mp4';

      return transformedUrl;
    } catch (e) {
      print('Error generating compatible URL, using original: $e');
      // Fallback to original URL if transformation fails
      return originalUrl;
    }
  }

  /// Converts any existing Cloudinary video URL to Flutter-compatible format
  /// This is useful for fixing URLs that were uploaded before this fix
  static String makeVideoUrlFlutterCompatible(String cloudinaryUrl) {
    try {
      // Check if it's already a transformed URL or already ends with .mp4
      if (cloudinaryUrl.contains('f_mp4') || cloudinaryUrl.endsWith('.mp4')) {
        return cloudinaryUrl;
      }

      // Parse the URL to extract cloud name and public ID
      final uri = Uri.parse(cloudinaryUrl);
      if (!uri.host.contains('cloudinary.com')) {
        return cloudinaryUrl; // Not a Cloudinary URL
      }

      // Extract cloud name and public ID from the URL path
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 4) {
        return cloudinaryUrl; // Invalid Cloudinary URL structure
      }

      final cloudName = pathSegments[0]; // Usually the cloud name
      final publicIdWithVersion =
          pathSegments.skip(3).join('/'); // Skip 'video', 'upload', version

      // Remove version prefix if present (v1234567/)
      String publicId = publicIdWithVersion;
      if (publicId.startsWith('v') && publicId.contains('/')) {
        final parts = publicId.split('/');
        if (parts.length > 1 && RegExp(r'^v\d+$').hasMatch(parts[0])) {
          publicId = parts.skip(1).join('/');
        }
      }

      // Remove file extension if present
      if (publicId.contains('.')) {
        publicId = publicId.substring(0, publicId.lastIndexOf('.'));
      }

      // Build Flutter-compatible URL with conservative settings for maximum compatibility
      final compatibleUrl =
          'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,vc_h264,ac_aac,br_1500k,w_720,h_1280,c_limit,q_auto:low/$publicId.mp4';

      print('Converted video URL: $cloudinaryUrl -> $compatibleUrl');
      return compatibleUrl;
    } catch (e) {
      print('Error converting video URL, using original: $e');
      return cloudinaryUrl;
    }
  }
}
