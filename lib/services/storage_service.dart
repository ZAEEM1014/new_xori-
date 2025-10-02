import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    try {
      print('[DEBUG] StorageService: Preparing to upload profile image');
      // Create a unique file path using uid and timestamp
      final String fileName = 'profile_$uid${path.extension(imageFile.path)}';
      final Reference storageRef =
          _storage.ref().child('profile_images/$fileName');

      // Upload the file (no metadata passed)
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      print('[DEBUG] StorageService: Profile image uploaded');

      // Get and return the download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      print('[DEBUG] StorageService: Download URL: ' + downloadUrl);
      return downloadUrl;
    } catch (e) {
      print('[DEBUG] StorageService: Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }
}
