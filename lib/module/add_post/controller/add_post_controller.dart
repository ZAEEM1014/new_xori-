import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/post_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/post_model.dart';

class AddPostController extends GetxController {
  // Observables
  final selectedTab = 0.obs; // 0 = Post, 1 = Reel
  final selectedImage = Rx<File?>(null);
  final isLoading = false.obs;
  final isUploading = false.obs;
  final taggedUsers = <String>[].obs; // List of tagged user IDs
  
  // Text controllers
  final captionController = TextEditingController();
  final hashtagsController = TextEditingController();
  
  // Services
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final PostService _postService = PostService();
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  
  // Image picker instance
  final ImagePicker _picker = ImagePicker();
  
  @override
  void onClose() {
    captionController.dispose();
    hashtagsController.dispose();
    super.onClose();
  }
  
  // Switch between Post and Reel tabs
  void switchTab(int index) {
    selectedTab.value = index;
  }
  
  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      isLoading.value = true;
      
      if (selectedTab.value == 1) {
        // For reels, pick video
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 1),
        );
        
        if (video != null) {
          selectedImage.value = File(video.path);
          Get.snackbar(
            'Success',
            'Video selected successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // For posts, pick image
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        
        if (image != null) {
          selectedImage.value = File(image.path);
          Get.snackbar(
            'Success',
            'Image selected successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick media from gallery: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      isLoading.value = true;
      
      if (selectedTab.value == 1) {
        // For reels, pick video
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 1),
        );
        
        if (video != null) {
          selectedImage.value = File(video.path);
          Get.snackbar(
            'Success',
            'Video captured successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // For posts, pick image
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        
        if (image != null) {
          selectedImage.value = File(image.path);
          Get.snackbar(
            'Success',
            'Photo captured successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to capture media: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Remove selected image
  void removeSelectedImage() {
    selectedImage.value = null;
  }
  
  // Validate post data
  bool _validatePost() {
    if (selectedImage.value == null) {
      Get.snackbar(
        'Validation Error',
        selectedTab.value == 0 ? 'Please select an image' : 'Please select a video',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
    
    if (captionController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please add a caption',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
    
    return true;
  }
  
  // Create post
  Future<void> createPost() async {
    if (!_validatePost()) return;
    
    try {
      isUploading.value = true;
      
      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user data from Firestore for username and profile image
      final userData = await _firestoreService.getUser(currentUser.uid);
      if (userData == null) {
        throw Exception('User data not found');
      }
      
      // Upload media to Cloudinary
      String? mediaUrl;
      String mediaType = 'image';
      
      if (selectedTab.value == 1) {
        // For reels (videos) - assuming we might add video support later
        mediaUrl = await _cloudinaryService.uploadVideo(selectedImage.value!);
        mediaType = 'video';
      } else {
        // For posts (images)
        mediaUrl = await _cloudinaryService.uploadImage(selectedImage.value!);
        mediaType = 'image';
      }
      
      if (mediaUrl == null) {
        throw Exception('Failed to upload media');
      }
      
      // Create Post object using the Post model
      final post = Post(
        id: '', // Will be auto-generated by Firestore
        userId: currentUser.uid,
        username: userData.username,
        userPhotoUrl: userData.profileImageUrl ?? '',
        caption: captionController.text.trim(),
        hashtags: _parseHashtags(hashtagsController.text.trim()),
        mediaUrls: [mediaUrl], // Store as list to support multiple media later
        mediaType: mediaType,
        createdAt: Timestamp.now(),
        likes: [], // Empty list initially
        commentCount: 0,
        isDeleted: false,
        taggedUsers: taggedUsers.toList(), // Use the tagged users list (empty if no users selected)
      );
      
      // Save post using PostService
      final postId = await _postService.createPost(post);
      
      Get.snackbar(
        'Success',
        selectedTab.value == 0 ? 'Post created successfully!' : 'Reel created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      print('[DEBUG] Post created with ID: $postId');
      
      // Clear form and navigate back
      _clearForm();
      Get.back();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create post: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      print('[DEBUG] Error creating post: $e');
    } finally {
      isUploading.value = false;
    }
  }
  
  // Parse hashtags from text
  List<String> _parseHashtags(String hashtagText) {
    if (hashtagText.isEmpty) return [];
    
    return hashtagText
        .split(' ')
        .where((tag) => tag.isNotEmpty)
        .map((tag) => tag.startsWith('#') ? tag : '#$tag')
        .toList();
  }
  
  // Clear form data
  void _clearForm() {
    selectedImage.value = null;
    captionController.clear();
    hashtagsController.clear();
    taggedUsers.clear(); // Clear tagged users
    selectedTab.value = 0;
  }
  
  // Cancel post creation
  void cancelPost() {
    _clearForm();
    Get.back();
  }
  
  // Add user to tagged users list
  void addTaggedUser(String userId) {
    if (!taggedUsers.contains(userId)) {
      taggedUsers.add(userId);
    }
  }
  
  // Remove user from tagged users list
  void removeTaggedUser(String userId) {
    taggedUsers.remove(userId);
  }
  
  // Clear all tagged users
  void clearTaggedUsers() {
    taggedUsers.clear();
  }
  
  // Check if user is tagged
  bool isUserTagged(String userId) {
    return taggedUsers.contains(userId);
  }
}