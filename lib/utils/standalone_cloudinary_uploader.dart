import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';

/// Simple standalone Cloudinary uploader to test if the issue is with the service pattern
class StandaloneCloudinaryUploader {
  static Future<String?> uploadImageDirect(File imageFile) async {
    try {
      print('[STANDALONE] Starting direct Cloudinary upload...');
      print('[STANDALONE] File: ${imageFile.path}');
      print('[STANDALONE] File exists: ${await imageFile.exists()}');
      print('[STANDALONE] File size: ${await imageFile.length()} bytes');

      final cloudinary = Cloudinary.full(
        apiKey: '917925199885998',
        apiSecret: '4bPHH0IpdBEY44ok0IU_I58f4-k',
        cloudName: 'dnisxyaon',
      );

      print('[STANDALONE] Cloudinary instance created');

      final response = await cloudinary.uploadFile(
        filePath: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'standalone_test',
        fileName: 'standalone_${DateTime.now().millisecondsSinceEpoch}',
        progressCallback: (count, total) {
          final progress = (count / total) * 100;
          print('[STANDALONE] Progress: ${progress.toStringAsFixed(2)}%');
        },
      );

      print('[STANDALONE] Upload completed');
      print('[STANDALONE] Success: ${response.isSuccessful}');
      print('[STANDALONE] Error: ${response.error}');
      print('[STANDALONE] URL: ${response.secureUrl}');

      if (response.isSuccessful && response.secureUrl != null) {
        print('[STANDALONE] SUCCESS: ${response.secureUrl}');
        return response.secureUrl;
      } else {
        print('[STANDALONE] FAILED: Upload unsuccessful or null URL');
        return null;
      }
    } catch (e, stackTrace) {
      print('[STANDALONE] Exception: $e');
      print('[STANDALONE] Stack trace: $stackTrace');
      return null;
    }
  }
}
