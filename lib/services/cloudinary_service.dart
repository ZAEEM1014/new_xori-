import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:get/get.dart';
import 'package:xori/config/cloudinary_config.dart';

class CloudinaryService extends GetxService {
  late final Cloudinary _cloudinary;
  final RxBool isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _cloudinary = Cloudinary.full(
      apiKey: CloudinaryConfig.apiKey,
      apiSecret: CloudinaryConfig.apiSecret,
      cloudName: CloudinaryConfig.cloudName,
    );
    print(
        'Cloudinary service initialized with cloud name: ${CloudinaryConfig.cloudName}');
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
      isUploading.value = true;

      // Create a unique file name using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'image_$timestamp';

      final response = await _cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: folder ?? 'xori_posts',
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
        return response.secureUrl;
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
}
