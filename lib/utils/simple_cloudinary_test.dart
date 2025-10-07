import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';

class SimpleCloudinaryTest {
  static final Cloudinary _cloudinary = Cloudinary.full(
    apiKey: '917925199885998',
    apiSecret: '4bPHH0IpdBEY44ok0IU_I58f4-k',
    cloudName: 'dnisxyaon',
  );

  static Future<String?> testUpload(File imageFile) async {
    try {
      print('[DEBUG] Testing Cloudinary upload directly...');
      print('[DEBUG] File path: ${imageFile.path}');
      print('[DEBUG] File exists: ${await imageFile.exists()}');
      print('[DEBUG] File size: ${await imageFile.length()} bytes');

      final response = await _cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'test_upload',
        fileName: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      print('[DEBUG] Upload completed');
      print('[DEBUG] Success: ${response.isSuccessful}');
      print('[DEBUG] Error: ${response.error}');
      print('[DEBUG] Secure URL: ${response.secureUrl}');
      print('[DEBUG] Public ID: ${response.publicId}');

      return response.isSuccessful ? response.secureUrl : null;
    } catch (e) {
      print('[DEBUG] Exception during upload: $e');
      return null;
    }
  }
}
